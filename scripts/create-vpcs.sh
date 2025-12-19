#!/bin/bash

# Script: create-vpcs.sh
# Purpose: Automate VPC creation for both us-east-1 and us-west-2 regions
# Usage: ./create-vpcs.sh

set -e  # Exit on error

echo "=================================================="
echo "VPC Creation Script for Excipient Technologies"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
EAST_REGION="us-east-1"
WEST_REGION="us-west-2"
EAST_VPC_CIDR="10.0.0.0/16"
WEST_VPC_CIDR="192.168.0.0/16"
EAST_SUBNET_CIDR="10.0.1.0/24"
WEST_SUBNET_CIDR="192.168.1.0/24"

# Tags
ENV_TAG="Production"
COST_CENTER="IT-Network"
OWNER="cloud-team@excipient.com"

echo -e "${YELLOW}Step 1: Creating VPC in us-east-1${NC}"
echo "=================================================="

# Create VPC in us-east-1
echo "Creating VPC with CIDR $EAST_VPC_CIDR..."
EAST_VPC_ID=$(aws ec2 create-vpc \
    --cidr-block $EAST_VPC_CIDR \
    --region $EAST_REGION \
    --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=excipient-vpc-east},{Key=Environment,Value=$ENV_TAG},{Key=CostCenter,Value=$COST_CENTER},{Key=Owner,Value=$OWNER}]" \
    --query 'Vpc.VpcId' \
    --output text)

if [ -z "$EAST_VPC_ID" ]; then
    echo -e "${RED}Failed to create VPC in us-east-1${NC}"
    exit 1
fi

echo -e "${GREEN}✓ VPC created in us-east-1: $EAST_VPC_ID${NC}"

# Enable DNS hostnames and DNS support
aws ec2 modify-vpc-attribute \
    --vpc-id $EAST_VPC_ID \
    --enable-dns-hostnames \
    --region $EAST_REGION

aws ec2 modify-vpc-attribute \
    --vpc-id $EAST_VPC_ID \
    --enable-dns-support \
    --region $EAST_REGION

echo -e "${GREEN}✓ DNS hostnames and support enabled${NC}"

# Create Internet Gateway for us-east-1
echo "Creating Internet Gateway..."
EAST_IGW_ID=$(aws ec2 create-internet-gateway \
    --region $EAST_REGION \
    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=excipient-igw-east},{Key=Environment,Value=$ENV_TAG}]" \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

echo -e "${GREEN}✓ Internet Gateway created: $EAST_IGW_ID${NC}"

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway \
    --internet-gateway-id $EAST_IGW_ID \
    --vpc-id $EAST_VPC_ID \
    --region $EAST_REGION

echo -e "${GREEN}✓ Internet Gateway attached to VPC${NC}"

# Create Subnet in us-east-1
echo "Creating subnet with CIDR $EAST_SUBNET_CIDR..."
EAST_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $EAST_VPC_ID \
    --cidr-block $EAST_SUBNET_CIDR \
    --availability-zone ${EAST_REGION}a \
    --region $EAST_REGION \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=excipient-subnet-east-public},{Key=Environment,Value=$ENV_TAG}]" \
    --query 'Subnet.SubnetId' \
    --output text)

echo -e "${GREEN}✓ Subnet created: $EAST_SUBNET_ID${NC}"

# Enable auto-assign public IP
aws ec2 modify-subnet-attribute \
    --subnet-id $EAST_SUBNET_ID \
    --map-public-ip-on-launch \
    --region $EAST_REGION

echo -e "${GREEN}✓ Auto-assign public IP enabled${NC}"

# Create Route Table for us-east-1
echo "Creating route table..."
EAST_RTB_ID=$(aws ec2 create-route-table \
    --vpc-id $EAST_VPC_ID \
    --region $EAST_REGION \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=excipient-rtb-east-public},{Key=Environment,Value=$ENV_TAG}]" \
    --query 'RouteTable.RouteTableId' \
    --output text)

echo -e "${GREEN}✓ Route table created: $EAST_RTB_ID${NC}"

# Add route to Internet Gateway
aws ec2 create-route \
    --route-table-id $EAST_RTB_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $EAST_IGW_ID \
    --region $EAST_REGION > /dev/null

echo -e "${GREEN}✓ Route to Internet Gateway added${NC}"

