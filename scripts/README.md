Scripts Directory
=================

**Project**: Excipient Technologies – Multi-Account AWS Architecture**Author:** **Saad Iqbal** **Last Updated:** October 2025

This directory contains automation scripts for provisioning, testing, and cleaning up AWS infrastructure used in the Excipient Technologies multi-account AWS architecture project.

Available Scripts
-----------------

### 1\. create-vpcs.sh

**Purpose**:Creates VPCs, subnets, internet gateways, route tables, and security groups in both us-east-1 and us-west-2 regions.

**Usage**:

`  ./create-vpcs.sh   `

**Output:**

*   Creates vpc-ids.txt containing all VPC and networking resource IDs.
    

**Prerequisites:**

*   AWS CLI configured with valid credentials
    
*   IAM permissions to create VPC and networking resources
    

### 2\. setup-peering.sh

**Purpose**: Establishes a VPC peering connection between the us-east-1 and us-west-2 VPCs and updates route tables for inter-VPC communication.

**Usage:**

`   ./setup-peering.sh   `

**Prerequisites:**

*   create-vpcs.sh must be run first
    
*   vpc-ids.txt must exist
    

**Output:**

*   Updates vpc-ids.txt with the VPC peering connection ID
    
*   Configures route tables in both regions
    

### 3\. launch-instances.sh

**Purpose**:Launches EC2 instances in both VPCs for connectivity testing. Automatically discovers the latest Amazon Linux 2 AMI in each region and creates SSH key pairs if needed.

**Usage:**

`./launch-instances.sh  ./launch-instances.sh`  

**Examples:**

`   # Automatic key pair creation  ./launch-instances.sh  # Custom key pair names  ./launch-instances.sh my-keypair-east my-keypair-west   `

**Prerequisites:**

*   create-vpcs.sh must be run first
    
*   vpc-ids.txt must exist
    

**Output:**

*   Creates instance-ids.txt with instance IDs and IP addresses
    
*   Displays SSH commands for direct access
    
*   Provides connectivity testing instructions
    

**Features:**

*   ✅ Automatic SSH key pair creation (if not present)
    
*   ✅ Automatic AMI discovery (Amazon Linux 2)
    
*   ✅ Uses t2.micro (Free Tier eligible)
    
*   ✅ Waits for instances to reach running state
    
*   ✅ Retrieves public and private IPs
    
*   ✅ Applies consistent resource tagging
    
*   ✅ Outputs ready-to-use SSH commands
    

**Execution Flow:**

1.  Create or validate SSH key pairs in both regions
    
2.  Discover latest Amazon Linux 2 AMI in us-east-1
    
3.  Discover latest Amazon Linux 2 AMI in us-west-2
    
4.  Launch EC2 instance in each VPC
    
5.  Wait for instances to be running
    
6.  Capture instance metadata (IDs and IPs)
    
7.  Save results to instance-ids.txt
    
8.  Display SSH and ping test instructions
    

### 4\. cleanup-resources.sh

**Purpose:**Deletes all AWS resources created by the project scripts.

**Usage:**

`   ./cleanup-resources.sh   `

⚠️ **WARNING**: This script permanently deletes AWS resources. Ensure all required screenshots and logs have been captured before running.

**Resources Deleted:**

*   EC2 instances (both regions)
    
*   VPC peering connection
    
*   Security groups
    
*   Subnets
    
*   Route tables
    
*   Internet gateways
    
*   VPCs
    
*   VPC Flow Logs (if enabled)
    
*   Local files (vpc-ids.txt, instance-ids.txt)
    

**Prerequisites:**

*   vpc-ids.txt must exist
    

Complete Workflow
-----------------

### Step 1: Create VPCs

`   cd scripts  chmod +x *.sh  ./create-vpcs.sh   `

### Step 2: Set Up VPC Peering

`   ./setup-peering.sh   `

### Step 3: Launch EC2 Instances

`   ./launch-instances.sh   `

### Step 4: Test Connectivity

**SSH to East Region Instance**

`   ssh -i ~/.ssh/your-key-east.pem ec2-user@   `

**Ping West Private IP**

`ping -c 4` 

**SSH to West Region Instance**

`   ssh -i ~/.ssh/your-key-west.pem ec2-user@   `

**Ping East Private IP**

`ping -c 4` 

Screenshot Evidence (Rubric Requirement)
----------------------------------------

Capture screenshots for:

*   VPC details (both regions)
    
*   Active VPC peering connection
    
*   Route tables (both regions)
    
*   Security groups
    
*   EC2 instance details
    
*   Successful bidirectional ping tests
    
*   VPC Flow Logs showing ACCEPT traffic
    

Key Pair Management
-------------------

**Default behavior:**

*   Creates excipient-keypair-east in us-east-1
    
*   Creates excipient-keypair-west in us-west-2
    
*   Saves keys to ~/.ssh/ with 400 permissions
    
*   Reuses existing key pairs if present
    

**Custom key pairs:**

`   ./launch-instances.sh my-custom-key-east my-custom-key-west   `

Lambda Functions
----------------

The lambda/ directory contains AWS Lambda functions used for budget enforcement:

*   budget-action-stop-dev.py – Stops development EC2 instances when budget thresholds are exceeded
    
*   budget-action-slack.py – Sends Slack notifications when budgets reach defined limits
    

These functions are referenced by AWS Budget Actions but are not executed directly by the scripts.

Cost Considerations
-------------------

**Estimated 24-Hour Testing Cost:**

*   2 × t2.micro EC2 instances: ~$0.28
    
*   VPC peering data transfer: ~$0.01/GB
    
*   VPC Flow Logs (if enabled): ~$0.50/GB
    
*   **Estimated total:** ~$1–2 per day
    

**Cost Optimization Tips:**

1.  Use Free Tier–eligible instances
    
2.  Run cleanup script immediately after testing
    
3.  Disable VPC Flow Logs when not required
    
4.  Configure AWS Budgets and alerts
    

Notes
-----

*   Scripts use set -e to exit on first error
    
*   Colored output improves readability
    
*   Resource IDs are persisted for reuse
    
*   Cleanup requires explicit confirmation
    
*   Scripts are designed to be idempotent where possible
