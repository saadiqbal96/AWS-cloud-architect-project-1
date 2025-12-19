AWS Multi-Account Cloud Architecture Project
============================================

**Author:** **Saad Iqbal** **Role:** Cloud / Solutions Architect**Project Type:** Hands-on AWS Architecture & Governance Implementation**Last Updated:** December 2025

📌 Project Overview
-------------------

This project demonstrates the design and implementation of a **secure, governed, multi-account AWS architecture** using AWS Organizations, VPC networking, Service Control Policies (SCPs), AWS Config, and AWS Budgets.

The solution is designed for a fictional enterprise, **Excipient Technologies**, and aligns with AWS best practices for:

*   Multi-account governance
    
*   Network isolation and connectivity
    
*   Cost management
    
*   Compliance enforcement
    
*   Operational automation
    

This repository includes **architecture documentation**, **automation scripts**, **policy definitions**, **budget controls**, and **evidence artifacts** required to satisfy the project rubric.

🏗️ Architecture Summary
------------------------

The architecture is built using **AWS Organizations** with a structured **Organizational Unit (OU) hierarchy**:

### Organizational Units

*   **Root**
    
    *   **Corporate OU**
        
        *   Shared services (billing, security, logging)
            
    *   **Workloads OU**
        
        *   Production and development workloads
            
    *   **Acquired Businesses OU**
        
        *   Integrated external AWS accounts
            

### Key Design Principles

*   Strong account isolation
    
*   Centralized governance and security controls
    
*   Least-privilege enforcement using SCPs
    
*   Automated compliance monitoring
    
*   Cost visibility and enforcement
    

Architecture diagrams are provided in the diagrams/ directory and reflect the documented OU hierarchy and account relationships.

🌐 Network Connectivity
-----------------------

The project establishes **cross-region VPC connectivity** using **VPC Peering**.

### Networking Details

*   Region 1: us-east-1
    
*   Region 2: us-west-2
    
*   One VPC per region
    
*   Bidirectional VPC peering
    
*   Updated route tables for inter-VPC traffic
    
*   Security groups and NACLs configured to allow ICMP and SSH
    
*   Optional VPC Flow Logs enabled for traffic verification
    

Connectivity is validated using:

*   EC2-to-EC2 ping
    
*   SSH access
    
*   VPC Flow Log ACCEPT entries
    

🧩 Governance & Compliance
--------------------------

### Tagging Strategy

A standardized tagging strategy is enforced across all accounts and resources.

Tag KeyPurposeEnvironmentIdentifies environment (Dev, Prod)CostCenterEnables cost allocationOwnerIdentifies resource ownerProjectAssociates resources to project

### Enforcement Mechanisms

*   **Service Control Policies (SCPs)**
    
    *   Deny resource creation if required tags are missing
        
*   **AWS Config Rules**
    
    *   Detect and flag non-compliant resources
        

All SCPs and Config rules are provided in **JSON format** inside the policies/ directory.

💰 Cost Management
------------------

Cost governance is implemented using **AWS Budgets and Budget Actions**.

### Budget Features

*   Separate budgets for:
    
    *   Master account
        
    *   Production workloads
        
    *   Development workloads
        
*   Threshold-based alerts
    
*   Automated actions:
    
    *   Slack notifications
        
    *   Automatic EC2 stop actions for development resources
        

Budget definitions and actions are stored in the budgets/ directory.

⚙️ Automation & Scripts
-----------------------

All infrastructure provisioning and teardown is automated using Bash scripts located in the scripts/ directory.

### Available Scripts

*   create-vpcs.sh – Creates VPCs and networking resources
    
*   setup-peering.sh – Establishes VPC peering and routing
    
*   launch-instances.sh – Launches EC2 instances for testing
    
*   cleanup-resources.sh – Deletes all created resources
    

Scripts are:

*   Idempotent where possible
    
*   Designed for AWS CLI usage
    
*   Logged and output-driven
    
*   Safe to clean up after testing
    

A detailed script walkthrough is available in scripts/README.md.

🧠 Lambda Functions
-------------------

The lambda/ directory contains AWS Lambda functions used by Budget Actions:

*   budget-action-stop-dev.pyAutomatically stops development EC2 instances when budget thresholds are exceeded.
    
*   budget-action-slack.pySends Slack notifications when budgets reach defined limits.
    

These functions support cost enforcement but are not directly executed by scripts.

📁 Repository Structure
-----------------------

`   .  ├── budgets/          # AWS Budget and Budget Action JSON files  ├── diagrams/         # Architecture diagrams  ├── lambda/           # Lambda functions for budget actions  ├── policies/         # SCPs and AWS Config rule definitions  ├── scripts/          # Automation scripts for AWS resources  ├── screenshots/      # Evidence screenshots for rubric validation  ├── PROJECT_REPORT.md # Detailed written report  └── README.md         # Project overview (this file)   `

📸 Evidence & Validation
------------------------

The screenshots/ directory contains evidence required by the rubric, including:

*   VPC configuration
    
*   Active VPC peering status
    
*   Route tables and security groups
    
*   EC2 instance details
    
*   Successful ping tests
    
*   VPC Flow Logs showing ACCEPT traffic
    
*   AWS Budgets and alerts
    

🔐 Security Considerations
--------------------------

*   Least-privilege IAM assumed for all automation
    
*   SCPs prevent non-compliant resource creation
    
*   Network access restricted to required ports only
    
*   SSH access controlled via key pairs
    
*   Logging enabled for visibility and auditing
    

🧪 Cost Awareness
-----------------

Estimated cost for testing:

*   ~$1–2 per day (short-lived testing)
    
*   Cleanup script removes all billable resources
    
*   Budgets and alerts prevent uncontrolled spend
    

🧾 Rubric Alignment Summary
---------------------------

Rubric RequirementStatusMulti-account AWS architecture✅ CompleteOU hierarchy & onboarding✅ CompleteNetwork connectivity & verification✅ CompleteGovernance via SCPs & Config✅ CompleteTagging strategy enforcement✅ CompleteCost management & budgets✅ CompleteAutomation & documentation✅ Complete

🧑‍💻 Author
------------

**Saad Iqbal**Cloud & Solutions ArchitectureGitHub: saadiqbal96