# Associate Route Table with Subnet
aws ec2 associate-route-table \
    --route-table-id $EAST_RTB_ID \
    --subnet-id $EAST_SUBNET_ID \
    --region $EAST_REGION > /dev/null

echo -e "${GREEN}✓ Route table associated with subnet${NC}"

# Create Security Group for us-east-1
echo "Creating security group..."
EAST_SG_ID=$(aws ec2 create-security-group \
    --group-name excipient-sg-east \
    --description "Security group for VPC East EC2 instances" \
    --vpc-id $EAST_VPC_ID \
    --region $EAST_REGION \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=excipient-sg-east},{Key=Environment,Value=$ENV_TAG}]" \
    --query 'GroupId' \
    --output text)

echo -e "${GREEN}✓ Security group created: $EAST_SG_ID${NC}"

# Get your public IP for SSH access
MY_IP=$(curl -s https://checkip.amazonaws.com)
echo "Your public IP: $MY_IP"

# Add SSH rule
aws ec2 authorize-security-group-ingress \
    --group-id $EAST_SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr ${MY_IP}/32 \
    --region $EAST_REGION

echo -e "${GREEN}✓ SSH access allowed from your IP${NC}"

# Add ICMP rule for west VPC
aws ec2 authorize-security-group-ingress \
    --group-id $EAST_SG_ID \
    --protocol icmp \
    --port -1 \
    --cidr $WEST_VPC_CIDR \
    --region $EAST_REGION

echo -e "${GREEN}✓ ICMP allowed from West VPC${NC}"

# Add all traffic rule for west VPC
aws ec2 authorize-security-group-ingress \
    --group-id $EAST_SG_ID \
    --protocol -1 \
    --cidr $WEST_VPC_CIDR \
    --region $EAST_REGION

echo -e "${GREEN}✓ All traffic allowed from West VPC${NC}"

echo ""
echo -e "${YELLOW}Step 2: Creating VPC in us-west-2${NC}"
echo "=================================================="

# Create VPC in us-west-2
echo "Creating VPC with CIDR $WEST_VPC_CIDR..."
WEST_VPC_ID=$(aws ec2 create-vpc \
    --cidr-block $WEST_VPC_CIDR \
    --region $WEST_REGION \
    --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=excipient-vpc-west},{Key=Environment,Value=$ENV_TAG},{Key=CostCenter,Value=$COST_CENTER},{Key=Owner,Value=$OWNER}]" \
    --query 'Vpc.VpcId' \
    --output text)

if [ -z "$WEST_VPC_ID" ]; then
    echo -e "${RED}Failed to create VPC in us-west-2${NC}"
    exit 1
fi

echo -e "${GREEN}✓ VPC created in us-west-2: $WEST_VPC_ID${NC}"

# Enable DNS hostnames and DNS support
aws ec2 modify-vpc-attribute \
    --vpc-id $WEST_VPC_ID \
    --enable-dns-hostnames \
    --region $WEST_REGION

aws ec2 modify-vpc-attribute \
    --vpc-id $WEST_VPC_ID \
    --enable-dns-support \
    --region $WEST_REGION

echo -e "${GREEN}✓ DNS hostnames and support enabled${NC}"

# Create Internet Gateway for us-west-2
echo "Creating Internet Gateway..."
WEST_IGW_ID=$(aws ec2 create-internet-gateway \
    --region $WEST_REGION \
    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=excipient-igw-west},{Key=Environment,Value=$ENV_TAG}]" \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

echo -e "${GREEN}✓ Internet Gateway created: $WEST_IGW_ID${NC}"

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway \
    --internet-gateway-id $WEST_IGW_ID \
    --vpc-id $WEST_VPC_ID \
    --region $WEST_REGION

echo -e "${GREEN}✓ Internet Gateway attached to VPC${NC}"

# Create Subnet in us-west-2
echo "Creating subnet with CIDR $WEST_SUBNET_CIDR..."
WEST_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $WEST_VPC_ID \
    --cidr-block $WEST_SUBNET_CIDR \
    --availability-zone ${WEST_REGION}a \
    --region $WEST_REGION \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=excipient-subnet-west-public},{Key=Environment,Value=$ENV_TAG}]" \
    --query 'Subnet.SubnetId' \
    --output text)

echo -e "${GREEN}✓ Subnet created: $WEST_SUBNET_ID${NC}"

