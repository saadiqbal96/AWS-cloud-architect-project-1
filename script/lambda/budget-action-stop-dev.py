"""
Lambda Function: Stop Development Resources on Budget Threshold
Purpose: Automatically stop EC2 instances tagged as Development when budget is exceeded
Trigger: AWS Budget Action at 100% threshold
Author: Excipient Technologies Cloud Team
"""

import boto3
import json
import os
from datetime import datetime

# Initialize AWS clients
ec2 = boto3.client('ec2')
sns = boto3.client('sns')

def lambda_handler(event, context):
    """
    Main handler function triggered by AWS Budget Action
    
    Args:
        event: Budget action event data
        context: Lambda context object
        
    Returns:
        dict: Status and details of stopped instances
    """
    
    print(f"Budget action triggered at {datetime.now()}")
    print(f"Event: {json.dumps(event, indent=2)}")
    
    # Parse budget event (if available)
    budget_name = event.get('detail', {}).get('budgetName', 'Development-Account-Monthly-Budget')
    threshold = event.get('detail', {}).get('threshold', 100)
    
    print(f"Budget: {budget_name}, Threshold: {threshold}%")
    
    # Find all running development instances across all regions
    stopped_instances = []
    regions = get_all_regions()
    
    for region in regions:
        print(f"Checking region: {region}")
        stopped_in_region = stop_development_instances(region)
        stopped_instances.extend(stopped_in_region)
    
    # Send notification
    if stopped_instances:
        send_notification(stopped_instances, budget_name, threshold)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Stopped {len(stopped_instances)} development instances',
                'instances': stopped_instances
            })
        }
    else:
        print("No development instances found to stop")
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'No development instances to stop'
            })
        }


def get_all_regions():
    """
    Get list of all AWS regions where EC2 is available
    
    Returns:
        list: List of region names
    """
    try:
        # For production, you might want to limit to specific regions
        # For this example, we'll use a subset of common regions
        regions = [
            'us-east-1',
            'us-east-2',
            'us-west-1',
            'us-west-2',
            'eu-west-1',
            'eu-central-1',
            'ap-southeast-1',
            'ap-northeast-1'
        ]
        return regions
    except Exception as e:
        print(f"Error getting regions: {str(e)}")
        return ['us-east-1']  # Fallback to default region


def stop_development_instances(region):
    """
    Stop all running EC2 instances tagged as Development in a specific region
    
    Args:
        region: AWS region to check
        
    Returns:
        list: List of stopped instance details
    """
    ec2_regional = boto3.client('ec2', region_name=region)
    stopped_instances = []
    
    try:
        # Find all running development instances
        response = ec2_regional.describe_instances(
            Filters=[
                {
                    'Name': 'tag:Environment',
                    'Values': ['Development', 'development', 'dev', 'Dev']
                },
                {
                    'Name': 'instance-state-name',
                    'Values': ['running']
                }
            ]
        )
        
        # Extract instance IDs
        instance_ids = []
        instance_details = []
        
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instance_id = instance['InstanceId']
                instance_ids.append(instance_id)
                
                # Get instance name from tags
                instance_name = 'Unnamed'
                for tag in instance.get('Tags', []):
                    if tag['Key'] == 'Name':
                        instance_name = tag['Value']
                        break
                
                instance_details.append({
                    'instance_id': instance_id,
                    'instance_name': instance_name,
                    'region': region,
                    'instance_type': instance['InstanceType'],
                    'private_ip': instance.get('PrivateIpAddress', 'N/A'),
                    'launch_time': instance['LaunchTime'].isoformat()
                })
        
        # Stop instances if any found
        if instance_ids:
            print(f"Stopping {len(instance_ids)} instances in {region}: {instance_ids}")
            
            ec2_regional.stop_instances(InstanceIds=instance_ids)
            
            # Tag instances with stop reason
            ec2_regional.create_tags(
                Resources=instance_ids,
                Tags=[
                    {
                        'Key': 'AutoStoppedBy',
                        'Value': 'BudgetAction'
                    },
                    {
                        'Key': 'AutoStoppedAt',
                        'Value': datetime.now().isoformat()
                    },
                    {
                        'Key': 'AutoStoppedReason',
                        'Value': 'Development budget threshold exceeded'
                    }
                ]
            )
            
            stopped_instances.extend(instance_details)
            print(f"Successfully stopped {len(instance_ids)} instances in {region}")
        else:
            print(f"No running development instances found in {region}")
    
    except Exception as e:
        print(f"Error stopping instances in {region}: {str(e)}")
    
    return stopped_instances


def send_notification(stopped_instances, budget_name, threshold):
    """
    Send SNS notification about stopped instances
    
    Args:
        stopped_instances: List of stopped instance details
        budget_name: Name of the budget that triggered the action
        threshold: Budget threshold percentage
    """
    
    # Get SNS topic ARN from environment variable
    sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')
    
    if not sns_topic_arn:
        print("SNS_TOPIC_ARN environment variable not set, skipping notification")
        return
    
    # Build notification message
    message_lines = [
        "🚨 AWS Budget Action Triggered - Development Resources Stopped",
        "",
        f"Budget: {budget_name}",
        f"Threshold: {threshold}%",
        f"Action Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}",
        "",
        f"Stopped {len(stopped_instances)} EC2 instances:",
        ""
    ]
    
    # Add instance details
    for idx, instance in enumerate(stopped_instances, 1):
        message_lines.extend([
            f"{idx}. Instance: {instance['instance_name']} ({instance['instance_id']})",
            f"   Region: {instance['region']}",
            f"   Type: {instance['instance_type']}",
            f"   Private IP: {instance['private_ip']}",
            ""
        ])
    
    message_lines.extend([
        "Action Required:",
        "1. Review budget utilization in AWS Cost Explorer",
        "2. Identify cost drivers",
        "3. Implement cost optimization measures",
        "4. Restart instances only if budget allows",
        "",
        "To restart instances, remove AutoStopped tags and start manually.",
        "",
        "Dashboard: https://console.aws.amazon.com/billing/home#/budgets",
        "",
        "This is an automated message from AWS Lambda."
    ])
    
    message = '\n'.join(message_lines)
    
    # Build subject
    subject = f"🚨 Budget Alert: {len(stopped_instances)} Development Instances Stopped"
    
    try:
        # Send notification
        response = sns.publish(
            TopicArn=sns_topic_arn,
            Subject=subject[:100],  # SNS subject has 100 char limit
            Message=message,
            MessageAttributes={
                'budget_name': {
                    'DataType': 'String',
                    'StringValue': budget_name
                },
                'instances_stopped': {
                    'DataType': 'Number',
                    'StringValue': str(len(stopped_instances))
                },
                'severity': {
                    'DataType': 'String',
                    'StringValue': 'HIGH'
                }
            }
        )
        
        print(f"Notification sent successfully. Message ID: {response['MessageId']}")
        
    except Exception as e:
        print(f"Error sending notification: {str(e)}")


# For local testing
if __name__ == "__main__":
    # Test event
    test_event = {
        "detail": {
            "budgetName": "Development-Account-Monthly-Budget",
            "threshold": 100,
            "currentSpend": 5100,
            "budgetAmount": 5000
        }
    }
    
    # Mock context
    class Context:
        function_name = "budget-action-stop-dev"
        memory_limit_in_mb = 128
        invoked_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:budget-action-stop-dev"
        aws_request_id = "test-request-id"
    
    result = lambda_handler(test_event, Context())
    print(f"Result: {json.dumps(result, indent=2)}")

