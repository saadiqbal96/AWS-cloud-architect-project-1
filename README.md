# AWS Solutions Architect Project
## Excipient Technologies - Multi-Account Architecture Design

This project demonstrates the design and implementation of a centralized AWS infrastructure for Excipient Technologies, integrating standalone accounts and acquired businesses into a unified Control Tower setup.

## Project Overview

**Company:** Excipient Technologies  
**Project:** Centralized AWS Network Architecture  
**Objective:** Integrate standalone AWS accounts and acquired business networks into existing Control Tower setup

## Project Structure

```
Project: Migrating a Credit Card Fraud Pipeline to AWS/
├── README.md                          # This file
├── PROJECT_REPORT.md                  # Main comprehensive project report
├── IMPLEMENTATION_GUIDE.md            # Step-by-step implementation guide
├── policies/                          # SCP and Config rule JSON files
│   ├── scp-require-tags-ec2.json
│   ├── scp-require-tags-s3.json
│   ├── scp-require-tags-rds.json
│   ├── config-rule-required-tags-ec2.json
│   ├── config-rule-required-tags-s3.json
│   └── config-rule-required-tags-rds.json
├── budgets/                           # AWS Budget configurations
│   ├── master-budget.json
│   ├── production-budget.json
│   └── development-budget.json
├── scripts/                           # Automation scripts
│   ├── create-vpcs.sh                # Create VPCs in both regions
│   ├── setup-peering.sh              # Setup VPC peering
│   ├── launch-instances.sh           # Launch EC2 instances (auto key pairs)
│   ├── enable-flow-logs.sh           # Enable VPC Flow Logs
│   ├── cleanup-resources.sh          # Clean up all resources
│   └── lambda/
│       ├── budget-action-stop-dev.py
│       └── budget-action-slack.py
└── diagrams/                          # Architecture diagrams
    └── README.md                      # Diagram specifications
```

## Four Main Tasks

### Step 1: Multi-Account AWS Architecture Design ✅
**Status:** Documentation Complete  
**Location:** `PROJECT_REPORT.md` - Section 1  
**Deliverables:**
- OU hierarchy design
- Integration strategy for standalone accounts
- Integration strategy for acquired organizations
- Governance and security policies (SCPs)
- Architecture diagrams specifications

### Step 2: Establish Network Connectivity 🚧
**Status:** Implementation Guide Ready  
**Location:** `PROJECT_REPORT.md` - Section 2  
**Deliverables:**
- VPC creation in two regions (us-east-1, us-west-2)
- VPC peering configuration
- Route table updates
- Security group configuration
- EC2 instance deployment and testing
- VPC Flow Logs analysis
- **Screenshots required**

### Step 3: Implement Governance with Tagging Strategies ✅
**Status:** Documentation and JSON Files Complete  
**Location:** `PROJECT_REPORT.md` - Section 3 + `policies/` directory  
**Deliverables:**
- Tagging strategy table
- SCP JSON files for tag enforcement
- AWS Config rule JSON files
- Enforcement and compliance plan

### Step 4: Configure Cost Management Controls ✅
**Status:** Documentation and Budget Configurations Complete  
**Location:** `PROJECT_REPORT.md` - Section 4 + `budgets/` directory  
**Deliverables:**
- Budget hierarchy design
- Budget configuration JSON files
- Budget actions and thresholds
- Notification configurations

## Quick Start

### For Documentation Tasks (Steps 1, 3, 4)

1. **Review the Main Report:**
   ```bash
   open PROJECT_REPORT.md
   ```

2. **Review JSON Policy Files:**
   ```bash
   # View SCPs
   cat policies/scp-require-tags-ec2.json
   
   # View Config rules
   cat policies/config-rule-required-tags-ec2.json
   
   # View Budget configurations
   cat budgets/master-budget.json
   ```

3. **Create Architecture Diagrams:**
   - Use Lucidchart, Draw.io, or similar tool
   - Follow specifications in `diagrams/README.md`
   - Export as PNG/PDF for submission

### For Hands-On AWS Task (Step 2)

1. **Access AWS Console:**
   - Log into your temporary AWS account
   - Select regions: us-east-1 and us-west-2

2. **Create VPCs:**
   ```bash
   cd scripts
   chmod +x *.sh
   ./create-vpcs.sh
   ```

