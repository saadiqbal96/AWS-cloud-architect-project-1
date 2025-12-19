#!/bin/bash

# Script: setup-peering.sh
# Purpose: Setup VPC peering connection between us-east-1 and us-west-2
# Usage: ./setup-peering.sh

set -e  # Exit on error

echo "=================================================="
echo "VPC Peering Setup Script"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if vpc-ids.txt exists
if [ ! -f "vpc-ids.txt" ]; then
    echo -e "${RED}Error: vpc-ids.txt not found${NC}"
    echo "Please run ./create-vpcs.sh first"
    exit 1
fi

# Load VPC IDs
source vpc-ids.txt

# Configuration
EAST_REGION="us-east-1"
WEST_REGION="us-west-2"
EAST_VPC_CIDR="10.0.0.0/16"
WEST_VPC_CIDR="192.168.0.0/16"

echo -e "${YELLOW}Step 1: Creating VPC Peering Connection${NC}"
echo "=================================================="

# Create peering connection
echo "Initiating peering request from us-east-1 to us-west-2..."
PEERING_ID=$(aws ec2 create-vpc-peering-connection \
    --vpc-id $EAST_VPC_ID \
    --peer-vpc-id $WEST_VPC_ID \
    --peer-region $WEST_REGION \
    --region $EAST_REGION \
    --tag-specifications "ResourceType=vpc-peering-connection,Tags=[{Key=Name,Value=excipient-peering-east-west},{Key=Environment,Value=Production}]" \
    --query 'VpcPeeringConnection.VpcPeeringConnectionId' \
    --output text)

if [ -z "$PEERING_ID" ]; then
    echo -e "${RED}Failed to create peering connection${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Peering connection created: $PEERING_ID${NC}"

# Wait a moment for the peering connection to be ready
echo "Waiting for peering connection to be ready..."
sleep 5

echo ""
echo -e "${YELLOW}Step 2: Accepting Peering Connection${NC}"
echo "=================================================="

# Accept peering connection
aws ec2 accept-vpc-peering-connection \
    --vpc-peering-connection-id $PEERING_ID \
    --region $WEST_REGION > /dev/null

echo -e "${GREEN}✓ Peering connection accepted${NC}"

# Wait for peering connection to become active
echo "Waiting for peering connection to become active..."
aws ec2 wait vpc-peering-connection-exists \
    --vpc-peering-connection-ids $PEERING_ID \
    --region $EAST_REGION

sleep 3

# Check status
STATUS=$(aws ec2 describe-vpc-peering-connections \
    --vpc-peering-connection-ids $PEERING_ID \
    --region $EAST_REGION \
    --query 'VpcPeeringConnections[0].Status.Code' \
    --output text)

echo -e "${GREEN}✓ Peering connection status: $STATUS${NC}"

echo ""
echo -e "${YELLOW}Step 3: Updating Route Tables${NC}"
echo "=================================================="

# Add route to West VPC in East route table
echo "Adding route to West VPC in East route table..."
aws ec2 create-route \
    --route-table-id $EAST_RTB_ID \
    --destination-cidr-block $WEST_VPC_CIDR \
    --vpc-peering-connection-id $PEERING_ID \
    --region $EAST_REGION > /dev/null

echo -e "${GREEN}✓ Route added in us-east-1 route table${NC}"

# Add route to East VPC in West route table
echo "Adding route to East VPC in West route table..."
aws ec2 create-route \
    --route-table-id $WEST_RTB_ID \
    --destination-cidr-block $EAST_VPC_CIDR \
    --vpc-peering-connection-id $PEERING_ID \
    --region $WEST_REGION > /dev/null

echo -e "${GREEN}✓ Route added in us-west-2 route table${NC}"

echo ""
echo -e "${YELLOW}Step 4: Verifying Configuration${NC}"
echo "=================================================="

# Display East route table
echo "US-EAST-1 Route Table:"
aws ec2 describe-route-tables \
    --route-table-ids $EAST_RTB_ID \
    --region $EAST_REGION \
    --query 'RouteTables[0].Routes[].[DestinationCidrBlock,GatewayId,VpcPeeringConnectionId,State]' \
    --output table

echo ""
echo "US-WEST-2 Route Table:"
aws ec2 describe-route-tables \
    --route-table-ids $WEST_RTB_ID \
    --region $WEST_REGION \
    --query 'RouteTables[0].Routes[].[DestinationCidrBlock,GatewayId,VpcPeeringConnectionId,State]' \
    --output table

# Save peering ID
echo "PEERING_ID=$PEERING_ID" >> vpc-ids.txt

echo ""
echo -e "${GREEN}=================================================="
echo "VPC Peering Setup Complete!"
echo "==================================================${NC}"
echo ""
echo -e "${YELLOW}Peering Connection Details:${NC}"
echo "  Connection ID: $PEERING_ID"
echo "  Status: $STATUS"
echo "  Requester VPC: $EAST_VPC_ID ($EAST_VPC_CIDR)"
echo "  Accepter VPC:  $WEST_VPC_ID ($WEST_VPC_CIDR)"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Launch EC2 instances in both VPCs"
echo "2. Test connectivity using ping"
echo "3. Enable VPC Flow Logs (optional)"
echo "4. Document results and take screenshots"
echo ""
echo -e "${YELLOW}To launch EC2 instances, use:${NC}"
echo "  ./launch-instances.sh"
echo ""