# Enable auto-assign public IP
aws ec2 modify-subnet-attribute \
    --subnet-id $WEST_SUBNET_ID \
    --map-public-ip-on-launch \
    --region $WEST_REGION

echo -e "${GREEN}✓ Auto-assign public IP enabled${NC}"

# Create Route Table for us-west-2
echo "Creating route table..."
WEST_RTB_ID=$(aws ec2 create-route-table \
    --vpc-id $WEST_VPC_ID \
    --region $WEST_REGION \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=excipient-rtb-west-public},{Key=Environment,Value=$ENV_TAG}]" \
    --query 'RouteTable.RouteTableId' \
    --output text)

echo -e "${GREEN}✓ Route table created: $WEST_RTB_ID${NC}"

# Add route to Internet Gateway
aws ec2 create-route \
    --route-table-id $WEST_RTB_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $WEST_IGW_ID \
    --region $WEST_REGION > /dev/null

echo -e "${GREEN}✓ Route to Internet Gateway added${NC}"

# Associate Route Table with Subnet
aws ec2 associate-route-table \
    --route-table-id $WEST_RTB_ID \
    --subnet-id $WEST_SUBNET_ID \
    --region $WEST_REGION > /dev/null

echo -e "${GREEN}✓ Route table associated with subnet${NC}"

# Create Security Group for us-west-2
echo "Creating security group..."
WEST_SG_ID=$(aws ec2 create-security-group \
    --group-name excipient-sg-west \
    --description "Security group for VPC West EC2 instances" \
    --vpc-id $WEST_VPC_ID \
    --region $WEST_REGION \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=excipient-sg-west},{Key=Environment,Value=$ENV_TAG}]" \
    --query 'GroupId' \
    --output text)

echo -e "${GREEN}✓ Security group created: $WEST_SG_ID${NC}"

# Add SSH rule
aws ec2 authorize-security-group-ingress \
    --group-id $WEST_SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr ${MY_IP}/32 \
    --region $WEST_REGION

echo -e "${GREEN}✓ SSH access allowed from your IP${NC}"

# Add ICMP rule for east VPC
aws ec2 authorize-security-group-ingress \
    --group-id $WEST_SG_ID \
    --protocol icmp \
    --port -1 \
    --cidr $EAST_VPC_CIDR \
    --region $WEST_REGION

echo -e "${GREEN}✓ ICMP allowed from East VPC${NC}"

# Add all traffic rule for east VPC
aws ec2 authorize-security-group-ingress \
    --group-id $WEST_SG_ID \
    --protocol -1 \
    --cidr $EAST_VPC_CIDR \
    --region $WEST_REGION

echo -e "${GREEN}✓ All traffic allowed from East VPC${NC}"

echo ""
echo -e "${GREEN}=================================================="
echo "VPC Creation Complete!"
echo "==================================================${NC}"
echo ""
echo -e "${YELLOW}Resource IDs:${NC}"
echo "----------------------------------------"
echo "US-EAST-1:"
echo "  VPC ID:        $EAST_VPC_ID"
echo "  Subnet ID:     $EAST_SUBNET_ID"
echo "  IGW ID:        $EAST_IGW_ID"
echo "  Route Table:   $EAST_RTB_ID"
echo "  Security Group: $EAST_SG_ID"
echo ""
echo "US-WEST-2:"
echo "  VPC ID:        $WEST_VPC_ID"
echo "  Subnet ID:     $WEST_SUBNET_ID"
echo "  IGW ID:        $WEST_IGW_ID"
echo "  Route Table:   $WEST_RTB_ID"
echo "  Security Group: $WEST_SG_ID"
echo ""

# Save IDs to file for use in other scripts
cat > vpc-ids.txt <<EOF
EAST_VPC_ID=$EAST_VPC_ID
EAST_SUBNET_ID=$EAST_SUBNET_ID
EAST_SG_ID=$EAST_SG_ID
EAST_RTB_ID=$EAST_RTB_ID
WEST_VPC_ID=$WEST_VPC_ID
WEST_SUBNET_ID=$WEST_SUBNET_ID
WEST_SG_ID=$WEST_SG_ID
WEST_RTB_ID=$WEST_RTB_ID
EOF

echo -e "${GREEN}✓ Resource IDs saved to vpc-ids.txt${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Run ./setup-peering.sh to create VPC peering connection"
echo "2. Launch EC2 instances for testing"
echo "3. Test connectivity between regions"
echo ""

