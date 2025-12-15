# EC2 - Bastion Hosts Guide

## 📋 Table of Contents
- [Overview](#overview)
- [What is a Bastion Host?](#what-is-a-bastion-host)
- [What Gets Created](#what-gets-created)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [Configuration Files Explained](#configuration-files-explained)
- [Accessing Bastion Hosts](#accessing-bastion-hosts)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Important Notes](#important-notes)

---

## 🎯 Overview

The **ec2** folder creates **Bastion Hosts** - secure jump servers that provide SSH access to your private infrastructure (EKS nodes, RDS databases).

**Think of it as the secure entrance gate to your private network.**

---

## 🔍 What is a Bastion Host?

### For Beginners:

**Bastion Host** = A hardened server in a public subnet that you use to access private servers

**Analogy:**
- **Physical World**: Security checkpoint at a building entrance
  - You enter through the checkpoint
  - From there, access internal offices
  
- **AWS**: Bastion host in public subnet
  - You SSH to bastion
  - From bastion, SSH to private EC2/EKS nodes

### Why Use a Bastion?

**Without Bastion:**
```
Internet → Private EC2 ✗ (blocked by security groups)
```

**With Bastion:**
```
Internet → Bastion Host (public) → Private EC2 ✓
```

**Security benefits:**
1. Single entry point (easier to audit)
2. Private instances don't need public IPs
3. Can enforce MFA on bastion
4. Centralized logging of access

---

## 📦 What Gets Created

### Bastion Host Configuration 1

```
Name: bastion-host
Count: 2 instances
AMI: Ubuntu 22.04 (ami-0b13630a979679b27)
Instance Type: t3a.micro (2 vCPU, 1 GB RAM)
Storage:
  - Root volume: 10 GB
  - No additional EBS volumes

Networking:
  - VPC: dev VPC
  - Subnet: dev-public-subnet-0 (AZ: ap-southeast-1a)
  - Public IP: Yes (auto-assigned)
  - Security Group: bastion-host (SSH port 22)

IAM:
  - Role: bastion-sd5046-aws-infrastructure
  - Profile: bastion-host-1-profile
  - Permissions: S3 access to bootstrap bucket

SSH Key:
  - Name: bastion-host.pem
  - Location: ./terraform/ec2/
```

### Bastion Host Configuration 2

```
Name: bastion-host-2
Count: 2 instances
Instance Type: t3a.micro
Storage:
  - Root volume: 10 GB
  - Additional EBS volumes: 2 x 20 GB each

Networking:
  - Subnet: dev-public-subnet-1 (AZ: ap-southeast-1b)
  - Public IP: Yes
  - Security Group: bastion-host

IAM:
  - Role: bastion-sd5046-aws-infrastructure-0002
  - Profile: bastion-host-2-profile

SSH Key:
  - Name: bastion-host-2.pem
  - Location: ./terraform/ec2/
```

### Total Resources Created

```
EC2 Instances: 4 total (2 + 2)
EBS Volumes: 4 additional (for bastion-host-2)
Security Groups: Reuses from network module
SSH Key Pairs: 2 (auto-generated)
IAM Instance Profiles: 2
```

---

## 🏗️ Architecture

### Visual Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet                                 │
└────────────────────────┬────────────────────────────────────────┘
                         │ SSH (Port 22)
                         │
┌────────────────────────┴────────────────────────────────────────┐
│                     Public Subnets                               │
│                                                                   │
│  ┌─────────────────────────────┐  ┌─────────────────────────┐  │
│  │  AZ-1a (10.0.0.0/20)        │  │  AZ-1b (10.0.16.0/20)   │  │
│  │                              │  │                          │  │
│  │  ┌─────────────────────┐    │  │  ┌─────────────────┐    │  │
│  │  │  Bastion Host 1A    │    │  │  │ Bastion Host 2A │    │  │
│  │  │  (t3a.micro)        │    │  │  │  (t3a.micro)    │    │  │
│  │  │  Public IP: x.x.x.x │    │  │  │  Public IP: y.y │    │  │
│  │  └─────────────────────┘    │  │  └─────────────────┘    │  │
│  │                              │  │                          │  │
│  │  ┌─────────────────────┐    │  │  ┌─────────────────┐    │  │
│  │  │  Bastion Host 1B    │    │  │  │ Bastion Host 2B │    │  │
│  │  │  (t3a.micro)        │    │  │  │  (t3a.micro)    │    │  │
│  │  │  Public IP: x.x.x.y │    │  │  │  Public IP: y.y │    │  │
│  │  └─────────────────────┘    │  │  └─────────────────┘    │  │
│  └─────────────────────────────┘  └─────────────────────────┘  │
└───────────────────────┬─────────────────────────────────────────┘
                        │ SSH (via bastion)
                        │
┌───────────────────────┴─────────────────────────────────────────┐
│                    Private Subnets                               │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  EKS Worker Nodes, RDS Databases, Private EC2               ││
│  │  (Not directly accessible from internet)                     ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘

Access Flow:
  Your Computer → Bastion (Public IP) → Private Resources
```

### High Availability

- **2 Availability Zones** - Bastions in AZ-1a and AZ-1b
- **4 Total Instances** - Redundancy if one fails
- **Auto-scaling capable** - Can add more if needed

---

## 📚 Prerequisites

### 1. Previous Steps Completed
✅ **Bootstrap** - Deployed (provides IAM roles)
✅ **Networks** - Deployed (provides VPC, subnets, security groups)

**Verify:**
```powershell
# Check bootstrap
cd ../bootstrap
terraform output bastion_role_arn

# Check networks  
cd ../networks
terraform output dev-public-subnet-0
terraform output security-groups
```

### 2. Software Requirements
- ✅ **SSH client** (PuTTY on Windows or OpenSSH)
- ✅ **AWS CLI** configured
- ✅ **Terraform** 1.3.0

---

## 🚀 Step-by-Step Deployment

### Update Configuration

#### 1. Update `provider.tf`
```hcl
provider "aws" {
  region  = "ap-southeast-1"
  profile = "YOUR_AWS_PROFILE"  # ← Change this
}
```

#### 2. Update `terraform.tfvars`
```hcl
project     = "your-project-name"  # ← Change this
environment = "dev"
owner       = "your-name"          # ← Change this
```

#### 3. Customize Instances (Optional)

Edit `locals.tf` to change:
- Instance count
- Instance types
- Storage size
- Availability zones

### Deployment Steps

#### **Step 1: Navigate to EC2 Folder**
```powershell
cd terraform/ec2
```

#### **Step 2: Initialize Terraform**
```powershell
terraform init
```

#### **Step 3: Review Plan**
```powershell
terraform plan
```

**Expected resources:**
- 4 EC2 instances
- 4 EBS volumes (for bastion-host-2)
- 2 SSH key pairs
- 2 IAM instance profiles

**Expected output:**
```
Plan: 10 to add, 0 to change, 0 to destroy.
```

#### **Step 4: Apply Configuration**
```powershell
terraform apply
```

Type `yes` when prompted.

⏱️ **Time**: ~2-3 minutes

**Expected output:**
```
Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:
bastion_host_public_ips = [
  "13.229.123.45",
  "13.229.123.46",
  "18.139.234.56",
  "18.139.234.57",
]
```

#### **Step 5: Secure SSH Keys**

SSH private keys are created in current directory:

```powershell
# List generated keys
ls *.pem

# Set proper permissions (important!)
icacls bastion-host.pem /inheritance:r
icacls bastion-host.pem /grant:r "$($env:USERNAME):(R)"

icacls bastion-host-2.pem /inheritance:r
icacls bastion-host-2.pem /grant:r "$($env:USERNAME):(R)"
```

**⚠️ Never commit .pem files to Git!**

---

## 📄 Configuration Files Explained

### 1. `main.tf` - EC2 Module Call

**Creates bastion hosts using EC2 module:**
```hcl
module "bastion-host" {
  source = "../modules/ec2"
  
  name          = "Bastion-host"
  ec2_instances = local.bastion_hosts
  
  generate_ssh_key_pair = true  # Auto-generate SSH keys
  
  owner       = var.owner
  project     = var.project
  environment = var.environment
}
```

### 2. `locals.tf` - Instance Configuration

**Defines two bastion configurations:**

**Configuration 1 (bastion_host_1):**
```hcl
bastion_host_1 = {
  name = "bastion-host"
  ami  = "ami-0030e4319cbf4dbf2"  # Ubuntu 22.04
  instance-type = "t3a.micro"
  
  instance-count = 2  # Creates 2 instances
  
  # Networking
  vpc-id    = data.terraform_remote_state.network.outputs.vpc.id
  subnet_id = data.terraform_remote_state.network.outputs.dev-public-subnet-0.id
  associate_public_ip_address = true
  
  # Storage
  root-volume-size = 10     # GB
  ebs-volume-count = 0      # No additional volumes
  
  # Security
  security-group-ids = data.terraform_remote_state.network.outputs.security-groups.bastion-host
  
  # IAM
  iam-role-default-name = data.terraform_remote_state.bootstrap.outputs.bastion_role_name
  
  # SSH
  generate-ssh-key-pair = true
  ssh-key-pair-path = "./"
}
```

**Configuration 2 (bastion_host_2):**
- Similar to config 1
- Different subnet (public-subnet-1)
- Has 2 additional EBS volumes (20 GB each)
- Different IAM role (bastion-sd5046-aws-infrastructure-0002)

### 3. `provider.tf` - Terraform Configuration

**Configures:**
- AWS provider
- S3 backend
- Remote state references to bootstrap and network

### 4. `variables.tf` - Input Variables

**Defines:**
- Project name
- Environment
- Owner

### 5. `terraform.tfvars` - Variable Values

**Sets actual values** for the variables

### 6. `outputs.tf` - Exported Values (if exists)

**Would export:**
- Instance IDs
- Public IPs
- Private IPs

---

## 🔑 Accessing Bastion Hosts

### Get Public IP Addresses

```powershell
# From Terraform output
terraform output

# Or from AWS CLI
aws ec2 describe-instances `
  --filters "Name=tag:Name,Values=bastion-host*" `
  --query "Reservations[*].Instances[*].[InstanceId,PublicIpAddress,State.Name]" `
  --output table
```

### SSH to Bastion (Windows)

#### **Using PowerShell/OpenSSH:**

```powershell
# Get public IP from terraform output
$BASTION_IP = "13.229.123.45"  # Replace with actual IP

# SSH to bastion
ssh -i bastion-host.pem ubuntu@$BASTION_IP
```

#### **Using PuTTY:**

1. **Convert .pem to .ppk:**
   - Open PuTTYgen
   - Load `bastion-host.pem`
   - Save as `bastion-host.ppk`

2. **Configure PuTTY:**
   - Host: `ubuntu@<bastion-ip>`
   - Connection → SSH → Auth → Private key: Browse to `.ppk` file
   - Click Open

### SSH to Bastion (Linux/Mac)

```bash
chmod 400 bastion-host.pem
ssh -i bastion-host.pem ubuntu@<bastion-ip>
```

### First Login

```bash
# Update packages
sudo apt update

# Install useful tools
sudo apt install -y vim htop

# Test AWS CLI (should work with IAM role)
aws s3 ls s3://terraform-boostrap-sd5046-aws-infrastructure-0002/
```

### SSH to Private Resources via Bastion

**Method 1: SSH ProxyJump (Direct)**

```powershell
# SSH to EKS node via bastion
ssh -i eks-key-dev.pem `
  -o ProxyJump=ubuntu@<bastion-ip> `
  ec2-user@<private-node-ip>
```

**Method 2: SSH Agent Forwarding**

```powershell
# Start SSH agent
ssh-agent

# Add key
ssh-add bastion-host.pem

# SSH with agent forwarding
ssh -A ubuntu@<bastion-ip>

# Now from bastion, SSH to private instance
ssh ec2-user@<private-node-ip>
```

**Method 3: Copy Key to Bastion (Less Secure)**

```powershell
# Copy EKS key to bastion
scp -i bastion-host.pem eks-key-dev.pem ubuntu@<bastion-ip>:~/

# SSH to bastion
ssh -i bastion-host.pem ubuntu@<bastion-ip>

# From bastion, SSH to private instance
chmod 400 eks-key-dev.pem
ssh -i eks-key-dev.pem ec2-user@<private-node-ip>
```

---

## ✅ Verification

### Check Terraform State

```powershell
terraform show
```

### Verify Instances Running

```powershell
# List instances
aws ec2 describe-instances `
  --filters "Name=tag:Name,Values=bastion-host*" `
  --query "Reservations[*].Instances[*].[InstanceId,PublicIpAddress,PrivateIpAddress,State.Name]" `
  --output table
```

**Expected output:**
```
------------------------------------------------------------
|                   DescribeInstances                      |
+---------------------+----------------+------------------+----------+
|  i-0abc123def456789 |  13.229.123.45 | 10.0.1.123      | running |
|  i-0def456ghi789abc |  13.229.123.46 | 10.0.1.234      | running |
|  i-0ghi789jkl012def |  18.139.234.56 | 10.0.17.123     | running |
|  i-0jkl012mno345ghi |  18.139.234.57 | 10.0.17.234     | running |
+---------------------+----------------+------------------+----------+
```

### Test SSH Access

```powershell
# Test SSH to first bastion
ssh -i bastion-host.pem ubuntu@<bastion-ip-1> "echo 'Connection successful!'"
```

### Verify IAM Role

```powershell
# SSH to bastion
ssh -i bastion-host.pem ubuntu@<bastion-ip>

# Check IAM role
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/

# Should show: bastion-sd5046-aws-infrastructure

# Test S3 access
aws s3 ls s3://terraform-boostrap-sd5046-aws-infrastructure-0002/
```

### Verify Security Group

```powershell
# Check security group rules
aws ec2 describe-security-groups `
  --filters "Name=group-name,Values=*bastion*"
```

**Should allow:**
- Inbound: SSH (port 22) from 0.0.0.0/0
- Outbound: All traffic

---

## 🔧 Troubleshooting

### Issue 1: "Connection timeout" when SSH

**Problem**: Security group or network issue

**Check:**
1. Security group allows your IP:
   ```powershell
   # Get your public IP
   (Invoke-WebRequest -Uri "https://api.ipify.org").Content
   
   # Check security group
   aws ec2 describe-security-groups --group-ids <sg-id>
   ```

2. Instance has public IP
3. Internet Gateway attached to VPC
4. Route table configured correctly

### Issue 2: "Permission denied (publickey)"

**Problem**: Wrong SSH key or permissions

**Solution:**
```powershell
# Windows: Set correct permissions
icacls bastion-host.pem /inheritance:r
icacls bastion-host.pem /grant:r "$($env:USERNAME):(R)"

# Use correct username (Ubuntu AMI uses 'ubuntu')
ssh -i bastion-host.pem ubuntu@<bastion-ip>
```

### Issue 3: Can't access private resources from bastion

**Problem**: Network routing or security group issue

**Check:**
1. Bastion in public subnet
2. Private resources in private subnet
3. Security groups allow traffic from bastion
4. Correct SSH key for private resource

**Debug:**
```bash
# From bastion, test connectivity
ping <private-ip>
telnet <private-ip> 22
```

### Issue 4: IAM role not working

**Problem**: Instance profile not attached

**Solution:**
```powershell
# Check instance profile
aws ec2 describe-instances --instance-ids <instance-id> `
  --query "Reservations[*].Instances[*].IamInstanceProfile"

# If missing, attach manually in console or re-apply terraform
terraform apply -replace="module.bastion-host.aws_instance.ec2[0]"
```

### Issue 5: EBS volumes not attached

**Problem**: Only applies to bastion-host-2

**Check:**
```bash
# SSH to bastion-host-2
ssh -i bastion-host-2.pem ubuntu@<bastion-ip>

# List block devices
lsblk

# Should show additional volumes (xvdf, xvdg)
```

**Mount additional volumes:**
```bash
# Format volume
sudo mkfs -t ext4 /dev/xvdf

# Mount volume
sudo mkdir /data
sudo mount /dev/xvdf /data
```

### Issue 6: Too many instances (cost concerns)

**Problem**: 4 instances might be excessive for dev

**Solution:** Reduce instance count in `locals.tf`:
```hcl
bastion_host_1 = {
  instance-count = 1  # ← Reduce from 2
}

bastion_host_2 = {
  instance-count = 0  # ← Disable completely
}
```

---

## ⚠️ Important Notes

### Cost Considerations

**Monthly costs (4 instances):**
- EC2 (4 x t3a.micro): ~$6-8/month
- EBS volumes (4 x 20 GB): ~$3/month
- Data transfer: Minimal

**Total: ~$9-11/month**

**Cost savings:**
- Reduce to 1 bastion for dev
- Stop instances when not in use
- Use Systems Manager Session Manager instead (no bastion needed)

### Security Best Practices

1. **Restrict SSH access by IP:**
   ```hcl
   # In networks/locals.tf
   bastion-host = {
     ingress = {
       cidr_blocks = "YOUR_IP/32"  # ← Your IP only
     }
   }
   ```

2. **Enable SSH key rotation**
3. **Use MFA for SSH** (Google Authenticator)
4. **Monitor SSH logs** in CloudWatch
5. **Disable password authentication** (key-only)

### Alternative: AWS Systems Manager Session Manager

**Instead of bastion hosts:**

**Pros:**
- No bastion costs
- No SSH keys to manage
- Better audit logging
- Access via AWS Console or CLI

**Setup:**
```hcl
# Add to EC2 IAM role
iam_role_additional_policies = [
  "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
]
```

**Access:**
```powershell
aws ssm start-session --target <instance-id>
```

### SSH Key Management

**⚠️ Important:**
- **Never commit .pem files** to Git
- Store keys securely (password manager)
- Rotate keys regularly
- Use separate keys for different environments

**Add to .gitignore:**
```
*.pem
*.ppk
```

### High Availability

**Current setup:**
- 4 bastions across 2 AZs
- If 1 AZ fails, still have 2 bastions in other AZ

**For production:**
- Consider Auto Scaling Group
- Use Application Load Balancer for distribution
- Or use AWS Systems Manager (no HA needed)

### Destroy Considerations

**Before destroying:**
- Ensure no active SSH sessions
- Backup any data on EBS volumes
- Document any custom configurations

```powershell
terraform destroy
```

---

## 🎓 Understanding Bastion Concepts

### What is a Jump Server?

**Jump Server** = Another name for bastion host

**Purpose:**
- Intermediary between internet and private network
- Hardened and monitored
- Single point of access control

### Bastion vs VPN

| Feature | Bastion Host | VPN |
|---------|-------------|-----|
| **Use Case** | Server access | Network access |
| **Scope** | Single server | All resources |
| **Setup** | Simple (1 EC2) | Complex (VPN gateway) |
| **Cost** | Low (~$10/month) | Medium (~$30/month) |
| **Security** | Good | Better |

### Bastion vs Systems Manager

| Feature | Bastion | Session Manager |
|---------|---------|----------------|
| **Cost** | EC2 charges | Free |
| **Setup** | Terraform | IAM policy only |
| **Access** | SSH client | AWS CLI/Console |
| **Audit** | Manual logs | Automatic |
| **Public IP** | Required | Not required |

**Recommendation:** Use Session Manager for production

---

## 🎓 Next Steps

After EC2 deployment:

1. ✅ Test SSH access to all bastions
2. ✅ Verify IAM role permissions
3. ✅ Test accessing EKS nodes via bastion
4. ✅ Set up monitoring and alerting
5. ✅ Proceed to **[RDS](../rds/README.md)** deployment

---

## 📞 Need Help?

- Check main [README](../../README.md)
- Review [EC2 documentation](https://docs.aws.amazon.com/ec2/)
- Check [SSH troubleshooting guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/TroubleshootingInstancesConnecting.html)

---

**Last Updated**: December 2025  
**Terraform Version**: 1.3.0  
**AWS Provider Version**: 4.67.0
