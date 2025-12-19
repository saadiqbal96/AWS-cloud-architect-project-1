"""
Lambda Function: Send Slack Notification for Budget Alerts
Purpose: Send formatted Slack message when budget thresholds are exceeded
Trigger: AWS Budget notification via SNS
Author: Excipient Technologies Cloud Team
"""

import json
import urllib3
import os
from datetime import datetime

# Initialize HTTP client
http = urllib3.PoolManager()

def lambda_handler(event, context):
    """
    Main handler function triggered by SNS from AWS Budgets
    
    Args:
        event: SNS event containing budget alert data
        context: Lambda context object
        
    Returns:
        dict: Status of Slack notification
    """
    
    print(f"Budget alert received at {datetime.now()}")
    print(f"Event: {json.dumps(event, indent=2)}")
    
    # Parse SNS message
    try:
        # Extract message from SNS
        sns_message = event['Records'][0]['Sns']['Message']
        
        # Parse budget data
        if isinstance(sns_message, str):
            budget_data = json.loads(sns_message)
        else:
            budget_data = sns_message
        
        # Send to Slack
        send_slack_notification(budget_data)
        
        return {
            'statusCode': 200,
            'body': json.dumps('Slack notification sent successfully')
        }
        
    except Exception as e:
        print(f"Error processing event: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }


def send_slack_notification(budget_data):
    """
    Format and send Slack notification
    
    Args:
        budget_data: Dictionary containing budget alert information
    """
    
    # Get Slack webhook URL from environment variable
    slack_webhook_url = os.environ.get('SLACK_WEBHOOK_URL')
    
    if not slack_webhook_url:
        print("SLACK_WEBHOOK_URL environment variable not set")
        raise ValueError("Slack webhook URL not configured")
    
    # Extract budget information
    budget_name = budget_data.get('budgetName', 'Unknown Budget')
    threshold = budget_data.get('threshold', 'Unknown')
    current_spend = budget_data.get('currentSpend', 0)
    budget_limit = budget_data.get('budgetLimit', 0)
    percentage = budget_data.get('percentage', 0)
    
    # Determine severity and emoji
    severity_config = get_severity_config(threshold)
    
    # Build Slack message
    slack_message = {
        'username': 'AWS Budget Monitor',
        'icon_emoji': ':money_with_wings:',
        'blocks': [
            {
                'type': 'header',
                'text': {
                    'type': 'plain_text',
                    'text': f'{severity_config["emoji"]} AWS Budget Alert',
                    'emoji': True
                }
            },
            {
                'type': 'section',
                'fields': [
                    {
                        'type': 'mrkdwn',
                        'text': f'*Budget Name:*\n{budget_name}'
                    },
                    {
                        'type': 'mrkdwn',
                        'text': f'*Severity:*\n{severity_config["level"]}'
                    }
                ]
            },
            {
                'type': 'section',
                'fields': [
                    {
                        'type': 'mrkdwn',
                        'text': f'*Threshold:*\n{threshold}%'
                    },
                    {
                        'type': 'mrkdwn',
                        'text': f'*Current Usage:*\n{percentage}%'
                    }
                ]
            },
            {
                'type': 'section',
                'fields': [
                    {
                        'type': 'mrkdwn',
                        'text': f'*Budget Limit:*\n${budget_limit:,.2f}'
                    },
                    {
                        'type': 'mrkdwn',
                        'text': f'*Current Spend:*\n${current_spend:,.2f}'
                    }
                ]
            },
            {
                'type': 'divider'
            },
            {
                'type': 'section',
                'text': {
                    'type': 'mrkdwn',
                    'text': severity_config['message']
                }
            },
            {
                'type': 'section',
                'text': {
                    'type': 'mrkdwn',
                    'text': '*Recommended Actions:*'
                }
            },
            {
                'type': 'section',
                'text': {
                    'type': 'mrkdwn',
                    'text': get_recommended_actions(threshold)
                }
            },
            {
                'type': 'actions',
                'elements': [
                    {
                        'type': 'button',
                        'text': {
                            'type': 'plain_text',
                            'text': 'View Budget Dashboard',
                            'emoji': True
                        },
                        'url': 'https://console.aws.amazon.com/billing/home#/budgets',
                        'style': 'primary'
                    },
                    {
                        'type': 'button',
                        'text': {
                            'type': 'plain_text',
                            'text': 'Cost Explorer',
                            'emoji': True
                        },
                        'url': 'https://console.aws.amazon.com/cost-management/home#/cost-explorer'
                    }
                ]
            },
            {
                'type': 'context',
                'elements': [
                    {
                        'type': 'mrkdwn',
                        'text': f'Alert triggered at {datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")} | Automated notification from AWS Lambda'
                    }
                ]
            }
        ]
    }
    
    # Add color coding to message based on severity
    if threshold >= 100:
        slack_message['attachments'] = [
            {
                'color': '#dc3545',  # Red
                'text': '⚠️ CRITICAL: Budget limit exceeded!'
            }
        ]
    elif threshold >= 85:
        slack_message['attachments'] = [
            {
                'color': '#ffc107',  # Yellow
                'text': '⚠️ WARNING: Approaching budget limit'
            }
        ]
    else:
        slack_message['attachments'] = [
            {
                'color': '#17a2b8',  # Blue
                'text': 'ℹ️ INFO: Budget threshold reached'
            }
        ]
    
    # Send to Slack
    try:
        encoded_data = json.dumps(slack_message).encode('utf-8')
        
        response = http.request(
            'POST',
            slack_webhook_url,
            body=encoded_data,
            headers={'Content-Type': 'application/json'}
        )
        
        if response.status == 200:
            print("Slack notification sent successfully")
        else:
            print(f"Failed to send Slack notification. Status: {response.status}")
            print(f"Response: {response.data.decode('utf-8')}")
            
    except Exception as e:
        print(f"Error sending Slack notification: {str(e)}")
        raise


def get_severity_config(threshold):
    """
    Get severity configuration based on threshold
    
    Args:
        threshold: Budget threshold percentage
        
    Returns:
        dict: Severity configuration
    """
    
    if threshold >= 100:
        return {
            'level': '🔴 CRITICAL',
            'emoji': '🚨',
            'message': '⚠️ *CRITICAL ALERT:* Your budget limit has been exceeded! Immediate action required.'
        }
    elif threshold >= 90:
        return {
            'level': '🟠 HIGH',
            'emoji': '⚠️',
            'message': '⚠️ *HIGH ALERT:* You are very close to exceeding your budget limit.'
        }
    elif threshold >= 80:
        return {
            'level': '🟡 MEDIUM',
            'emoji': '⚡',
            'message': '⚡ *MEDIUM ALERT:* Your spending is trending towards the budget limit.'
        }
    else:
        return {
            'level': '🟢 LOW',
            'emoji': 'ℹ️',
            'message': 'ℹ️ *INFO:* Budget threshold reached. Monitoring recommended.'
        }


def get_recommended_actions(threshold):
    """
    Get recommended actions based on threshold
    
    Args:
        threshold: Budget threshold percentage
        
    Returns:
        str: Markdown formatted recommended actions
    """
    
    if threshold >= 100:
        return '''
• 🛑 Stop all non-critical workloads immediately
• 🔍 Review Cost Explorer for unexpected charges
• 📧 Notify department head and finance team
• 🔒 Enable spending controls via Budget Actions
• 📊 Schedule emergency cost review meeting
        '''.strip()
    elif threshold >= 90:
        return '''
• 🔍 Analyze current spending patterns in Cost Explorer
• 💰 Identify and stop unused resources
• 📊 Review Reserved Instance utilization
• ⚙️ Implement cost optimization recommendations
• 📧 Alert team leads of spending situation
        '''.strip()
    elif threshold >= 80:
        return '''
• 📊 Monitor daily spending trends
• 🔍 Review recent resource deployments
• 💾 Check for over-provisioned resources
• 🔄 Consider auto-scaling adjustments
• 📝 Update forecasts and projections
        '''.strip()
    else:
        return '''
• 📈 Continue monitoring spending trends
• 🔍 Regular cost optimization reviews
• 📝 Update team on budget status
• ✅ Maintain current cost controls
        '''.strip()


# For local testing
if __name__ == "__main__":
    # Test SNS event
    test_event = {
        "Records": [
            {
                "Sns": {
                    "Message": json.dumps({
                        "budgetName": "Excipient-Master-Monthly-Budget",
                        "threshold": 85,
                        "currentSpend": 42500,
                        "budgetLimit": 50000,
                        "percentage": 85
                    })
                }
            }
        ]
    }
    
    # Set test webhook URL (use a test webhook)
    os.environ['SLACK_WEBHOOK_URL'] = 'https://hooks.slack.com/services/YOUR/TEST/WEBHOOK'
    
    # Mock context
    class Context:
        function_name = "budget-action-slack"
        memory_limit_in_mb = 128
        invoked_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:budget-action-slack"
        aws_request_id = "test-request-id"
    
    result = lambda_handler(test_event, Context())
    print(f"Result: {json.dumps(result, indent=2)}")

