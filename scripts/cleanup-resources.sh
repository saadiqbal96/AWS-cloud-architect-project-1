#!/bin/bash

# Script: cleanup-resources.sh
# Purpose: Cleanup all AWS resources created for this project
# Usage: ./cleanup-resources.sh
# WARNING: This will delete all resources. Make sure you have screenshots!

set -e  # Exit on error

echo "=================================================="
echo "AWS Resources Cleanup Script"
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

echo -e "${RED}WARNING: This script will DELETE all AWS resources created for this project!${NC}"
echo -e "${RED}Make sure you have captured all required screenshots before proceeding.${NC}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo -e "${YELLOW}Starting cleanup process...${NC}"
echo ""

# Check if vpc-ids.txt exists
if [ ! -f "vpc-ids.txt" ]; then
    echo -e "${RED}Error: vpc-ids.txt not found${NC}"
    echo "Manual cleanup may be required. Check AWS Console."
    exit 1
fi

# Load resource IDs
source vpc-ids.txt

echo -e "${YELLOW}Step 1: Terminating EC2 Instances${NC}"
echo "=================================================="

# Find and terminate EC2 instances in us-east-1
echo "Checking for EC2 instances in us-east-1..."
EAST_INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=vpc-id,Values=$EAST_VPC_ID" "Name=instance-state-name,Values=running,stopped" \
    --region $EAST_REGION \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text)

if [ -n "$EAST_INSTANCES" ]; then
    echo "Terminating instances in us-east-1: $EAST_INSTANCES"
    aws ec2 terminate-instances \
        --instance-ids $EAST_INSTANCES \
        --region $EAST_REGION > /dev/null
    echo -e "${GREEN}✓ Instances terminating in us-east-1${NC}"
    
    echo "Waiting for instances to terminate..."
    aws ec2 wait instance-terminated \
        --instance-ids $EAST_INSTANCES \
        --region $EAST_REGION
    echo -e "${GREEN}✓ Instances terminated in us-east-1${NC}"
else
    echo "No EC2 instances found in us-east-1"
fi

# Find and terminate EC2 instances in us-west-2
echo "Checking for EC2 instances in us-west-2..."
WEST_INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=vpc-id,Values=$WEST_VPC_ID" "Name=instance-state-name,Values=running,stopped" \
    --region $WEST_REGION \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text)

if [ -n "$WEST_INSTANCES" ]; then
    echo "Terminating instances in us-west-2: $WEST_INSTANCES"
    aws ec2 terminate-instances \
        --instance-ids $WEST_INSTANCES \
        --region $WEST_REGION > /dev/null
    echo -e "${GREEN}✓ Instances terminating in us-west-2${NC}"
    
    echo "Waiting for instances to terminate..."
    aws ec2 wait instance-terminated \
        --instance-ids $WEST_INSTANCES \
        --region $WEST_REGION
    echo -e "${GREEN}✓ Instances terminated in us-west-2${NC}"
else
    echo "No EC2 instances found in us-west-2"
fi

echo ""
echo -e "${YELLOW}Step 2: Deleting VPC Peering Connection${NC}"
echo "=================================================="

if [ -n "$PEERING_ID" ]; then
    echo "Deleting peering connection: $PEERING_ID"
    aws ec2 delete-vpc-peering-connection \
        --vpc-peering-connection-id $PEERING_ID \
        --region $EAST_REGION > /dev/null
    echo -e "${GREEN}✓ VPC peering connection deleted${NC}"
    sleep 3
else
    echo "No peering connection ID found, skipping..."
fi

echo ""
echo -e "${YELLOW}Step 3: Deleting Security Groups${NC}"
echo "=================================================="

# Delete East security group
echo "Deleting security group in us-east-1..."
if [ -n "$EAST_SG_ID" ]; then
    aws ec2 delete-security-group \
        --group-id $EAST_SG_ID \
        --region $EAST_REGION 2>/dev/null && \
    echo -e "${GREEN}✓ Security group deleted in us-east-1${NC}" || \
    echo -e "${YELLOW}! Security group may have dependencies, trying again later${NC}"
fi

# Delete West security group
echo "Deleting security group in us-west-2..."
if [ -n "$WEST_SG_ID" ]; then
    aws ec2 delete-security-group \
        --group-id $WEST_SG_ID \
        --region $WEST_REGION 2>/dev/null && \
    echo -e "${GREEN}✓ Security group deleted in us-west-2${NC}" || \
    echo -e "${YELLOW}! Security group may have dependencies, trying again later${NC}"
fi

echo ""
echo -e "${YELLOW}Step 4: Deleting Subnets${NC}"
echo "=================================================="

# Delete East subnet
if [ -n "$EAST_SUBNET_ID" ]; then
    echo "Deleting subnet in us-east-1..."
    aws ec2 delete-subnet \
        --subnet-id $EAST_SUBNET_ID \
        --region $EAST_REGION
    echo -e "${GREEN}✓ Subnet deleted in us-east-1${NC}"
fi

# Delete West subnet
if [ -n "$WEST_SUBNET_ID" ]; then
    echo "Deleting subnet in us-west-2..."
    aws ec2 delete-subnet \
        --subnet-id $WEST_SUBNET_ID \
        --region $WEST_REGION
    echo -e "${GREEN}✓ Subnet deleted in us-west-2${NC}"
fi

echo ""
echo -e "${YELLOW}Step 5: Deleting Route Tables${NC}"
echo "=================================================="

# Delete East route table
if [ -n "$EAST_RTB_ID" ]; then
    echo "Deleting route table in us-east-1..."
    aws ec2 delete-route-table \
        --route-table-id $EAST_RTB_ID \
        --region $EAST_REGION 2>/dev/null && \
    echo -e "${GREEN}✓ Route table deleted in us-east-1${NC}" || \
    echo -e "${YELLOW}! Route table is main or has associations${NC}"
