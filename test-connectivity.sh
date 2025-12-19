#!/bin/bash
source instance-ids.txt

echo "=================================================="
echo "Testing Cross-Region VPC Connectivity"
echo "=================================================="
echo ""

echo "Test 1: East (10.0.1.210) → West (192.168.1.216)"
echo "--------------------------------------------------"
ssh -i ~/.ssh/${EAST_KEY_NAME}.pem -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
    ec2-user@${EAST_PUBLIC_IP} "ping -c 4 ${WEST_PRIVATE_IP}"

echo ""
echo "Test 2: West (192.168.1.216) → East (10.0.1.210)"
echo "--------------------------------------------------"
ssh -i ~/.ssh/${WEST_KEY_NAME}.pem -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
    ec2-user@${WEST_PUBLIC_IP} "ping -c 4 ${EAST_PRIVATE_IP}"

echo ""
echo "=================================================="
echo "Connectivity Test Complete!"
echo "=================================================="
