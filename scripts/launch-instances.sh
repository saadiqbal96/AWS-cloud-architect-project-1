#!/bin/bash

# Script: launch-instances.sh
# Purpose: Launch EC2 instances in both VPCs for connectivity testing
# Usage: ./launch-instances.sh <key-name-east> <key-name-west>

set -e  # Exit on error

echo "=================================================="
echo "EC2 Instance Launch Script for Excipient Technologies"
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
INSTANCE_TYPE="t2.micro"

# Tags
ENV_TAG="Testing"
COST_CENTER="IT-Network"
OWNER="cloud-team@excipient.com"

# Default key pair names (can be overridden by command line arguments)
KEY_NAME_EAST="excipient-keypair-east"
KEY_NAME_WEST="excipient-keypair-west"

# Check command line arguments (optional now)
if [ $# -eq 2 ]; then
    KEY_NAME_EAST=$1
    KEY_NAME_WEST=$2
    echo -e "${BLUE}Using provided key pair names${NC}"
elif [ $# -eq 0 ]; then
    echo -e "${BLUE}Using default key pair names${NC}"
else
    echo -e "${RED}Error: Invalid number of arguments${NC}"
    echo ""
    echo "Usage: $0 [key-name-east] [key-name-west]"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Use default key pairs (will be created automatically)"
    echo "  $0 my-keypair-east my-keypair-west   # Use custom key pairs"
    echo ""
    exit 1
fi

echo -e "${BLUE}Configuration:${NC}"
echo "  East Region:    $EAST_REGION"
echo "  West Region:    $WEST_REGION"
echo "  Instance Type:  $INSTANCE_TYPE"
echo "  Key Pair East:  $KEY_NAME_EAST"
echo "  Key Pair West:  $KEY_NAME_WEST"
echo ""

# Check if vpc-ids.txt exists
if [ ! -f vpc-ids.txt ]; then
    echo -e "${RED}Error: vpc-ids.txt not found${NC}"
    echo "Please run ./create-vpcs.sh first to create VPC resources"
    exit 1
fi

# Source VPC IDs from file
echo -e "${YELLOW}Loading VPC configuration from vpc-ids.txt...${NC}"
source vpc-ids.txt

# Verify required variables are set
if [ -z "$EAST_SUBNET_ID" ] || [ -z "$EAST_SG_ID" ] || [ -z "$WEST_SUBNET_ID" ] || [ -z "$WEST_SG_ID" ]; then
    echo -e "${RED}Error: Required VPC resources not found in vpc-ids.txt${NC}"
    echo "Please ensure create-vpcs.sh completed successfully"
    exit 1
fi

echo -e "${GREEN}✓ VPC configuration loaded${NC}"
echo ""

# Step 1: Create or verify SSH key pairs
echo -e "${YELLOW}Step 1: Setting up SSH key pairs${NC}"
echo "=================================================="

# Create ~/.ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Check and create East key pair
echo "Checking for key pair in us-east-1..."
EAST_KEY_EXISTS=$(aws ec2 describe-key-pairs \
    --key-names $KEY_NAME_EAST \
    --region $EAST_REGION \
    --query 'KeyPairs[0].KeyName' \
    --output text 2>/dev/null || echo "None")

if [ "$EAST_KEY_EXISTS" == "None" ] || [ -z "$EAST_KEY_EXISTS" ]; then
    echo "Creating new key pair: $KEY_NAME_EAST"
    aws ec2 create-key-pair \
        --key-name $KEY_NAME_EAST \
        --region $EAST_REGION \
        --query 'KeyMaterial' \
        --output text > ~/.ssh/${KEY_NAME_EAST}.pem
    
    chmod 400 ~/.ssh/${KEY_NAME_EAST}.pem
    echo -e "${GREEN}✓ Key pair created and saved to ~/.ssh/${KEY_NAME_EAST}.pem${NC}"
else
    echo -e "${GREEN}✓ Key pair already exists: $KEY_NAME_EAST${NC}"
    
    # Check if local key file exists
    if [ ! -f ~/.ssh/${KEY_NAME_EAST}.pem ]; then
        echo -e "${YELLOW}⚠ Warning: Key pair exists in AWS but private key not found locally${NC}"
        echo -e "${YELLOW}  Expected location: ~/.ssh/${KEY_NAME_EAST}.pem${NC}"
        echo -e "${YELLOW}  You may not be able to SSH into the instance${NC}"
    fi
fi

# Check and create West key pair
echo "Checking for key pair in us-west-2..."
WEST_KEY_EXISTS=$(aws ec2 describe-key-pairs \
    --key-names $KEY_NAME_WEST \
    --region $WEST_REGION \
    --query 'KeyPairs[0].KeyName' \
    --output text 2>/dev/null || echo "None")

if [ "$WEST_KEY_EXISTS" == "None" ] || [ -z "$WEST_KEY_EXISTS" ]; then
    echo "Creating new key pair: $KEY_NAME_WEST"
    aws ec2 create-key-pair \
        --key-name $KEY_NAME_WEST \
        --region $WEST_REGION \
        --query 'KeyMaterial' \
        --output text > ~/.ssh/${KEY_NAME_WEST}.pem
    
    chmod 400 ~/.ssh/${KEY_NAME_WEST}.pem
    echo -e "${GREEN}✓ Key pair created and saved to ~/.ssh/${KEY_NAME_WEST}.pem${NC}"
else
    echo -e "${GREEN}✓ Key pair already exists: $KEY_NAME_WEST${NC}"
    
    # Check if local key file exists
    if [ ! -f ~/.ssh/${KEY_NAME_WEST}.pem ]; then
        echo -e "${YELLOW}⚠ Warning: Key pair exists in AWS but private key not found locally${NC}"
        echo -e "${YELLOW}  Expected location: ~/.ssh/${KEY_NAME_WEST}.pem${NC}"
        echo -e "${YELLOW}  You may not be able to SSH into the instance${NC}"
    fi
fi

echo ""

# Step 2: Discover latest Amazon Linux 2 AMI in us-east-1
echo -e "${YELLOW}Step 2: Discovering latest Amazon Linux 2 AMI in us-east-1${NC}"
echo "=================================================="

echo "Querying AWS for latest Amazon Linux 2 AMI..."
EAST_AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
              "Name=state,Values=available" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
    --output text \
    --region $EAST_REGION)

if [ -z "$EAST_AMI_ID" ] || [ "$EAST_AMI_ID" == "None" ]; then
    echo -e "${RED}Failed to discover AMI in us-east-1${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found AMI in us-east-1: $EAST_AMI_ID${NC}"
echo ""

# Step 3: Discover latest Amazon Linux 2 AMI in us-west-2
echo -e "${YELLOW}Step 3: Discovering latest Amazon Linux 2 AMI in us-west-2${NC}"
echo "=================================================="

echo "Querying AWS for latest Amazon Linux 2 AMI..."
WEST_AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
              "Name=state,Values=available" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
    --output text \
    --region $WEST_REGION)