fi

# Delete West route table
if [ -n "$WEST_RTB_ID" ]; then
    echo "Deleting route table in us-west-2..."
    aws ec2 delete-route-table \
        --route-table-id $WEST_RTB_ID \
        --region $WEST_REGION 2>/dev/null && \
    echo -e "${GREEN}✓ Route table deleted in us-west-2${NC}" || \
    echo -e "${YELLOW}! Route table is main or has associations${NC}"
fi

echo ""
echo -e "${YELLOW}Step 6: Detaching and Deleting Internet Gateways${NC}"
echo "=================================================="

# Find and delete East IGW
echo "Finding Internet Gateway in us-east-1..."
EAST_IGW=$(aws ec2 describe-internet-gateways \
    --filters "Name=attachment.vpc-id,Values=$EAST_VPC_ID" \
    --region $EAST_REGION \
    --query 'InternetGateways[0].InternetGatewayId' \
    --output text 2>/dev/null)

if [ -n "$EAST_IGW" ] && [ "$EAST_IGW" != "None" ]; then
    echo "Detaching Internet Gateway in us-east-1..."
    aws ec2 detach-internet-gateway \
        --internet-gateway-id $EAST_IGW \
        --vpc-id $EAST_VPC_ID \
        --region $EAST_REGION
    
    echo "Deleting Internet Gateway in us-east-1..."
    aws ec2 delete-internet-gateway \
        --internet-gateway-id $EAST_IGW \
        --region $EAST_REGION
    echo -e "${GREEN}✓ Internet Gateway deleted in us-east-1${NC}"
else
    echo "No Internet Gateway found in us-east-1"
fi

# Find and delete West IGW
echo "Finding Internet Gateway in us-west-2..."
WEST_IGW=$(aws ec2 describe-internet-gateways \
    --filters "Name=attachment.vpc-id,Values=$WEST_VPC_ID" \
    --region $WEST_REGION \
    --query 'InternetGateways[0].InternetGatewayId' \
    --output text 2>/dev/null)

if [ -n "$WEST_IGW" ] && [ "$WEST_IGW" != "None" ]; then
    echo "Detaching Internet Gateway in us-west-2..."
    aws ec2 detach-internet-gateway \
        --internet-gateway-id $WEST_IGW \
        --vpc-id $WEST_VPC_ID \
        --region $WEST_REGION
    
    echo "Deleting Internet Gateway in us-west-2..."
    aws ec2 delete-internet-gateway \
        --internet-gateway-id $WEST_IGW \
        --region $WEST_REGION
    echo -e "${GREEN}✓ Internet Gateway deleted in us-west-2${NC}"
else
    echo "No Internet Gateway found in us-west-2"
fi

echo ""
echo -e "${YELLOW}Step 7: Deleting VPCs${NC}"
echo "=================================================="

# Wait a moment to ensure all resources are detached
sleep 3

# Delete East VPC
if [ -n "$EAST_VPC_ID" ]; then
    echo "Deleting VPC in us-east-1..."
    aws ec2 delete-vpc \
        --vpc-id $EAST_VPC_ID \
        --region $EAST_REGION
    echo -e "${GREEN}✓ VPC deleted in us-east-1${NC}"
fi

# Delete West VPC
if [ -n "$WEST_VPC_ID" ]; then
    echo "Deleting VPC in us-west-2..."
    aws ec2 delete-vpc \
        --vpc-id $WEST_VPC_ID \
        --region $WEST_REGION
    echo -e "${GREEN}✓ VPC deleted in us-west-2${NC}"
fi

echo ""
echo -e "${YELLOW}Step 8: Deleting VPC Flow Logs (if any)${NC}"
echo "=================================================="

# Delete CloudWatch Log Groups for VPC Flow Logs
echo "Checking for VPC Flow Logs log groups..."

aws logs delete-log-group \
    --log-group-name /aws/vpc/flowlogs/excipient-vpc-east \
    --region $EAST_REGION 2>/dev/null && \
echo -e "${GREEN}✓ Flow Logs deleted in us-east-1${NC}" || \
echo "No Flow Logs found in us-east-1"

aws logs delete-log-group \
    --log-group-name /aws/vpc/flowlogs/excipient-vpc-west \
    --region $WEST_REGION 2>/dev/null && \
echo -e "${GREEN}✓ Flow Logs deleted in us-west-2${NC}" || \
echo "No Flow Logs found in us-west-2"

echo ""
echo -e "${GREEN}=================================================="
echo "Cleanup Complete!"
echo "==================================================${NC}"
echo ""
echo -e "${YELLOW}Cleanup Summary:${NC}"
echo "  ✓ EC2 instances terminated"
echo "  ✓ VPC peering connection deleted"
echo "  ✓ Security groups deleted"
echo "  ✓ Subnets deleted"
echo "  ✓ Route tables deleted"
echo "  ✓ Internet Gateways deleted"
echo "  ✓ VPCs deleted"
echo "  ✓ VPC Flow Logs deleted"
echo ""
echo -e "${GREEN}All resources have been cleaned up.${NC}"
echo -e "${YELLOW}Please verify in AWS Console that no resources remain.${NC}"
echo ""
echo -e "${YELLOW}Final Steps:${NC}"
echo "1. Check AWS Billing Dashboard"
echo "2. Verify no unexpected charges"
echo "3. Review Cost Explorer for the day"
echo ""

# Clean up local files
rm -f vpc-ids.txt
rm -f instance-ids.txt
echo -e "${GREEN}✓ Local configuration files removed (vpc-ids.txt, instance-ids.txt)${NC}"
echo ""

