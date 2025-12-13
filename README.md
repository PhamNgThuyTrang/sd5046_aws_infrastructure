# SD5046 AWS Infrastructure - Complete Setup Guide

## 📋 Table of Contents
- [Overview](#overview)
- [What This Repository Does](#what-this-repository-does)
- [Architecture Diagram](#architecture-diagram)
- [Prerequisites](#prerequisites)
- [Quick Start Guide](#quick-start-guide)
- [Folder Structure](#folder-structure)
- [Deployment Order](#deployment-order)
- [Detailed Documentation](#detailed-documentation)
- [Troubleshooting](#troubleshooting)
- [Important Notes](#important-notes)

---

## 🎯 Overview

This repository contains **Infrastructure as Code (IaC)** using **Terraform** to automatically create and manage cloud infrastructure on **Amazon Web Services (AWS)**. 

Think of it as a blueprint that automatically builds:
- 🌐 **Network infrastructure** (Virtual Private Cloud, subnets, routing)
- 🚀 **Kubernetes cluster** (EKS - Elastic Kubernetes Service)
- 💻 **Virtual servers** (EC2 instances for secure access)
- 🗄️ **Databases** (RDS - Relational Database Service)
- 📦 **Container registry** (ECR - Elastic Container Registry)

---

## 🔍 What This Repository Does

### For Complete Beginners:

**Terraform** = A tool that writes code to create cloud infrastructure automatically
**AWS** = Amazon's cloud computing platform (like renting computers, storage, and services)

**This repo replaces manual clicking in AWS Console with code that:**
1. Creates secure networks isolated from the internet
2. Sets up a Kubernetes cluster to run containerized applications
3. Configures databases to store your application data
4. Creates jump servers (bastion hosts) for secure access
5. Sets up a place to store Docker container images

### Infrastructure Created:

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Cloud                            │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              VPC (Virtual Network)                      │ │
│  │                                                          │ │
│  │  ┌──────────────┐         ┌──────────────┐             │ │
│  │  │   Public     │         │   Private    │             │ │
│  │  │   Subnets    │         │   Subnets    │             │ │
│  │  │              │         │              │             │ │
│  │  │  ┌────────┐  │         │  ┌────────┐  │             │ │
│  │  │  │Bastion │  │         │  │  EKS   │  │             │ │
│  │  │  │ Host   │──┼────────>│  │Cluster │  │             │ │
│  │  │  └────────┘  │         │  └────────┘  │             │ │
│  │  │              │         │              │             │ │
│  │  │              │         │  ┌────────┐  │             │ │
│  │  │              │         │  │  RDS   │  │             │ │
│  │  │              │         │  │Database│  │             │ │
│  │  │              │         │  └────────┘  │             │ │
│  │  └──────────────┘         └──────────────┘             │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │           ECR (Container Registry)                      │ │
│  │         (Stores Docker Images)                          │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 📚 Prerequisites

### 1. Software Installation

You need to install these tools on your computer:

#### **Terraform** (Infrastructure automation tool)
- **Windows**: 
  ```powershell
  # Using Chocolatey
  choco install terraform
  
  # Or download from: https://www.terraform.io/downloads
  ```
- **Verify installation**:
  ```powershell
  terraform version
  # Should show: Terraform v1.3.x
  ```

#### **AWS CLI** (Command line tool for AWS)
- **Download**: https://aws.amazon.com/cli/
- **Verify installation**:
  ```powershell
  aws --version
  # Should show: aws-cli/2.x.x
  ```

#### **kubectl** (Kubernetes command line tool)
- **Windows**:
  ```powershell
  choco install kubernetes-cli
  ```
- **Verify installation**:
  ```powershell
  kubectl version --client
  ```

### 2. AWS Account Setup

You need:
1. **AWS Account** - Sign up at https://aws.amazon.com
2. **AWS Credentials** - Access keys or SSO profile
3. **Permissions** - Administrator access to create resources

#### **Step 2.1: Create AWS Account**

If you don't have an AWS account yet:

1. Go to https://aws.amazon.com
2. Click **"Create an AWS Account"**
3. Follow the registration process:
   - Enter email address
   - Choose account name
   - Provide contact information
   - Add payment method (credit card required)
   - Verify your identity (phone verification)
4. Select **Free Tier** plan (12 months free for eligible services)

**⚠️ Important**: Even with Free Tier, this infrastructure will incur costs since EKS and NAT Gateway are not free.

#### **Step 2.2: Create IAM User with Admin Access**

**Why?** Never use root account for daily operations. Create an IAM user instead.

**Steps:**

1. **Sign in to AWS Console**: https://console.aws.amazon.com
   - Use your root account email and password

2. **Navigate to IAM Service**:
   - Search for "IAM" in the search bar
   - Click **"IAM"** (Identity and Access Management)

3. **Create New User**:
   - Click **"Users"** in the left sidebar
   - Click **"Add users"** button
   - Enter username (e.g., `your-name-admin`)
   - Click **"Next"**

4. **Set Permissions**:
   - Select **"Attach policies directly"**
   - Search for and check **"AdministratorAccess"**
   - Click **"Next"**
   - Click **"Create user"**

5. **Create Access Keys**:
   - Click on the newly created user
   - Go to **"Security credentials"** tab
   - Scroll to **"Access keys"** section
   - Click **"Create access key"**
   - Select **"Command Line Interface (CLI)"**
   - Check the confirmation box
   - Click **"Next"**
   - Add description (e.g., "Terraform CLI access")
   - Click **"Create access key"**

6. **Save Your Credentials** (IMPORTANT!):
   ```
   Access Key ID: AKIAIOSFODNN7EXAMPLE
   Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   ```
   - Click **"Download .csv file"** (save securely)
   - ⚠️ **You can only see the secret key once!**
   - Store in a password manager

#### **Step 2.3: Configure AWS Credentials**

Now configure AWS CLI with your credentials:

**Option A: Using Access Keys (Simpler for Beginners)**

```powershell
# Run this command
aws configure

# You'll be prompted for:
AWS Access Key ID [None]: <Paste your Access Key ID>
AWS Secret Access Key [None]: <Paste your Secret Access Key>
Default region name [None]: ap-southeast-1
Default output format [None]: json
```

**Example interaction:**
```powershell
PS C:\> aws configure
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: ap-southeast-1
Default output format [None]: json
```

**Verify configuration:**
```powershell
# Test AWS CLI connection
aws sts get-caller-identity
```

**Expected output:**
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-name-admin"
}
```

If you see your account details, you're ready! ✅

**Where credentials are stored:**
- Windows: `C:\Users\YourName\.aws\credentials`
- Linux/Mac: `~/.aws/credentials`

---

**Option B: Using AWS SSO (For Organizations)**

If your company uses AWS SSO:

```powershell
# Start SSO configuration
aws configure sso
```

**You'll be prompted for:**
```powershell
SSO session name (Recommended): my-sso-session
SSO start URL [None]: https://my-company.awsapps.com/start
SSO region [None]: us-east-1
SSO registration scopes [sso:account:access]: <Press Enter>
```

**Then:**
1. Your browser will open
2. Sign in with your company credentials
3. Authorize the AWS CLI
4. Return to terminal and select:
   - AWS account
   - IAM role (choose Administrator or similar)
   - Default region: `ap-southeast-1`
   - Output format: `json`
   - Profile name: `my-company-profile`

**Using SSO profile:**
```powershell
# Login to SSO (do this daily/when token expires)
aws sso login --profile my-company-profile

# Test connection
aws sts get-caller-identity --profile my-company-profile
```

#### **Step 2.4: Verify AWS Account ID**

You'll need your AWS Account ID for configuration:

```powershell
# Get your account ID
aws sts get-caller-identity --query Account --output text
```

**Example output:**
```
123456789012
```

**Save this number!** You'll need to update it in the Terraform configuration files.

#### **Step 2.5: Check Your Permissions**

Verify you have administrator access:

```powershell
# List attached policies for your user
aws iam list-attached-user-policies --user-name your-name-admin
```

**Expected output should include:**
```json
{
    "AttachedPolicies": [
        {
            "PolicyName": "AdministratorAccess",
            "PolicyArn": "arn:aws:iam::aws:policy/AdministratorAccess"
        }
    ]
}
```

If you see `AdministratorAccess`, you're good to go! ✅

---

#### **Troubleshooting AWS Credentials**

**Issue: "Unable to locate credentials"**

**Solution:**
```powershell
# Check if credentials file exists
Test-Path $env:USERPROFILE\.aws\credentials

# If False, run aws configure again
aws configure
```

**Issue: "An error occurred (UnauthorizedOperation)"**

**Solution:** Your IAM user doesn't have sufficient permissions. Add `AdministratorAccess` policy to your user.

**Issue: "The security token included in the request is invalid"**

**Solution:** For SSO, your session expired:
```powershell
aws sso login --profile my-company-profile
```

**Issue: Can't remember which profile to use**

**Solution:** List all configured profiles:
```powershell
# Windows
Get-Content $env:USERPROFILE\.aws\config

# Or view credentials
Get-Content $env:USERPROFILE\.aws\credentials
```

### 3. Important Configuration

⚠️ **Before running this code, you MUST update these values:**

1. **AWS Profile Name**: Currently set to `datton.nashtech.saml`
   - Location: All `provider.tf` files
   - Change to your AWS profile name

2. **AWS Account ID**: Currently `377414509754`
   - Location: Bootstrap KMS policies
   - Change to your AWS account ID

3. **Region**: Currently `ap-southeast-1` (Singapore)
   - Location: All `provider.tf` files
   - Change if you want a different region

---

## 🚀 Quick Start Guide

### Step-by-Step Deployment

#### **Step 1: Clone the Repository**
```powershell
git clone <repository-url>
cd sd5046_aws_infrastructure
```

#### **Step 2: Update Configuration**
1. Find your AWS account ID:
   ```powershell
   aws sts get-caller-identity --query Account --output text
   ```

2. Update `terraform.auto.tfvars` files with your values:
   - Owner name
   - Project name
   - Environment

#### **Step 3: Deploy Infrastructure** (IN THIS ORDER!)

```powershell
# 1. Bootstrap (Foundation - Creates S3 bucket for state storage)
cd terraform/bootstrap
terraform init
terraform plan    # Preview changes
terraform apply   # Type 'yes' to create

# 2. Networks (VPC, Subnets, Security Groups)
cd ../networks
terraform init
terraform plan
terraform apply

# 3. EKS (Kubernetes Cluster)
cd ../eks
terraform init
terraform plan
terraform apply   # This takes 15-20 minutes!

# 4. EC2 (Bastion Hosts)
cd ../ec2
terraform init
terraform plan
terraform apply

# 5. RDS (Databases)
cd ../rds
terraform init
terraform plan
terraform apply

# 6. ECR (Container Registry)
cd ../ecr
terraform init
terraform plan
terraform apply
```

---

## 📁 Folder Structure

```
sd5046_aws_infrastructure/
│
├── README.md                          # This file - Overview and main guide
│
├── terraform/
│   │
│   ├── bootstrap/                     # Step 1: Foundation infrastructure
│   │   ├── README.md                  # Detailed bootstrap guide
│   │   ├── ws_bootstrap.tf           # S3 bucket, DynamoDB table
│   │   ├── kms.tf                    # Encryption keys
│   │   ├── ec2_roles.tf              # IAM roles for EC2
│   │   └── provider.tf               # AWS and Terraform configuration
│   │
│   ├── networks/                      # Step 2: Network infrastructure
│   │   ├── README.md                  # Detailed network guide
│   │   ├── dev.tf                    # Development environment network
│   │   ├── staging.tf                # Staging environment (commented out)
│   │   ├── security-groups.tf        # Firewall rules
│   │   └── locals.tf                 # Network configuration
│   │
│   ├── eks/                           # Step 3: Kubernetes cluster
│   │   ├── README.md                  # Detailed EKS guide
│   │   ├── eks.tf                    # Main cluster configuration
│   │   ├── key_pair.tf               # SSH keys for nodes
│   │   └── irsa_*.tf                 # Service account permissions
│   │
│   ├── ec2/                           # Step 4: Bastion hosts
│   │   ├── README.md                  # Detailed EC2 guide
│   │   ├── main.tf                   # EC2 instance creation
│   │   └── locals.tf                 # Instance configurations
│   │
│   ├── rds/                           # Step 5: Databases
│   │   ├── README.md                  # Detailed RDS guide
│   │   ├── main.tf                   # Database creation
│   │   └── locals.tf                 # Database configurations
│   │
│   ├── ecr/                           # Step 6: Container registry
│   │   ├── README.md                  # Detailed ECR guide
│   │   └── main.tf                   # ECR repository creation
│   │
│   └── modules/                       # Reusable infrastructure components
│       ├── network/                  # Network module
│       ├── eks/                      # EKS module
│       ├── ec2/                      # EC2 module
│       ├── rds/                      # RDS module
│       ├── ecr/                      # ECR module
│       └── tags/                     # Standardized resource tagging
```

---

## 🔢 Deployment Order

**CRITICAL**: You must deploy in this exact order because each step depends on the previous one:

| Step | Folder | Why | Time |
|------|--------|-----|------|
| 1️⃣ | `bootstrap/` | Creates S3 bucket to store infrastructure state | ~2 min |
| 2️⃣ | `networks/` | Creates VPC, subnets for all other resources | ~3 min |
| 3️⃣ | `eks/` | Creates Kubernetes cluster (needs network) | ~20 min |
| 4️⃣ | `ec2/` | Creates bastion hosts (needs network) | ~2 min |
| 5️⃣ | `rds/` | Creates databases (needs network) | ~5 min |
| 6️⃣ | `ecr/` | Creates container registry (independent) | ~1 min |

**Total Time**: ~35 minutes

---

## 📖 Detailed Documentation

Each folder has its own detailed README with specific instructions:

- **[Bootstrap Guide](terraform/bootstrap/README.md)** - Setting up the foundation
- **[Networks Guide](terraform/networks/README.md)** - Configuring VPC and subnets
- **[EKS Guide](terraform/eks/README.md)** - Deploying Kubernetes cluster
- **[EC2 Guide](terraform/ec2/README.md)** - Setting up bastion hosts
- **[RDS Guide](terraform/rds/README.md)** - Creating databases
- **[ECR Guide](terraform/ecr/README.md)** - Setting up container registry

---

## 🔧 Troubleshooting

### Common Issues

#### **Issue 1: "Error: No valid credential sources found"**
**Solution**: Configure AWS credentials
```powershell
aws configure
# Enter your AWS credentials
```

#### **Issue 2: "Error: Backend initialization required"**
**Solution**: Run terraform init
```powershell
terraform init
```

#### **Issue 3: "Error: State locking failed"**
**Solution**: Another user is running Terraform. Wait or:
```powershell
# Force unlock (use carefully!)
terraform force-unlock <LOCK_ID>
```

#### **Issue 4: "Error: Insufficient IAM permissions"**
**Solution**: Ensure your AWS user has AdministratorAccess policy

#### **Issue 5: "Error: Resource already exists"**
**Solution**: Import existing resource or destroy and recreate:
```powershell
terraform destroy  # Removes all infrastructure
terraform apply    # Creates fresh
```

### Getting Help

1. Check the specific folder's README for detailed guidance
2. Review AWS console to see what was created
3. Check Terraform error messages - they're usually helpful
4. View Terraform state: `terraform show`

---

## ⚠️ Important Notes

### Cost Warning
**This infrastructure will cost money!**
- EKS Cluster: ~$72/month (cluster) + worker nodes
- RDS Databases: ~$15-30/month per database
- NAT Gateway: ~$32/month
- Data transfer and other services

**Estimated monthly cost: $150-300**

To avoid charges, destroy infrastructure when not in use:
```powershell
# Destroy in reverse order
cd terraform/ecr && terraform destroy
cd ../rds && terraform destroy
cd ../ec2 && terraform destroy
cd ../eks && terraform destroy      # This takes ~15 minutes
cd ../networks && terraform destroy
cd ../bootstrap && terraform destroy
```

### Security Notes

1. **Never commit sensitive data** to Git:
   - AWS credentials
   - Database passwords
   - Private keys

2. **Use `.gitignore`** to exclude:
   - `*.tfstate` files (contain sensitive data)
   - `.terraform/` directories
   - `*.pem` key files

3. **Rotate credentials** regularly

4. **Use AWS Secrets Manager** for production passwords

### State Management

- Terraform state is stored in S3: `terraform-boostrap-nashtech-devops-0002`
- State is encrypted with KMS
- State locking uses DynamoDB to prevent conflicts
- **Never manually edit state files**

---

## 🎓 Learning Resources

### Understanding Key Concepts

- **Terraform**: https://learn.hashicorp.com/terraform
- **AWS Basics**: https://aws.amazon.com/getting-started/
- **Kubernetes**: https://kubernetes.io/docs/tutorials/
- **VPC Networking**: https://docs.aws.amazon.com/vpc/

### AWS Services Used

- **VPC** (Virtual Private Cloud) - Isolated network
- **EC2** (Elastic Compute Cloud) - Virtual servers
- **EKS** (Elastic Kubernetes Service) - Managed Kubernetes
- **RDS** (Relational Database Service) - Managed databases
- **ECR** (Elastic Container Registry) - Docker image storage
- **S3** (Simple Storage Service) - Object storage
- **KMS** (Key Management Service) - Encryption keys
- **IAM** (Identity and Access Management) - Permissions

---

## 📞 Support

For issues or questions:
1. Check folder-specific README files
2. Review Terraform documentation
3. Check AWS service documentation

---

## 📝 License

[Add your license information here]

---

**Last Updated**: December 2025  
**Terraform Version**: 1.3.0  
**AWS Provider Version**: 4.67.0