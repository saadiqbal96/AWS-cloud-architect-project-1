#!/bin/bash

# Script: enable-flow-logs.sh
# Purpose: Enable VPC Flow Logs for both VPCs
# Usage: ./enable-flow-logs.sh

set -e  # Exit on error

echo "=================================================="
echo "VPC Flow Logs Enablement Script"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
EAST_REGION="us-east-1"
WEST_REGION="us-west-2"

# Check if vpc-ids.txt exists
if [ ! -f vpc-ids.txt ]; then
    echo -e "${RED}Error: vpc-ids.txt not found${NC}"
    echo "Please run ./create-vpcs.sh first"
    exit 1
fi

# Source VPC IDs
source vpc-ids.txt

echo -e "${YELLOW}Step 1: Creating IAM Role for VPC Flow Logs${NC}"
echo "=================================================="

# Check if role already exists
ROLE_EXISTS=$(aws iam get-role --role-name VPCFlowLogsRole --query 'Role.RoleName' --output text 2>/dev/null || echo "None")

if [ "$ROLE_EXISTS" == "None" ] || [ -z "$ROLE_EXISTS" ]; then
    echo "Creating IAM role..."
    
    # Create trust policy
    cat > /tmp/flow-logs-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    # Create role
    aws iam create-role \
        --role-name VPCFlowLogsRole \
        --assume-role-policy-document file:///tmp/flow-logs-trust-policy.json > /dev/null
    
    # Attach policy
    aws iam attach-role-policy \
        --role-name VPCFlowLogsRole \
        --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
    
    echo -e "${GREEN}✓ IAM role created${NC}"
    
    # Clean up temp file
    rm /tmp/flow-logs-trust-policy.json
    
    # Wait for role to propagate
    echo "Waiting for IAM role to propagate (10 seconds)..."
    sleep 10
else
    echo -e "${GREEN}✓ IAM role already exists${NC}"
fi

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name VPCFlowLogsRole --query 'Role.Arn' --output text)
echo "Role ARN: $ROLE_ARN"
echo ""

echo -e "${YELLOW}Step 2: Enabling Flow Logs for East VPC${NC}"
echo "=================================================="

# Check if log group exists
EAST_LOG_GROUP_EXISTS=$(aws logs describe-log-groups \
    --log-group-name-prefix /aws/vpc/flowlogs/excipient-vpc-east \
    --region $EAST_REGION \
    --query 'logGroups[0].logGroupName' \
    --output text 2>/dev/null || echo "None")

if [ "$EAST_LOG_GROUP_EXISTS" == "None" ] || [ -z "$EAST_LOG_GROUP_EXISTS" ]; then
    echo "Creating log group..."
    aws logs create-log-group \
        --log-group-name /aws/vpc/flowlogs/excipient-vpc-east \
        --region $EAST_REGION
    
    # Set retention to 1 day to save costs
    aws logs put-retention-policy \
        --log-group-name /aws/vpc/flowlogs/excipient-vpc-east \
        --retention-in-days 1 \
        --region $EAST_REGION
    
    echo -e "${GREEN}✓ Log group created${NC}"
else
    echo -e "${GREEN}✓ Log group already exists${NC}"
fi

# Check if flow logs already enabled
EAST_FLOW_LOGS=$(aws ec2 describe-flow-logs \
    --filter "Name=resource-id,Values=$EAST_VPC_ID" \
    --region $EAST_REGION \
    --query 'FlowLogs[0].FlowLogId' \
    --output text 2>/dev/null || echo "None")

if [ "$EAST_FLOW_LOGS" == "None" ] || [ -z "$EAST_FLOW_LOGS" ]; then
    echo "Enabling VPC Flow Logs..."
    aws ec2 create-flow-logs \
        --resource-type VPC \
        --resource-ids $EAST_VPC_ID \
        --traffic-type ALL \
        --log-destination-type cloud-watch-logs \
        --log-group-name /aws/vpc/flowlogs/excipient-vpc-east \
        --deliver-logs-permission-arn $ROLE_ARN \
        --region $EAST_REGION > /dev/null
    
    echo -e "${GREEN}✓ VPC Flow Logs enabled for East VPC${NC}"