if [ -z "$WEST_AMI_ID" ] || [ "$WEST_AMI_ID" == "None" ]; then
    echo -e "${RED}Failed to discover AMI in us-west-2${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found AMI in us-west-2: $WEST_AMI_ID${NC}"
echo ""

# Step 4: Launch EC2 instance in us-east-1
echo -e "${YELLOW}Step 4: Launching EC2 instance in us-east-1${NC}"
echo "=================================================="

echo "Launching t2.micro instance..."
EAST_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $EAST_AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME_EAST \
    --security-group-ids $EAST_SG_ID \
    --subnet-id $EAST_SUBNET_ID \
    --associate-public-ip-address \
    --region $EAST_REGION \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=excipient-test-east},{Key=Environment,Value=$ENV_TAG},{Key=CostCenter,Value=$COST_CENTER},{Key=Owner,Value=$OWNER}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

if [ -z "$EAST_INSTANCE_ID" ]; then
    echo -e "${RED}Failed to launch instance in us-east-1${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Instance launched: $EAST_INSTANCE_ID${NC}"
echo ""

# Step 5: Launch EC2 instance in us-west-2
echo -e "${YELLOW}Step 5: Launching EC2 instance in us-west-2${NC}"
echo "=================================================="

echo "Launching t2.micro instance..."
WEST_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $WEST_AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME_WEST \
    --security-group-ids $WEST_SG_ID \
    --subnet-id $WEST_SUBNET_ID \
    --associate-public-ip-address \
    --region $WEST_REGION \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=excipient-test-west},{Key=Environment,Value=$ENV_TAG},{Key=CostCenter,Value=$COST_CENTER},{Key=Owner,Value=$OWNER}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

if [ -z "$WEST_INSTANCE_ID" ]; then
    echo -e "${RED}Failed to launch instance in us-west-2${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Instance launched: $WEST_INSTANCE_ID${NC}"
echo ""

# Step 6: Wait for instances to be running
echo -e "${YELLOW}Step 6: Waiting for instances to reach running state${NC}"
echo "=================================================="

echo "Waiting for East instance to be running (this may take 1-2 minutes)..."
aws ec2 wait instance-running \
    --instance-ids $EAST_INSTANCE_ID \
    --region $EAST_REGION

echo -e "${GREEN}✓ East instance is running${NC}"

echo "Waiting for West instance to be running (this may take 1-2 minutes)..."
aws ec2 wait instance-running \
    --instance-ids $WEST_INSTANCE_ID \
    --region $WEST_REGION

echo -e "${GREEN}✓ West instance is running${NC}"
echo ""

# Step 7: Retrieve instance details
echo -e "${YELLOW}Step 7: Retrieving instance details${NC}"
echo "=================================================="

echo "Fetching East instance details..."
EAST_DETAILS=$(aws ec2 describe-instances \
    --instance-ids $EAST_INSTANCE_ID \
    --region $EAST_REGION \
    --query 'Reservations[0].Instances[0].[PublicIpAddress,PrivateIpAddress]' \
    --output text)

