# Scripts Directory

This directory contains automation scripts for the Excipient Technologies AWS project.

## Available Scripts

### 1. create-vpcs.sh
**Purpose:** Creates VPCs, subnets, internet gateways, route tables, and security groups in both us-east-1 and us-west-2 regions.

**Usage:**
```bash
./create-vpcs.sh
```

**Output:** Creates `vpc-ids.txt` with all VPC resource IDs.

**Prerequisites:**
- AWS CLI configured with valid credentials
- Permissions to create VPC resources

---

### 2. setup-peering.sh
**Purpose:** Establishes VPC peering connection between us-east-1 and us-west-2 VPCs.

**Usage:**
```bash
./setup-peering.sh
```

**Prerequisites:**
- `create-vpcs.sh` must be run first
- `vpc-ids.txt` must exist

**Output:** Updates `vpc-ids.txt` with peering connection ID and configures route tables.

---

### 3. launch-instances.sh (NEW)
**Purpose:** Launches EC2 instances in both VPCs for connectivity testing. Automatically discovers the latest Amazon Linux 2 AMI in each region and creates SSH key pairs if needed.

**Usage:**
```bash
./launch-instances.sh                              # Uses default key pairs (auto-created)
./launch-instances.sh <key-name-east> <key-name-west>  # Uses custom key pairs
```

**Example:**
```bash
# Easiest way - let the script handle everything
./launch-instances.sh

# Or use custom key pair names
./launch-instances.sh my-keypair-east my-keypair-west
```

**Prerequisites:**
- `create-vpcs.sh` must be run first
- `vpc-ids.txt` must exist

**Output:** 
- Creates `instance-ids.txt` with instance details
- Displays SSH connection commands
- Provides connectivity testing instructions

**Features:**
- ✅ Automatic SSH key pair creation (if not exists)
- ✅ Automatic AMI discovery (latest Amazon Linux 2)
- ✅ Launches t2.micro instances (free tier eligible)
- ✅ Waits for instances to be running
- ✅ Retrieves public and private IPs
- ✅ Applies consistent tagging
- ✅ Provides ready-to-use SSH commands

**What It Does:**
1. Creates or verifies SSH key pairs in both regions
2. Discovers latest Amazon Linux 2 AMI in us-east-1
3. Discovers latest Amazon Linux 2 AMI in us-west-2
4. Launches instance in us-east-1
5. Launches instance in us-west-2
6. Waits for both instances to be running
7. Retrieves instance details (IDs, IPs)
8. Saves information to `instance-ids.txt`
9. Displays SSH connection commands and testing instructions

---

### 4. cleanup-resources.sh
**Purpose:** Deletes all AWS resources created by the above scripts.

**Usage:**
```bash
./cleanup-resources.sh
```

**⚠️ WARNING:** This script will DELETE all resources. Make sure you have captured all required screenshots before running!

**What It Deletes:**
- EC2 instances (both regions)
- VPC peering connection
- Security groups
- Subnets
- Route tables
- Internet gateways
- VPCs
- VPC Flow Logs (if enabled)
- Local configuration files (`vpc-ids.txt`, `instance-ids.txt`)

**Prerequisites:**
- `vpc-ids.txt` must exist

---

## Complete Workflow

Follow this sequence to set up and test the infrastructure:

### Step 1: Create VPCs
```bash
cd scripts
chmod +x *.sh
./create-vpcs.sh
```

**Output:** `vpc-ids.txt` created

### Step 2: Setup VPC Peering
```bash
./setup-peering.sh
```

**Output:** `vpc-ids.txt` updated with peering connection ID

### Step 3: Launch EC2 Instances
```bash
./launch-instances.sh
```

**Output:** 
- SSH key pairs created (saved to `~/.ssh/`)
- `instance-ids.txt` created with instance details

### Step 4: Test Connectivity

**SSH to East Instance:**
```bash
ssh -i ~/.ssh/your-key-east.pem ec2-user@<EAST_PUBLIC_IP>
```

**Ping West Private IP:**
```bash
ping -c 4 <WEST_PRIVATE_IP>
```

**SSH to West Instance:**
```bash
ssh -i ~/.ssh/your-key-west.pem ec2-user@<WEST_PUBLIC_IP>
```

**Ping East Private IP:**
```bash
ping -c 4 <EAST_PRIVATE_IP>
```

### Step 5: Capture Screenshots

Capture screenshots for:
- VPC details (both regions)
- Peering connection (active status)
- Route tables (both regions)
- Security groups (both regions)
- EC2 instance details
- Successful ping tests (both directions)
- VPC Flow Logs (if enabled)

### Step 6: Cleanup
```bash
./cleanup-resources.sh
```

Type `yes` when prompted to confirm deletion.

---

## Key Pair Management

The `launch-instances.sh` script automatically creates SSH key pairs for you! 

**Default behavior:**
- Creates `excipient-keypair-east` in us-east-1
- Creates `excipient-keypair-west` in us-west-2
- Saves private keys to `~/.ssh/` with 400 permissions
- If key pairs already exist, it uses them

**Custom key pairs (optional):**
If you prefer to use your own key pair names:
```bash
./launch-instances.sh my-custom-key-east my-custom-key-west
```

**Manual creation (if needed):**
If you prefer to create key pairs manually before running the script:
```bash
aws ec2 create-key-pair \
    --key-name my-keypair-east \
    --region us-east-1 \
    --query 'KeyMaterial' \
    --output text > ~/.ssh/my-keypair-east.pem

chmod 400 ~/.ssh/my-keypair-east.pem
```

---

## Troubleshooting

### Script Permission Denied
```bash
chmod +x scripts/*.sh
```

### vpc-ids.txt Not Found
Make sure to run `create-vpcs.sh` first before running other scripts.

### Instance Launch Fails
- Check AWS quotas for EC2 instances
- Verify key pair exists in the correct region
- Ensure VPC resources exist

### AMI Discovery Fails
- Check AWS CLI configuration
- Verify internet connectivity
- Ensure AWS credentials have EC2 read permissions

### SSH Connection Fails
- Verify security group allows SSH from your IP
- Check that public IP is assigned
- Confirm key pair name matches
- Ensure key file has correct permissions (400)

---

## Lambda Functions

The `lambda/` directory contains AWS Lambda functions for budget actions:

### budget-action-stop-dev.py
Automatically stops development EC2 instances when budget threshold is exceeded.

### budget-action-slack.py
Sends Slack notifications when budget thresholds are reached.

These are referenced in the budget configurations but are not directly executed by the scripts.

---

## Cost Considerations

### Estimated Costs for Testing (24 hours):
- 2x t2.micro EC2 instances: ~$0.28/day
- VPC Peering data transfer: ~$0.01/GB
- VPC Flow Logs (if enabled): ~$0.50/GB
- **Total: ~$1-2 per day**

### Cost Optimization Tips:
1. Use t2.micro instances (free tier eligible)
2. Run cleanup script immediately after testing
3. Disable VPC Flow Logs if not needed
4. Set up budget alerts

---

## Support

For issues or questions:
1. Review the troubleshooting section
2. Check AWS CloudTrail for API errors
3. Review script output for specific error messages
4. Consult AWS documentation for service-specific issues

---

## Notes

- All scripts use `set -e` to exit on first error
- Scripts provide colored output for better readability
- Resource IDs are saved to text files for reuse
- Cleanup script requires confirmation before deletion
- Scripts are designed to be idempotent where possible

---

**Last Updated:** October 2025