else
    echo -e "${GREEN}✓ VPC Flow Logs already enabled${NC}"
fi

echo ""

echo -e "${YELLOW}Step 3: Enabling Flow Logs for West VPC${NC}"
echo "=================================================="

# Check if log group exists
WEST_LOG_GROUP_EXISTS=$(aws logs describe-log-groups \
    --log-group-name-prefix /aws/vpc/flowlogs/excipient-vpc-west \
    --region $WEST_REGION \
    --query 'logGroups[0].logGroupName' \
    --output text 2>/dev/null || echo "None")

if [ "$WEST_LOG_GROUP_EXISTS" == "None" ] || [ -z "$WEST_LOG_GROUP_EXISTS" ]; then
    echo "Creating log group..."
    aws logs create-log-group \
        --log-group-name /aws/vpc/flowlogs/excipient-vpc-west \
        --region $WEST_REGION
    
    # Set retention to 1 day to save costs
    aws logs put-retention-policy \
        --log-group-name /aws/vpc/flowlogs/excipient-vpc-west \
        --retention-in-days 1 \
        --region $WEST_REGION
    
    echo -e "${GREEN}✓ Log group created${NC}"
else
    echo -e "${GREEN}✓ Log group already exists${NC}"
fi

# Check if flow logs already enabled
WEST_FLOW_LOGS=$(aws ec2 describe-flow-logs \
    --filter "Name=resource-id,Values=$WEST_VPC_ID" \
    --region $WEST_REGION \
    --query 'FlowLogs[0].FlowLogId' \
    --output text 2>/dev/null || echo "None")

if [ "$WEST_FLOW_LOGS" == "None" ] || [ -z "$WEST_FLOW_LOGS" ]; then
    echo "Enabling VPC Flow Logs..."
    aws ec2 create-flow-logs \
        --resource-type VPC \
        --resource-ids $WEST_VPC_ID \
        --traffic-type ALL \
        --log-destination-type cloud-watch-logs \
        --log-group-name /aws/vpc/flowlogs/excipient-vpc-west \
        --deliver-logs-permission-arn $ROLE_ARN \
        --region $WEST_REGION > /dev/null
    
    echo -e "${GREEN}✓ VPC Flow Logs enabled for West VPC${NC}"
else
    echo -e "${GREEN}✓ VPC Flow Logs already enabled${NC}"
fi

echo ""
echo -e "${GREEN}=================================================="
echo "VPC Flow Logs Setup Complete!"
echo "==================================================${NC}"
echo ""
echo -e "${YELLOW}Important Information:${NC}"
echo "  • Logs will appear in 5-10 minutes"
echo "  • Log retention set to 1 day (cost optimization)"
echo "  • East log group: /aws/vpc/flowlogs/excipient-vpc-east"
echo "  • West log group: /aws/vpc/flowlogs/excipient-vpc-west"
echo ""
echo -e "${YELLOW}How to View Logs:${NC}"
echo ""
echo "AWS Console:"
echo "  1. Go to CloudWatch console"
echo "  2. Select correct region (us-east-1 or us-west-2)"
echo "  3. Click 'Logs' → 'Log groups'"
echo "  4. Find /aws/vpc/flowlogs/excipient-vpc-*"
echo ""
echo "AWS CLI:"
echo -e "  ${BLUE}# View East VPC logs${NC}"
echo "  aws logs tail /aws/vpc/flowlogs/excipient-vpc-east --region us-east-1 --follow"
echo ""
echo -e "  ${BLUE}# View West VPC logs${NC}"
echo "  aws logs tail /aws/vpc/flowlogs/excipient-vpc-west --region us-west-2 --follow"
echo ""
echo -e "  ${BLUE}# Search for ACCEPT traffic${NC}"
echo "  aws logs filter-log-events --log-group-name /aws/vpc/flowlogs/excipient-vpc-east --region us-east-1 --filter-pattern 'ACCEPT'"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Wait 5-10 minutes for logs to start appearing"
echo "2. SSH into your instances and run ping tests"
echo "3. Check CloudWatch Logs for ACCEPT entries"
echo "4. Capture screenshots for your project submission"
echo ""