EAST_PUBLIC_IP=$(echo $EAST_DETAILS | awk '{print $1}')
EAST_PRIVATE_IP=$(echo $EAST_DETAILS | awk '{print $2}')

if [ -z "$EAST_PUBLIC_IP" ] || [ -z "$EAST_PRIVATE_IP" ]; then
    echo -e "${RED}Failed to retrieve East instance details${NC}"
    exit 1
fi

echo -e "${GREEN}✓ East instance details retrieved${NC}"

echo "Fetching West instance details..."
WEST_DETAILS=$(aws ec2 describe-instances \
    --instance-ids $WEST_INSTANCE_ID \
    --region $WEST_REGION \
    --query 'Reservations[0].Instances[0].[PublicIpAddress,PrivateIpAddress]' \
    --output text)

WEST_PUBLIC_IP=$(echo $WEST_DETAILS | awk '{print $1}')
WEST_PRIVATE_IP=$(echo $WEST_DETAILS | awk '{print $2}')

if [ -z "$WEST_PUBLIC_IP" ] || [ -z "$WEST_PRIVATE_IP" ]; then
    echo -e "${RED}Failed to retrieve West instance details${NC}"
    exit 1
fi

echo -e "${GREEN}✓ West instance details retrieved${NC}"
echo ""

# Step 8: Save instance information to file
echo -e "${YELLOW}Step 8: Saving instance information${NC}"
echo "=================================================="

TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

cat > instance-ids.txt <<EOF
# EC2 Instance Information
# Generated: $TIMESTAMP

# East Region (us-east-1)
EAST_INSTANCE_ID=$EAST_INSTANCE_ID
EAST_PUBLIC_IP=$EAST_PUBLIC_IP
EAST_PRIVATE_IP=$EAST_PRIVATE_IP
EAST_AMI_ID=$EAST_AMI_ID
EAST_KEY_NAME=$KEY_NAME_EAST

# West Region (us-west-2)
WEST_INSTANCE_ID=$WEST_INSTANCE_ID
WEST_PUBLIC_IP=$WEST_PUBLIC_IP
WEST_PRIVATE_IP=$WEST_PRIVATE_IP
WEST_AMI_ID=$WEST_AMI_ID
WEST_KEY_NAME=$KEY_NAME_WEST

# Launch Configuration
INSTANCE_TYPE=$INSTANCE_TYPE
LAUNCH_TIMESTAMP="$TIMESTAMP"
EOF

echo -e "${GREEN}✓ Instance information saved to instance-ids.txt${NC}"
echo ""

# Display Summary
echo ""
echo -e "${GREEN}=================================================="
echo "Instance Launch Complete!"
echo "==================================================${NC}"
echo ""
echo -e "${YELLOW}Instance Details:${NC}"
echo "----------------------------------------"
echo ""
echo -e "${BLUE}US-EAST-1:${NC}"
echo "  Instance ID:    $EAST_INSTANCE_ID"
echo "  Public IP:      $EAST_PUBLIC_IP"
echo "  Private IP:     $EAST_PRIVATE_IP"
echo "  AMI ID:         $EAST_AMI_ID"
echo "  Key Pair:       $KEY_NAME_EAST"
echo ""
echo -e "${BLUE}US-WEST-2:${NC}"
echo "  Instance ID:    $WEST_INSTANCE_ID"
echo "  Public IP:      $WEST_PUBLIC_IP"
echo "  Private IP:     $WEST_PRIVATE_IP"
echo "  AMI ID:         $WEST_AMI_ID"
echo "  Key Pair:       $KEY_NAME_WEST"
echo ""
echo -e "${YELLOW}SSH Connection Commands:${NC}"
echo "----------------------------------------"
echo ""
echo "Connect to East instance:"
echo -e "${BLUE}ssh -i ~/.ssh/${KEY_NAME_EAST}.pem ec2-user@${EAST_PUBLIC_IP}${NC}"
echo ""
echo "Connect to West instance:"
echo -e "${BLUE}ssh -i ~/.ssh/${KEY_NAME_WEST}.pem ec2-user@${WEST_PUBLIC_IP}${NC}"
echo ""
echo -e "${YELLOW}Connectivity Testing:${NC}"
echo "----------------------------------------"
echo ""
echo "1. SSH to East instance and ping West private IP:"
echo -e "   ${BLUE}ping -c 4 ${WEST_PRIVATE_IP}${NC}"
echo ""
echo "2. SSH to West instance and ping East private IP:"
echo -e "   ${BLUE}ping -c 4 ${EAST_PRIVATE_IP}${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Test SSH connectivity to both instances"
echo "2. Verify cross-region ping functionality"
echo "3. Check VPC Flow Logs in CloudWatch"
echo "4. Capture screenshots for documentation"
echo "5. Run ./cleanup-resources.sh when finished"
echo ""
echo -e "${RED}⚠️  Important: Remember to clean up resources to avoid charges!${NC}"
echo ""

