# Bootstrap - Foundation Infrastructure Guide

## 📋 Table of Contents
- [Overview](#overview)
- [What is Bootstrap?](#what-is-bootstrap)
- [What Gets Created](#what-gets-created)
- [Prerequisites](#prerequisites)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [Configuration Files Explained](#configuration-files-explained)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Important Notes](#important-notes)

---

## 🎯 Overview

The **bootstrap** folder is the **first and most critical** step in deploying your AWS infrastructure. It creates the foundational resources needed for secure Terraform state management and shared infrastructure.

**Think of it as building the foundation of a house before building the walls.**

---

## 🔍 What is Bootstrap?

### For Beginners:

**The "Chicken and Egg" Problem:**
- Terraform needs a place to store its state (record of what it created)
- But you need Terraform to create that storage
- Bootstrap solves this by creating the storage first

**Bootstrap creates:**
1. 🗃️ **S3 Bucket** - Secure storage for Terraform state files
2. 🔒 **DynamoDB Table** - Prevents multiple people from running Terraform at once
3. 🔐 **KMS Keys** - Encryption keys to secure your data
4. 👤 **IAM Roles** - Permissions for EC2 instances to access AWS services

---

## 📦 What Gets Created

### 1. S3 Bucket (State Storage)
```
Name: terraform-boostrap-nashtech-devops-0002
Purpose: Stores Terraform state files
Features:
  - Versioning enabled (can recover old versions)
  - Encryption with KMS
  - Transfer acceleration enabled
```

**Why?** 
- Allows team collaboration (everyone sees same state)
- Keeps history of infrastructure changes
- Encrypted to protect sensitive data (passwords, IPs)

### 2. DynamoDB Table (State Locking)
```
Name: terraform-boostrap-nashtech-devops
Purpose: Prevents simultaneous Terraform runs
Hash Key: LockID
```

**Why?**
- Prevents two people from modifying infrastructure at the same time
- Avoids corrupted state files
- Shows who is currently running Terraform

### 3. KMS Keys (Encryption)

**a) Bootstrap KMS Key**
```
Name: terraform-boostrap-nashtech-devops-0002
Purpose: Encrypts S3 bucket and DynamoDB table
```

**b) EKS KMS Key**
```
Alias: eks-test
Purpose: Encrypts Kubernetes secrets
```

**Why?**
- Protects sensitive data at rest
- Meets security compliance requirements
- Only authorized users can decrypt

### 4. IAM Roles (Permissions)

**Bastion Host Roles**
```
Role 1: bastion-nashtech-devops
Role 2: bastion-nashtech-devops-0002
Purpose: Allow EC2 instances to access S3 without storing credentials
```

**Why?**
- Secure way for EC2 instances to access AWS services
- No hardcoded credentials on servers
- Automatic credential rotation

---

## 📚 Prerequisites

### Before You Start:

1. ✅ **AWS Account** with administrator access
2. ✅ **AWS CLI** installed and configured
3. ✅ **Terraform** installed (version ~1.3.0)
4. ✅ **AWS Profile** configured (SSO or access keys)

### Find Your AWS Account ID:
```powershell
aws sts get-caller-identity --query Account --output text
```

### Verify Your AWS Profile:
```powershell
aws sts get-caller-identity --profile datton.nashtech.saml
```

---

## 🚀 Step-by-Step Deployment

### ⚠️ IMPORTANT: Update Configuration First!

Before running Terraform, you **MUST** update these values:

#### 1. Update `provider.tf`
Change the AWS profile name:
```hcl
provider "aws" {
  region  = "ap-southeast-1"
  profile = "YOUR_AWS_PROFILE_HERE"  # ← Change this
}
```

#### 2. Update `kms.tf`
Change AWS account ID in both KMS policies:
```hcl
principals {
  type = "AWS"
  identifiers = [
    "arn:aws:iam::YOUR_ACCOUNT_ID:user/YOUR_USERNAME"  # ← Change these
  ]
}
```

#### 3. Update `terraform.auto.tfvars`
Change project details:
```hcl
name        = "boostrap"
project     = "your-project-name"    # ← Change this
environment = "mgmt"
owner       = "your-name"            # ← Change this
```

### Deployment Steps:

#### **Step 1: Navigate to Bootstrap Folder**
```powershell
cd terraform/bootstrap
```

#### **Step 2: Initialize Terraform**
```powershell
terraform init
```

**What this does:**
- Downloads AWS provider plugins
- Prepares Terraform to work with AWS
- Uses **local state** (stored in this folder)

**Expected output:**
```
Terraform has been successfully initialized!
```

#### **Step 3: Review What Will Be Created**
```powershell
terraform plan
```

**What this does:**
- Shows all resources that will be created
- No changes are made yet
- Review carefully!

**Expected output:**
```
Plan: 10 to add, 0 to change, 0 to destroy.
```

#### **Step 4: Create Infrastructure**
```powershell
terraform apply
```

**What this does:**
- Creates all bootstrap resources
- You must type `yes` to confirm

**Expected output:**
```
Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:
kms_eks_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
kms_bootstrap_id = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
bastion_role_arn = "arn:aws:iam::377414509754:role/bastion-nashtech-devops"
```

⏱️ **Time**: ~2-3 minutes

#### **Step 5: Migrate State to S3** (Critical!)

After the first apply, you need to migrate state from local to S3:

```powershell
terraform init -migrate-state
```

**What this does:**
- Moves state file from local folder to S3 bucket
- Future runs will use S3 for state storage
- Enables team collaboration

**When prompted:**
```
Do you want to migrate all workspaces to "s3"?
Type: yes
```

**Expected output:**
```
Terraform has been successfully initialized!
Backend configuration updated!
```

#### **Step 6: Verify State Migration**
```powershell
# List files in S3 bucket
aws s3 ls s3://terraform-boostrap-nashtech-devops-0002/

# Should show: terraform.tfstate
```

---

## 📄 Configuration Files Explained

### 1. `ws_bootstrap.tf` - Main Resources

**Creates:**
- S3 bucket with versioning and encryption
- DynamoDB table for state locking
- Applies standardized tags

**Key sections:**
```hcl
resource "aws_s3_bucket" "bootstrap"              # Storage for state
resource "aws_s3_bucket_versioning" "versioning"  # Version history
resource "aws_dynamodb_table" "bootstrap"         # State locking
```

### 2. `kms.tf` - Encryption Keys

**Creates:**
- Bootstrap KMS key (for S3/DynamoDB)
- EKS KMS key (for Kubernetes secrets)

**Key sections:**
```hcl
resource "aws_kms_key" "terraform-bootstrap"  # Encrypts state
resource "aws_kms_key" "eks_dev"             # Encrypts EKS secrets
```

### 3. `ec2_roles.tf` - IAM Roles

**Creates:**
- Bastion host IAM roles (2 roles)
- Trust policy (who can use the role)
- Permission policy (what the role can do)

**Key sections:**
```hcl
resource "aws_iam_role" "bastion"              # Primary role
resource "aws_iam_role" "bastion_2"            # Backup role
data "aws_iam_policy_document" "trust-policies" # Who can assume
```

### 4. `provider.tf` - Terraform Configuration

**Configures:**
- AWS provider (region, profile)
- Terraform version requirements
- Backend configuration (where state is stored)

**Important:** This file contains the S3 backend config that other folders reference.

### 5. `variables.tf` - Input Variables

**Defines:**
- Project name
- Environment
- Owner
- Resource naming

### 6. `terraform.auto.tfvars` - Variable Values

**Sets actual values** for variables defined in `variables.tf`.

### 7. `outputs.tf` - Exported Values

**Exports:**
- KMS key IDs (used by EKS, RDS)
- IAM role ARNs (used by EC2)

Other Terraform folders reference these outputs using:
```hcl
data "terraform_remote_state" "bootstrap" {
  # ... configuration
}
```

---

## ✅ Verification

### Check What Was Created

#### 1. View Terraform State
```powershell
terraform show
```

#### 2. Check S3 Bucket
```powershell
# List buckets
aws s3 ls | findstr terraform

# Check bucket contents
aws s3 ls s3://terraform-boostrap-nashtech-devops-0002/
```

#### 3. Check DynamoDB Table
```powershell
# List tables
aws dynamodb list-tables --query "TableNames[?contains(@, 'terraform')]"
```

#### 4. Check KMS Keys
```powershell
# List KMS keys
aws kms list-keys

# Describe specific key
aws kms describe-key --key-id <KEY_ID>
```

#### 5. Check IAM Roles
```powershell
# List bastion roles
aws iam list-roles --query "Roles[?contains(RoleName, 'bastion')]"
```

#### 6. View Outputs
```powershell
terraform output
```

**Expected output:**
```
bastion_role_arn = "arn:aws:iam::377414509754:role/bastion-nashtech-devops"
kms_bootstrap_alias_arn = "arn:aws:kms:ap-southeast-1:377414509754:alias/terraform-..."
kms_eks_alias_arn = "arn:aws:kms:ap-southeast-1:377414509754:alias/eks-test"
```

### Check in AWS Console

1. **S3 Console**: https://s3.console.aws.amazon.com/
   - Look for bucket: `terraform-boostrap-nashtech-devops-0002`

2. **DynamoDB Console**: https://console.aws.amazon.com/dynamodb/
   - Look for table: `terraform-boostrap-nashtech-devops`

3. **KMS Console**: https://console.aws.amazon.com/kms/
   - Look for aliases: `terraform-*` and `eks-test`

4. **IAM Console**: https://console.aws.amazon.com/iam/
   - Look for roles: `bastion-nashtech-devops`

---

## 🔧 Troubleshooting

### Issue 1: "Error: No valid credential sources found"

**Problem**: AWS credentials not configured

**Solution**:
```powershell
# Check current credentials
aws sts get-caller-identity

# If error, configure credentials
aws configure --profile datton.nashtech.saml
```

### Issue 2: "Error: Access Denied creating S3 bucket"

**Problem**: Insufficient IAM permissions

**Solution**:
- Ensure your AWS user has `AdministratorAccess` policy
- Check with: `aws iam list-attached-user-policies --user-name YOUR_USERNAME`

### Issue 3: "Error: Bucket already exists"

**Problem**: Bucket name must be globally unique

**Solution**: Change bucket name in `ws_bootstrap.tf`:
```hcl
resource "aws_s3_bucket" "bootstrap" {
  bucket = "terraform-YOUR-UNIQUE-NAME-0002"  # ← Change this
}
```

### Issue 4: "Error: KMS key deletion pending"

**Problem**: Trying to recreate a deleted KMS key

**Solution**: Wait 7-14 days for deletion, or use a different alias

### Issue 5: State file conflicts

**Problem**: Local state exists after S3 migration

**Solution**:
```powershell
# Backup local state
Copy-Item terraform.tfstate terraform.tfstate.backup

# Re-initialize
terraform init -reconfigure
```

### Issue 6: "Error: Backend configuration changed"

**Problem**: Backend configuration was modified

**Solution**:
```powershell
# Reconfigure backend
terraform init -reconfigure
```

---

## ⚠️ Important Notes

### First Time Setup

1. **First run uses LOCAL state**:
   - State file stored in `terraform.tfstate` (local file)
   - After creation, migrate to S3 with `terraform init -migrate-state`

2. **Subsequent runs use S3 state**:
   - State file stored in S3 bucket
   - Shared across team members

### Security Best Practices

1. **Never commit state files** to Git:
   ```
   # Add to .gitignore
   *.tfstate
   *.tfstate.backup
   .terraform/
   ```

2. **Protect KMS keys**:
   - Only grant access to necessary users
   - Use 14-day deletion window (allows recovery)

3. **Rotate credentials** regularly

4. **Review IAM policies** - Currently uses wildcard `*` for S3 actions

### Cost Considerations

**Monthly costs:**
- S3 bucket: ~$0.50 (minimal storage)
- DynamoDB: ~$0.50 (low usage)
- KMS keys: $1/key = $2
- Data transfer: Minimal

**Total: ~$3/month**

### State Management

- **Never manually edit** state files
- Use `terraform state` commands for state modifications
- Keep backups of state files
- State contains sensitive data (encrypted in S3)

### Destroy Warning

⚠️ **DO NOT destroy bootstrap until ALL other infrastructure is destroyed!**

Other folders depend on bootstrap resources. Destroy order:
1. ECR
2. RDS
3. EC2
4. EKS
5. Networks
6. **Bootstrap (LAST!)**

To destroy:
```powershell
terraform destroy
# Type: yes
```

---

## 📖 Understanding Key Concepts

### What is Terraform State?

**State** = A file that records what infrastructure Terraform created

**Contains:**
- Resource IDs
- IP addresses
- Passwords (sensitive!)
- Dependencies between resources

**Why important:**
- Terraform uses state to know what exists
- Tracks changes over time
- Enables team collaboration

### What is State Locking?

**Locking** = Prevents two people from running Terraform simultaneously

**Without locking:**
```
Person A: terraform apply (creates EC2)
Person B: terraform apply (creates same EC2)
Result: Conflict! Corrupted state!
```

**With locking (DynamoDB):**
```
Person A: terraform apply (acquires lock)
Person B: terraform apply (waits for lock)
Result: Safe! No conflicts!
```

### What is KMS?

**KMS** = Key Management Service (encryption key storage)

**How it works:**
1. KMS stores encryption key securely
2. S3 asks KMS to encrypt data before storing
3. Only authorized users can decrypt

**Analogy:**
- KMS = Bank vault with master key
- S3 = Safe deposit box
- Your data = Valuables

### What is IAM Role?

**IAM Role** = A set of permissions that AWS resources can use

**For EC2:**
- Without role: Must store AWS credentials on server (insecure)
- With role: AWS provides temporary credentials automatically (secure)

---

## 🎓 Next Steps

After bootstrap is successfully deployed:

1. ✅ Verify all resources in AWS Console
2. ✅ Confirm state is in S3
3. ✅ Test DynamoDB locking by running `terraform plan` twice simultaneously
4. ✅ Proceed to **[Networks](../networks/README.md)** deployment

---

## 📞 Need Help?

- Check main [README](../../README.md) for general guidance
- Review [Terraform documentation](https://www.terraform.io/docs)
- Check [AWS documentation](https://docs.aws.amazon.com/)

---

**Last Updated**: December 2025  
**Terraform Version**: 1.3.0  
**AWS Provider Version**: 4.67.0
