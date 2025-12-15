# Networks - VPC and Network Infrastructure Guide

## 📋 Table of Contents
- [Overview](#overview)
- [What is a VPC?](#what-is-a-vpc)
- [What Gets Created](#what-gets-created)
- [Network Architecture](#network-architecture)
- [Prerequisites](#prerequisites)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [Configuration Files Explained](#configuration-files-explained)
- [Customization Guide](#customization-guide)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Important Notes](#important-notes)

---

## 🎯 Overview

The **networks** folder creates your **Virtual Private Cloud (VPC)** - an isolated network in AWS where all your other resources (EC2, EKS, RDS) will live.

**Think of it as building the roads, neighborhoods, and security gates for your cloud city.**

---

## 🔍 What is a VPC?

### For Beginners:

**VPC (Virtual Private Cloud)** = Your own private network in AWS

**Analogy:**
- **Physical World**: Your office building with separate floors
  - Public floors (lobby) - anyone can access
  - Private floors (offices) - only employees can access
  - Security gates - control who enters

- **AWS VPC**: Your cloud network with separate subnets
  - Public subnets - accessible from internet
  - Private subnets - only internal access
  - Security groups - firewall rules

### Key Network Components:

1. **VPC** - The entire network (like the building)
2. **Subnets** - Subdivisions of the network (like floors)
3. **Internet Gateway** - Door to the internet
4. **NAT Gateway** - Allows private resources to access internet
5. **Route Tables** - Traffic directions (like road signs)
6. **Security Groups** - Firewall rules (like security checkpoints)

---

## 📦 What Gets Created

### Development Environment (dev)

#### 1. VPC
```
Name: sd5046-aws-infrastructure-network-dev
CIDR: 10.0.0.0/16
Total IPs: 65,536 addresses
```

#### 2. Public Subnets (3)
```
Subnet 0: 10.0.0.0/20   (4,096 IPs) - AZ: ap-southeast-1a
Subnet 1: 10.0.16.0/20  (4,096 IPs) - AZ: ap-southeast-1b
Subnet 2: 10.0.32.0/20  (4,096 IPs) - AZ: ap-southeast-1c

Purpose: Resources with public internet access
Usage: Bastion hosts, Load balancers, NAT Gateway
```

#### 3. Private Subnets (3)
```
Subnet 0: 10.0.48.0/20  (4,096 IPs) - AZ: ap-southeast-1a
Subnet 1: 10.0.64.0/20  (4,096 IPs) - AZ: ap-southeast-1b
Subnet 2: 10.0.80.0/20  (4,096 IPs) - AZ: ap-southeast-1c

Purpose: Resources without direct internet access
Usage: EKS nodes, RDS databases, Private EC2
```

#### 4. Gateways
```
Internet Gateway: Connects public subnets to internet
NAT Gateway: Allows private subnets to access internet
Elastic IP: Public IP for NAT Gateway
```

#### 5. Route Tables
```
Public Route Table: Routes traffic to Internet Gateway
Private Route Table: Routes traffic to NAT Gateway
```

#### 6. Security Groups
```
default-group: Minimal access (placeholder)
bastion-host: SSH access on port 22
test-host: HTTP access on port 80
alb-ingress: HTTP (80) and HTTPS (443) for load balancers
```

#### 7. DB Subnet Group
```
Name: network-db-subnet-group-dev
Purpose: Group private subnets for RDS databases
Subnets: Private subnet 0 and 1
```

### Staging Environment

**Status**: Commented out (not deployed)

To enable staging, uncomment the code in `staging.tf`.

---

## 🏗️ Network Architecture

### Visual Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                      VPC: 10.0.0.0/16                                │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                   Internet Gateway                              │ │
│  └────────────────────┬───────────────────────────────────────────┘ │
│                       │                                               │
│  ┌────────────────────┴───────────────────────────────────────────┐ │
│  │              Public Subnets (3 AZs)                             │ │
│  │                                                                  │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │ │
│  │  │   AZ-1a      │  │   AZ-1b      │  │   AZ-1c      │         │ │
│  │  │ 10.0.0.0/20  │  │ 10.0.16.0/20 │  │ 10.0.32.0/20 │         │ │
│  │  │              │  │              │  │              │         │ │
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │  │              │         │ │
│  │  │ │ Bastion  │ │  │ │ Bastion  │ │  │              │         │ │
│  │  │ │  Hosts   │ │  │ │  Hosts   │ │  │              │         │ │
│  │  │ └──────────┘ │  │ └──────────┘ │  │              │         │ │
│  │  │              │  │              │  │              │         │ │
│  │  │ ┌──────────┐ │  │              │  │              │         │ │
│  │  │ │   NAT    │ │  │              │  │              │         │ │
│  │  │ │ Gateway  │ │  │              │  │              │         │ │
│  │  │ └──────────┘ │  │              │  │              │         │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘         │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │              Private Subnets (3 AZs)                           │ │
│  │                                                                  │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │ │
│  │  │   AZ-1a      │  │   AZ-1b      │  │   AZ-1c      │         │ │
│  │  │ 10.0.48.0/20 │  │ 10.0.64.0/20 │  │ 10.0.80.0/20 │         │ │
│  │  │              │  │              │  │              │         │ │
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │         │ │
│  │  │ │   EKS    │ │  │ │   EKS    │ │  │ │   EKS    │ │         │ │
│  │  │ │  Nodes   │ │  │ │  Nodes   │ │  │ │  Nodes   │ │         │ │
│  │  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │         │ │
│  │  │              │  │              │  │              │         │ │
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │  │              │         │ │
│  │  │ │   RDS    │ │  │ │   RDS    │ │  │              │         │ │
│  │  │ │ Database │ │  │ │(Standby) │ │  │              │         │ │
│  │  │ └──────────┘ │  │ └──────────┘ │  │              │         │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘         │ │
│  └──────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘

Traffic Flow:
  Public Subnet → Internet Gateway → Internet ✓
  Private Subnet → NAT Gateway → Internet Gateway → Internet ✓
  Internet → Internet Gateway → Public Subnet only ✓
  Internet → Private Subnet ✗ (blocked)
```

### High Availability Design

**3 Availability Zones (AZs):**
- If one AZ fails, resources in other AZs continue running
- Increases reliability and fault tolerance
- Recommended by AWS for production workloads

---

## 📚 Prerequisites

### 1. Completed Bootstrap
✅ Bootstrap infrastructure must be deployed first
- S3 bucket for state storage
- DynamoDB table for locking
- KMS keys for encryption

**Verify bootstrap:**
```powershell
cd ../bootstrap
terraform output
# Should show KMS keys and IAM roles
```

### 2. Software Requirements
- ✅ AWS CLI configured
- ✅ Terraform 1.3.0 installed
- ✅ Valid AWS credentials

---

## 🚀 Step-by-Step Deployment

### Update Configuration

#### 1. Update `provider.tf`
Change AWS profile:
```hcl
provider "aws" {
  region  = "ap-southeast-1"
  profile = "YOUR_AWS_PROFILE"  # ← Change this
}
```

#### 2. Update `terraform.tfvars`
Customize network settings:
```hcl
name         = "network"
project-name = "your-project-name"  # ← Change this
owner        = "your-name"          # ← Change this

# Optional: Modify IP ranges if needed
vpc-cidr-block-dev = "10.0.0.0/16"
```

### Deployment Steps

#### **Step 1: Navigate to Networks Folder**
```powershell
cd terraform/networks
```

#### **Step 2: Initialize Terraform**
```powershell
terraform init
```

**What this does:**
- Downloads AWS provider
- Configures S3 backend (from bootstrap)
- Prepares to read bootstrap outputs

**Expected output:**
```
Terraform has been successfully initialized!
```

#### **Step 3: Review Plan**
```powershell
terraform plan
```

**What to check:**
- VPC will be created
- 6 subnets (3 public + 3 private)
- 2 route tables
- 1 Internet Gateway
- 1 NAT Gateway
- Security groups

**Expected output:**
```
Plan: 25 to add, 0 to change, 0 to destroy.
```

#### **Step 4: Apply Configuration**
```powershell
terraform apply
```

Type `yes` when prompted.

⏱️ **Time**: ~3-5 minutes

**Expected output:**
```
Apply complete! Resources: 25 added, 0 changed, 0 destroyed.

Outputs:
dev-sd5046-aws-infrastructure-vpc = { id = "vpc-xxxxx", cidr_block = "10.0.0.0/16" }
dev-public-subnet-0 = { id = "subnet-xxxxx", cidr_block = "10.0.0.0/20" }
dev-private-subnet-0 = { id = "subnet-yyyyy", cidr_block = "10.0.48.0/20" }
```

---

## 📄 Configuration Files Explained

### 1. `dev.tf` - Development Network

**Creates:**
- Module for tags (standardized resource naming)
- Network module with dev configuration
- Reads variables from `terraform.tfvars`

**Key section:**
```hcl
module "network_dev" {
  source = "../modules/network"
  
  vpc-cidr-block = "10.0.0.0/16"
  
  public-subnet-numbers = {
    0 = "10.0.0.0/20"
    1 = "10.0.16.0/20"
    2 = "10.0.32.0/20"
  }
  
  private-subnet-numbers = {
    0 = "10.0.48.0/20"
    1 = "10.0.64.0/20"
    2 = "10.0.80.0/20"
  }
  
  create_private_natgw = true  # Creates NAT Gateway
}
```

### 2. `staging.tf` - Staging Network

**Status**: Commented out (not deployed)

**Uses different IP range**: `10.1.0.0/16`

**To enable:**
1. Uncomment all code in `staging.tf`
2. Uncomment staging outputs in `outputs.tf`
3. Run `terraform apply`

### 3. `security-groups.tf` - Firewall Rules

**Creates:**
- `alb-ingress` security group
  - Port 80 (HTTP) from anywhere
  - Port 443 (HTTPS) from anywhere
  - For Application Load Balancers

**More security groups** defined in `locals.tf`:
- `bastion-host` - SSH access (port 22)
- `test-host` - HTTP access (port 80)
- `default-group` - Minimal access

### 4. `locals.tf` - Security Group Definitions

**Defines firewall rules:**
```hcl
bastion-host = {
  ingress = {
    from_port   = "22"      # SSH
    to_port     = "22"
    protocol    = "TCP"
    cidr_blocks = "0.0.0.0/0"  # From anywhere (⚠️ Consider restricting)
  }
}
```

### 5. `variables.tf` - Input Variables

**Defines:**
- AWS region
- VPC CIDR blocks
- Subnet configurations
- Project metadata

### 6. `terraform.tfvars` - Variable Values

**Sets actual values:**
- Dev network: `10.0.0.0/16`
- Staging network: `10.1.0.0/16`
- Project name and owner

### 7. `outputs.tf` - Exported Values

**Exports network information** for other modules:
- VPC ID
- Subnet IDs
- Security group IDs
- Route table IDs

**Used by:**
- EKS (needs subnet IDs)
- EC2 (needs subnet and security group IDs)
- RDS (needs subnet group)

### 8. `provider.tf` - Terraform Configuration

**Configures:**
- AWS provider
- S3 backend (uses bootstrap bucket)
- Remote state references

---

## 🎨 Customization Guide

### Change IP Address Ranges

**Edit `terraform.tfvars`:**

```hcl
# Use different IP range
vpc-cidr-block-dev = "172.16.0.0/16"

public-subnet-numbers-dev = {
  0 = "172.16.0.0/20"
  1 = "172.16.16.0/20"
  2 = "172.16.32.0/20"
}

private-subnet-numbers-dev = {
  0 = "172.16.48.0/20"
  1 = "172.16.64.0/20"
  2 = "172.16.80.0/20"
}
```

**IP Range Recommendations:**
- **10.0.0.0/8** - Commonly used for corporate networks
- **172.16.0.0/12** - AWS default VPC range
- **192.168.0.0/16** - Small networks

**Avoid conflicts** with:
- Your office network
- VPN networks
- Other AWS VPCs

### Add More Subnets

**Edit `terraform.tfvars`:**
```hcl
public-subnet-numbers-dev = {
  0 = "10.0.0.0/20"
  1 = "10.0.16.0/20"
  2 = "10.0.32.0/20"
  3 = "10.0.48.0/20"  # ← Add more
}
```

### Disable NAT Gateway (Save Costs)

**Edit `dev.tf`:**
```hcl
module "network_dev" {
  source = "../modules/network"
  
  create_private_natgw = false  # ← Disable NAT Gateway
}
```

**Impact:**
- Private subnets can't access internet
- No outbound internet for EKS nodes
- Saves ~$32/month
- ⚠️ May break EKS node setup

### Add Custom Security Group

**Edit `locals.tf`:**
```hcl
locals {
  security-groups = {
    my-custom-group = {
      ingress = {
        from_port   = "8080"
        to_port     = "8080"
        protocol    = "TCP"
        cidr_blocks = "10.0.0.0/16"  # Only from VPC
      }
    }
  }
}
```

### Restrict Bastion SSH Access

**Security improvement - Limit SSH to your IP:**

**Edit `locals.tf`:**
```hcl
bastion-host = {
  ingress = {
    from_port   = "22"
    to_port     = "22"
    protocol    = "TCP"
    cidr_blocks = "YOUR_PUBLIC_IP/32"  # ← Your IP only
  }
}
```

**Find your IP:**
```powershell
(Invoke-WebRequest -Uri "https://api.ipify.org").Content
```

### Enable Staging Environment

**Uncomment `staging.tf`:**
```hcl
# Remove all comment markers (#) from staging.tf
module "network_label_staging" {
  # ... full configuration
}
```

---

## ✅ Verification

### Check Terraform Outputs

```powershell
terraform output
```

**Expected output:**
```
dev-sd5046-aws-infrastructure-vpc = {
  "arn" = "arn:aws:ec2:ap-southeast-1:377414509754:vpc/vpc-xxxxx"
  "cidr_block" = "10.0.0.0/16"
  "id" = "vpc-xxxxx"
}

dev-public-subnet-0 = {
  "id" = "subnet-xxxxx"
  "cidr_block" = "10.0.0.0/20"
  "availability_zone" = "ap-southeast-1a"
}

security-groups = {
  "bastion-host" = "sg-xxxxx"
  "default-group" = "sg-yyyyy"
}
```

### Verify in AWS Console

#### 1. VPC Console
**URL**: https://console.aws.amazon.com/vpc/

**Check:**
- VPCs: Should see `sd5046-aws-infrastructure-network-dev`
- Subnets: Should see 6 subnets (3 public, 3 private)
- Internet Gateways: 1 attached to VPC
- NAT Gateways: 1 in public subnet
- Route Tables: 2 (public and private)

#### 2. Using AWS CLI

**List VPCs:**
```powershell
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=sd5046-aws-infrastructure"
```

**List Subnets:**
```powershell
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxx"
```

**List Security Groups:**
```powershell
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=vpc-xxxxx"
```

**Check NAT Gateway:**
```powershell
aws ec2 describe-nat-gateways --filter "Name=state,Values=available"
```

### Test Network Connectivity

**After deploying EC2:**
1. SSH to bastion host in public subnet
2. Verify internet access: `ping 8.8.8.8`
3. Check private subnet access

---

## 🔧 Troubleshooting

### Issue 1: "Error: reading Terraform remote state"

**Problem**: Can't read bootstrap state

**Solution**:
```powershell
# Verify bootstrap is deployed
cd ../bootstrap
terraform output

# Check S3 bucket exists
aws s3 ls | findstr terraform
```

### Issue 2: "Error: Insufficient VPC Capacity"

**Problem**: AWS account VPC limit reached (default: 5)

**Solution**: Request VPC limit increase in AWS Console

### Issue 3: "Error: NAT Gateway creation timeout"

**Problem**: NAT Gateway taking too long

**Solution**: Wait up to 10 minutes, or retry:
```powershell
terraform apply -replace="aws_nat_gateway.private-natgw[0]"
```

### Issue 4: Overlapping CIDR Blocks

**Problem**: IP ranges conflict with existing VPC

**Solution**: Change CIDR blocks in `terraform.tfvars`:
```hcl
vpc-cidr-block-dev = "172.16.0.0/16"  # Different range
```

### Issue 5: Security Group Rules Not Working

**Problem**: Traffic blocked unexpectedly

**Check:**
1. **Security group rules** in console
2. **Route table** associations
3. **NACL rules** (Network ACLs)
4. **Destination** resource security group

**Debug:**
```powershell
# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxx
```

### Issue 6: "Error: InvalidSubnet.Range"

**Problem**: Subnet CIDR doesn't fit in VPC CIDR

**Solution**: Ensure subnet CIDR is within VPC CIDR:
- VPC: `10.0.0.0/16`
- Valid subnet: `10.0.0.0/20` ✓
- Invalid subnet: `10.1.0.0/20` ✗

---

## ⚠️ Important Notes

### Cost Considerations

**Monthly costs:**
- VPC: Free
- Subnets: Free
- Internet Gateway: Free
- Route Tables: Free
- **NAT Gateway: ~$32/month** (largest cost)
- Elastic IP: $0 (while attached to NAT Gateway)
- Data transfer: Variable (~$0.09/GB)

**Total: ~$32-50/month**

**Cost savings:**
- Disable NAT Gateway if private subnets don't need internet
- Use VPC endpoints instead of NAT for AWS services

### Security Best Practices

1. **Restrict bastion SSH** to your IP only
2. **Don't use 0.0.0.0/0** for production security groups
3. **Enable VPC Flow Logs** for monitoring
4. **Use private subnets** for databases and application servers
5. **Never put databases in public subnets**

### Network Planning

1. **CIDR block sizing:**
   - Too small: Run out of IPs
   - Too large: Wasted address space
   - Recommendation: /16 for VPC, /20 for subnets

2. **Availability zones:**
   - Use at least 2 for high availability
   - This setup uses 3 (best practice)

3. **Subnet types:**
   - Public: Resources that need public IP
   - Private: Internal resources only

### Modifying Existing Networks

⚠️ **WARNING**: Some changes require replacement

**Safe changes:**
- Add new subnets
- Add security group rules
- Modify route tables

**Destructive changes:**
- Change VPC CIDR (recreates VPC)
- Change subnet CIDR (recreates subnet)
- Delete NAT Gateway (breaks private subnet internet)

**Before destructive changes:**
```powershell
# Backup state
terraform state pull > backup.tfstate

# Preview changes
terraform plan
```

### Destroy Order

**To destroy network infrastructure:**

⚠️ **Must destroy resources IN THIS ORDER:**
1. RDS (databases in this VPC)
2. EC2 (instances in this VPC)
3. EKS (cluster in this VPC)
4. **Then Networks**

```powershell
cd terraform/networks
terraform destroy
```

---

## 🎓 Understanding Network Concepts

### What is CIDR Notation?

**CIDR** = Classless Inter-Domain Routing

**Format**: `IP_ADDRESS/PREFIX_LENGTH`

**Examples:**
- `10.0.0.0/16` = 65,536 IP addresses (10.0.0.0 to 10.0.255.255)
- `10.0.0.0/20` = 4,096 IP addresses (10.0.0.0 to 10.0.15.255)
- `10.0.0.0/24` = 256 IP addresses (10.0.0.0 to 10.0.0.255)

**Larger number after /** = Fewer IPs**

### Public vs Private Subnets

| Feature | Public Subnet | Private Subnet |
|---------|--------------|----------------|
| **Internet Gateway** | Yes | No |
| **Public IP** | Auto-assigned | No |
| **Inbound from Internet** | Yes | No |
| **Outbound to Internet** | Yes | Via NAT Gateway |
| **Use Cases** | Load balancers, Bastion | Databases, App servers |

### What is NAT Gateway?

**NAT** = Network Address Translation

**Purpose**: Allows private subnets to access internet without being directly accessible

**How it works:**
1. Private EC2 wants to download update from internet
2. Traffic goes to NAT Gateway (in public subnet)
3. NAT Gateway forwards request with its public IP
4. Response comes back to NAT Gateway
5. NAT Gateway forwards to private EC2

**Why not just use public subnet?**
- Security - Resources not directly accessible from internet
- Best practice for databases and application servers

### Route Tables Explained

**Route table** = Rules for where network traffic goes

**Public subnet route table:**
```
Destination      Target
10.0.0.0/16      local              # Within VPC
0.0.0.0/0        igw-xxxxx          # Everything else → Internet
```

**Private subnet route table:**
```
Destination      Target
10.0.0.0/16      local              # Within VPC
0.0.0.0/0        nat-xxxxx          # Everything else → NAT Gateway
```

---

## 🎓 Next Steps

After network deployment:

1. ✅ Verify all subnets in AWS Console
2. ✅ Test connectivity (after EC2 deployment)
3. ✅ Review security group rules
4. ✅ Proceed to **[EKS](../eks/README.md)** deployment

---

## 📞 Need Help?

- Check main [README](../../README.md)
- Review [AWS VPC documentation](https://docs.aws.amazon.com/vpc/)
- Check [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/)

---

**Last Updated**: December 2025  
**Terraform Version**: 1.3.0  
**AWS Provider Version**: 4.67.0