3. **Setup VPC Peering:**
   ```bash
   ./setup-peering.sh
   ```

4. **Launch EC2 Instances:**
   ```bash
   ./launch-instances.sh
   ```
   (Automatically creates SSH key pairs and launches instances)

5. **Test Connectivity:**
   ```bash
   source instance-ids.txt
   ssh -i ~/.ssh/excipient-keypair-east.pem ec2-user@$EAST_PUBLIC_IP
   # Then: ping -c 4 $WEST_PRIVATE_IP
   ```
   Repeat for West → East. Capture screenshots!

6. **Enable VPC Flow Logs:**
   ```bash
   ./enable-flow-logs.sh
   ```
   Wait 10 minutes, then view in CloudWatch console.

7. **Cleanup Resources (IMPORTANT):**
   ```bash
   ./cleanup-resources.sh
   ```

## AWS Services Used

### Core Services
- **AWS Organizations** - Multi-account management
- **AWS Control Tower** - Governance and compliance
- **AWS VPC** - Network isolation
- **Amazon EC2** - Compute resources
- **VPC Peering** - Cross-region connectivity

### Security & Compliance
- **AWS IAM** - Identity and access management
- **AWS Config** - Resource compliance tracking
- **Service Control Policies (SCPs)** - Organizational policies
- **AWS Security Hub** - Centralized security findings
- **VPC Flow Logs** - Network traffic monitoring

### Cost Management
- **AWS Budgets** - Cost tracking and alerts
- **AWS Cost Explorer** - Cost analysis
- **Cost Allocation Tags** - Resource cost attribution

### Monitoring & Logging
- **AWS CloudTrail** - API activity logging
- **Amazon CloudWatch** - Metrics and logs
- **CloudWatch Logs Insights** - Log analysis

## Key Concepts Demonstrated

### 1. Multi-Account Strategy
- Organizational Unit (OU) hierarchy design
- Account isolation and security boundaries
- Centralized logging and auditing
- Cross-account access management

### 2. Network Architecture
- VPC design with non-overlapping CIDR blocks
- Cross-region VPC peering
- Route table configuration
- Security group and NACL management

### 3. Governance Framework
- Tagging strategy for resource management
- Preventive controls with SCPs
- Detective controls with AWS Config
- Compliance monitoring and reporting

### 4. Cost Optimization
- Budget hierarchies and thresholds
- Automated budget actions
- Cost allocation and chargeback
- Forecasting and trend analysis

## Project Rubric Alignment

### ✅ Multi-Account AWS Architecture Design
- [x] Clearly defined OU hierarchy
- [x] Integration steps documented
- [x] Governance policies (SCPs) defined
- [x] Visual architecture diagram specifications

### 🚧 Establish Network Connectivity
- [ ] VPC peering connections created
- [ ] Route tables and security groups configured
- [ ] Traffic flow verified with ping/logs
- [ ] Screenshots captured

### ✅ Implement Governance with Tagging Strategies
- [x] Tagging strategy table defined
- [x] SCPs in JSON format
- [x] AWS Config rules in JSON format

### ✅ Configure Cost Management Controls
- [x] Budget configurations with thresholds
- [x] Budget Actions defined
- [x] Notification settings configured

## Cost Considerations

### Free Tier Resources Used
- **EC2:** t2.micro instances (750 hours/month free)
- **VPC:** VPC creation is free
- **VPC Peering:** Data transfer charges apply
- **CloudWatch:** 5GB logs ingestion free
- **AWS Config:** First 100,000 evaluations free

### Estimated Costs for Step 2
- EC2 instances (2x t2.micro): ~$0.0116/hour = ~$0.28/day
- VPC Peering data transfer: ~$0.01/GB
- VPC Flow Logs storage: ~$0.50/GB/month
- **Total for 24 hours:** ~$1-2

### Cost Optimization Tips
1. Use t2.micro or t3.micro instances (Free Tier eligible)
2. Terminate resources immediately after testing
3. Use provided cleanup script
4. Enable billing alerts
5. Monitor AWS Budgets dashboard

## Prerequisites

### Knowledge Requirements
- AWS fundamentals (VPC, EC2, IAM)
- Networking concepts (CIDR, routing, security groups)
- JSON syntax
- Basic Linux/SSH commands

### Tools Required
- **AWS Account** with appropriate permissions
- **AWS CLI** configured (optional but recommended)
- **SSH client** for EC2 access
- **Diagramming tool** (Lucidchart, Draw.io, etc.)
- **Text editor** for viewing JSON files

### AWS CLI Installation
```bash
# macOS (using Homebrew)
brew install awscli

# Verify installation
aws --version

# Configure AWS CLI
aws configure
```

## Security Best Practices

1. **Never commit AWS credentials** to version control
2. **Use IAM roles** instead of access keys when possible
3. **Enable MFA** for root and IAM users
4. **Follow principle of least privilege**
5. **Enable CloudTrail** in all accounts
6. **Encrypt data** at rest and in transit
7. **Regular security audits** with AWS Config
8. **Monitor with GuardDuty** for threat detection

## Troubleshooting

### VPC Peering Issues
**Problem:** Ping fails between instances
**Solutions:**
- Verify peering connection is "Active"
- Check route tables have correct CIDR routes
- Ensure security groups allow ICMP
- Verify NACLs aren't blocking traffic
- Check VPC Flow Logs for REJECT entries

### Budget Alert Issues
**Problem:** Not receiving budget notifications
**Solutions:**
- Verify email addresses are correct
- Check spam folder
- Confirm SNS topic subscriptions
- Test with lower threshold values

### SCP Enforcement Issues
**Problem:** SCP not preventing resource creation
**Solutions:**
- Verify SCP is attached to correct OU
- Check SCP is not being overridden
- Ensure account is in correct OU
- Test with CLI/SDK to see detailed error

## Additional Resources

### AWS Documentation
- [AWS Control Tower User Guide](https://docs.aws.amazon.com/controltower/)
- [VPC Peering Guide](https://docs.aws.amazon.com/vpc/latest/peering/)
- [AWS Budgets User Guide](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html)
- [AWS Config Developer Guide](https://docs.aws.amazon.com/config/)

### AWS Whitepapers
- AWS Well-Architected Framework
- Organizing Your AWS Environment Using Multiple Accounts
- AWS Security Best Practices

### Training
- AWS Certified Solutions Architect - Associate
- AWS Control Tower Workshop
- AWS Networking Fundamentals

## Submission Checklist

Before submitting your project, ensure you have:

### Documentation
- [ ] Completed PROJECT_REPORT.md with all sections
- [ ] Created architecture diagrams (OU hierarchy, network topology, integration flow)
- [ ] All JSON files present in policies/ and budgets/ directories
- [ ] README.md reviewed and updated if necessary

### Step 2: Network Connectivity Screenshots
- [ ] VPC 1 details (us-east-1 with CIDR 10.0.0.0/16)
- [ ] VPC 2 details (us-west-2 with CIDR 192.168.0.0/16)
- [ ] VPC Peering connection showing "Active" status
- [ ] Route tables for both VPCs
- [ ] Security group rules for both instances
- [ ] EC2 instance details for both regions
- [ ] Terminal showing successful ping from east to west
- [ ] Terminal showing successful ping from west to east
- [ ] VPC Flow Logs showing ACCEPT traffic
- [ ] CloudWatch Logs query results

### AWS Resources
- [ ] All resources cleaned up (to avoid charges)
- [ ] Final billing check performed
- [ ] Cost analysis documented

### Review Against Rubric
- [ ] Multi-Account Architecture Design criteria met
- [ ] Network Connectivity criteria met
- [ ] Governance with Tagging criteria met
- [ ] Cost Management Controls criteria met

## Support

For questions or issues:
1. Review the PROJECT_REPORT.md thoroughly
2. Check AWS documentation links
3. Consult the troubleshooting section
4. Review Udacity project guidelines
5. Ask in Udacity student forums

## License

This project is created for educational purposes as part of the Udacity AWS Solutions Architect Nanodegree program.

## Author

**Student:** [Your Name]  
**Program:** Udacity AWS Solutions Architect Nanodegree  
**Project:** Design and Architect Infrastructure for an Organization  
**Date:** October 2025

---

**Note:** Remember to delete all AWS resources after completing the project to avoid unnecessary charges!

Good luck with your project! 🚀

