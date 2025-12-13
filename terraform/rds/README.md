# RDS - Database Guide

## 📋 Table of Contents
- [Overview](#overview)
- [What is RDS?](#what-is-rds)
- [What Gets Created](#what-gets-created)
- [Database Architecture](#database-architecture)
- [Prerequisites](#prerequisites)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [Configuration Files Explained](#configuration-files-explained)
- [Accessing Databases](#accessing-databases)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Important Notes](#important-notes)

---

## 🎯 Overview

The **rds** folder creates **Amazon RDS (Relational Database Service)** instances - managed MySQL databases for your applications.

**Think of it as creating reliable, managed database servers without worrying about backups, patches, or hardware.**

---

## 🔍 What is RDS?

### For Beginners:

**RDS** = Amazon's managed database service

**Database** = Organized storage for application data (users, products, orders, etc.)

**Managed** = AWS handles:
- Automatic backups
- Software patching
- Hardware maintenance
- High availability
- Monitoring

**Analogy:**
- **Self-hosted DB**: You own and maintain the database server
- **RDS**: You rent a database, AWS maintains everything

### Why Use RDS?

1. **Automated backups** - Daily snapshots
2. **Easy scaling** - Upgrade size with one click
3. **High availability** - Multi-AZ for redundancy
4. **Security** - Encrypted storage and network isolation
5. **Monitoring** - Built-in CloudWatch metrics

---

## 📦 What Gets Created

### Database 1: default-db

```
Database Name: testdb
Engine: MySQL 5.7
Instance Class: db.t3.micro (1 vCPU, 1 GB RAM)
Storage: 20 GB

Network:
  - VPC: dev VPC
  - Subnet Group: network-db-subnet-group-dev
  - Subnets: Private subnets 0 and 1
  - Security Group: default-rds
  - Public Access: No (private only)

Credentials:
  - Username: admin (default)
  - Password: From variables (you set this)

Backup:
  - Automated backups: 7 days retention
  - Backup window: AWS chooses optimal time
  - Maintenance window: AWS chooses optimal time

Encryption:
  - At rest: Yes (EBS encryption)
  - In transit: SSL/TLS supported
```

### Database 2: another-db

```
Database Name: testdb2
Engine: MySQL 5.7
Instance Class: db.t3.micro
Storage: 20 GB

Network: Same as default-db
Credentials: Separate password
```

### Supporting Resources

```
DB Subnet Group: network-db-subnet-group-dev
  - Contains private subnet 0 and 1
  - Required for RDS Multi-AZ
  - Created by network module

Security Group: default-rds
  - Created by network module
  - Allows MySQL port 3306 from VPC
```

---

## 🏗️ Database Architecture

### Visual Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         VPC (10.0.0.0/16)                        │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Public Subnets                            │ │
│  │                                                               │ │
│  │  ┌──────────────┐         ┌──────────────┐                  │ │
│  │  │   Bastion    │         │   Bastion    │                  │ │
│  │  │   Host       │         │   Host       │                  │ │
│  │  └──────┬───────┘         └──────────────┘                  │ │
│  └─────────┼──────────────────────────────────────────────────┘ │
│            │ MySQL Client                                        │
│            │                                                     │
│  ┌─────────┼──────────────────────────────────────────────────┐ │
│  │         │       Private Subnets (DB Tier)                   │ │
│  │         ▼                                                    │ │
│  │  ┌──────────────┐         ┌──────────────┐                  │ │
│  │  │   AZ-1a      │         │   AZ-1b      │                  │ │
│  │  │              │         │              │                  │ │
│  │  │ ┌──────────┐ │         │ ┌──────────┐ │                  │ │
│  │  │ │  RDS 1   │ │         │ │  RDS 1   │ │                  │ │
│  │  │ │ (Primary)│─┼─────────┼▶│(Standby) │ │ Multi-AZ         │ │
│  │  │ │ testdb   │ │         │ │ (backup) │ │ (Optional)       │ │
│  │  │ └──────────┘ │         │ └──────────┘ │                  │ │
│  │  │              │         │              │                  │ │
│  │  │ ┌──────────┐ │         │ ┌──────────┐ │                  │ │
│  │  │ │  RDS 2   │ │         │ │  RDS 2   │ │                  │ │
│  │  │ │ (Primary)│─┼─────────┼▶│(Standby) │ │ Multi-AZ         │ │
│  │  │ │ testdb2  │ │         │ │ (backup) │ │ (Optional)       │ │
│  │  │ └──────────┘ │         │ └──────────┘ │                  │ │
│  │  └──────────────┘         └──────────────┘                  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                EKS Nodes (Private Subnets)                   │ │
│  │                                                               │ │
│  │  Application Pods connect to RDS via DNS endpoint           │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘

Access Methods:
  1. Bastion → RDS (for administration)
  2. EKS Pods → RDS (for application access)
  3. EC2 in VPC → RDS
  
Blocked:
  ✗ Direct internet access to RDS
```

### High Availability (Optional)

**Multi-AZ deployment:**
- Primary database in AZ-1a
- Standby replica in AZ-1b
- Automatic failover if primary fails
- **Not enabled by default** (costs 2x)

---

## 📚 Prerequisites

### 1. Previous Steps Completed
✅ **Bootstrap** - Deployed
✅ **Networks** - Deployed (provides VPC, subnets, security groups)

**Verify:**
```powershell
cd ../networks
terraform output db-subnet-group
terraform output security-groups
```

### 2. Database Password

**⚠️ IMPORTANT**: You must set database passwords!

**Create a file**: `terraform.tfvars`

```powershell
# In terraform/rds/ folder
New-Item -Path "terraform.tfvars" -ItemType File
```

**Add passwords** (never commit this file!):
```hcl
default_db_password = "YourStrongPassword123!"
another_db_password = "AnotherStrongPass456!"
```

**Password requirements:**
- Minimum 8 characters
- Contains letters and numbers
- Special characters recommended

### 3. Software Requirements
- ✅ **MySQL client** (for testing connections)
- ✅ **AWS CLI** configured
- ✅ **Terraform** 1.3.0

**Install MySQL client:**
```powershell
choco install mysql
```

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

#### 2. Create `terraform.tfvars`

**⚠️ CRITICAL:** Set your database passwords!

```hcl
project     = "your-project-name"
environment = "dev"
owner       = "your-name"

# Database passwords (REQUIRED!)
default_db_password = "ChangeMe123!"  # ← Set strong password
another_db_password = "ChangeMe456!"  # ← Set strong password
```

#### 3. Update `.gitignore`

**Ensure passwords aren't committed:**

```powershell
# In repository root
Add-Content -Path ".gitignore" -Value "terraform/rds/terraform.tfvars"
```

#### 4. Customize Database Configuration (Optional)

Edit `locals.tf` to change:
- Database names
- Instance sizes
- Storage sizes
- MySQL versions

### Deployment Steps

#### **Step 1: Navigate to RDS Folder**
```powershell
cd terraform/rds
```

#### **Step 2: Initialize Terraform**
```powershell
terraform init
```

#### **Step 3: Review Plan**
```powershell
terraform plan
```

**Check for:**
- 2 RDS instances
- Correct subnets (private)
- Security groups configured

**Expected output:**
```
Plan: 2 to add, 0 to change, 0 to destroy.
```

#### **Step 4: Apply Configuration**
```powershell
terraform apply
```

Type `yes` when prompted.

⏱️ **Time**: 5-10 minutes (RDS takes time to provision)

**You will see:**
```
module.rds.aws_db_instance.rds["default-db"]: Creating...
module.rds.aws_db_instance.rds["default-db"]: Still creating... [2m0s elapsed]
module.rds.aws_db_instance.rds["default-db"]: Still creating... [4m0s elapsed]
...
```

**Expected output:**
```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:
rds_endpoints = {
  "default-db" = "testdb.xxxxxxxxxxxx.ap-southeast-1.rds.amazonaws.com:3306"
  "another-db" = "testdb2.xxxxxxxxxxxx.ap-southeast-1.rds.amazonaws.com:3306"
}
```

---

## 📄 Configuration Files Explained

### 1. `main.tf` - RDS Module Call

**Creates databases using RDS module:**
```hcl
module "rds" {
  source = "../modules/rds"
  
  rds = local.rds  # Database configurations from locals.tf
  
  name        = "rds-nashtech-devops-dev"
  owner       = var.owner
  project     = var.project
  environment = var.environment
}
```

### 2. `locals.tf` - Database Configurations

**Defines two databases:**

```hcl
locals {
  rds = {
    default-db = {
      db_name                = "testdb"
      db_subnet_group_name   = data.terraform_remote_state.network.outputs.db-subnet-group.name
      vpc_security_group_ids = [data.terraform_remote_state.network.outputs.security-groups.default-rds]
      
      allocated_storage = "20"        # GB
      engine           = "mysql"
      engine_version   = "5.7"
      instance_class   = "db.t3.micro"
      
      password = var.default_db_password  # From terraform.tfvars
    }
    
    another-db = {
      db_name   = "testdb2"
      # ... similar configuration
      password = var.another_db_password
    }
  }
}
```

**Key parameters:**
- `db_name` - Initial database name
- `engine` - mysql, postgres, mariadb, etc.
- `engine_version` - Database version
- `instance_class` - Server size (CPU/RAM)
- `allocated_storage` - Disk size in GB
- `password` - Master password (from variables)

### 3. `provider.tf` - Terraform Configuration

**Configures:**
- AWS provider
- S3 backend
- Remote state references

### 4. `variables.tf` - Input Variables

**Defines:**
```hcl
variable "default_db_password" {
  type        = string
  description = "Password for default-db"
  sensitive   = true  # Won't show in logs
}

variable "another_db_password" {
  type        = string
  description = "Password for another-db"
  sensitive   = true
}
```

### 5. `terraform.tfvars` - Variable Values (You Create This)

**Must contain:**
```hcl
default_db_password = "your-strong-password"
another_db_password = "another-strong-password"
```

---

## 🔑 Accessing Databases

### Get Database Endpoints

```powershell
# From Terraform output
terraform output

# Or from AWS CLI
aws rds describe-db-instances `
  --query "DBInstances[*].[DBInstanceIdentifier,Endpoint.Address,Endpoint.Port]" `
  --output table
```

**Example endpoint:**
```
testdb.c1a2b3c4d5e6.ap-southeast-1.rds.amazonaws.com:3306
```

### Method 1: From Bastion Host (Recommended)

**Step 1: SSH to Bastion**
```powershell
ssh -i ../ec2/bastion-host.pem ubuntu@<bastion-ip>
```

**Step 2: Install MySQL Client**
```bash
sudo apt update
sudo apt install -y mysql-client
```

**Step 3: Connect to Database**
```bash
# Replace with your endpoint
DB_ENDPOINT="testdb.xxxxxxxxxxxx.ap-southeast-1.rds.amazonaws.com"
DB_PASSWORD="YourStrongPassword123!"

mysql -h $DB_ENDPOINT -u admin -p$DB_PASSWORD
```

**Step 4: Test Connection**
```sql
-- List databases
SHOW DATABASES;

-- Use testdb
USE testdb;

-- Create a test table
CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100),
  email VARCHAR(100)
);

-- Insert test data
INSERT INTO users (name, email) VALUES ('John Doe', 'john@example.com');

-- Query data
SELECT * FROM users;

-- Exit
EXIT;
```

### Method 2: From EKS Pod

**Create MySQL client pod:**
```powershell
kubectl run mysql-client --image=mysql:5.7 -it --rm --restart=Never -- /bin/bash
```

**Inside pod:**
```bash
mysql -h testdb.xxxxxxxxxxxx.ap-southeast-1.rds.amazonaws.com -u admin -p
# Enter password when prompted
```

### Method 3: Port Forwarding via Bastion

**For GUI tools (MySQL Workbench, etc.):**

```powershell
# Create SSH tunnel
ssh -i ../ec2/bastion-host.pem `
  -L 3306:testdb.xxxxxxxxxxxx.ap-southeast-1.rds.amazonaws.com:3306 `
  ubuntu@<bastion-ip>
```

**Then connect locally:**
- Host: `localhost`
- Port: `3306`
- Username: `admin`
- Password: Your password

---

## ✅ Verification

### Check Terraform Outputs

```powershell
terraform output
```

**Expected output:**
```
rds_endpoints = {
  "another-db" = "testdb2.xxxxxxxxxxxx.ap-southeast-1.rds.amazonaws.com:3306"
  "default-db" = "testdb.xxxxxxxxxxxx.ap-southeast-1.rds.amazonaws.com:3306"
}
```

### Verify in AWS Console

**RDS Console**: https://console.aws.amazon.com/rds/

**Check:**
1. **Databases tab**: 2 databases (testdb, testdb2)
2. **Status**: Available
3. **Engine**: MySQL 5.7
4. **Size**: db.t3.micro
5. **VPC**: dev VPC
6. **Subnet Group**: network-db-subnet-group-dev
7. **Public Access**: No
8. **Encryption**: Enabled

### Using AWS CLI

**List databases:**
```powershell
aws rds describe-db-instances `
  --query "DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Engine,DBInstanceClass]" `
  --output table
```

**Get endpoint:**
```powershell
aws rds describe-db-instances `
  --db-instance-identifier <db-id> `
  --query "DBInstances[0].Endpoint"
```

**Check backups:**
```powershell
aws rds describe-db-snapshots `
  --db-instance-identifier <db-id>
```

### Test Connection

**From bastion:**
```bash
# Test connectivity
nc -zv testdb.xxxxxxxxxxxx.ap-southeast-1.rds.amazonaws.com 3306

# Expected: Connection to ... 3306 port [tcp/mysql] succeeded!

# Test MySQL login
mysql -h testdb.xxxxxxxxxxxx.ap-southeast-1.rds.amazonaws.com -u admin -p

# Run a query
mysql -h <endpoint> -u admin -p -e "SHOW DATABASES;"
```

---

## 🔧 Troubleshooting

### Issue 1: "Can't connect to MySQL server"

**Problem**: Network or security group issue

**Check:**
1. **Security group** allows port 3306 from your source
2. **DB is in private subnet** (needs bastion or VPC connection)
3. **Endpoint is correct**

**Debug:**
```bash
# From bastion, test port
nc -zv <rds-endpoint> 3306

# Check security group
aws ec2 describe-security-groups --group-ids <sg-id>
```

### Issue 2: "Access denied for user 'admin'"

**Problem**: Wrong password

**Solution:**
- Verify password in `terraform.tfvars`
- Reset password in AWS Console if needed

**Reset password:**
```powershell
aws rds modify-db-instance `
  --db-instance-identifier <db-id> `
  --master-user-password NewPassword123! `
  --apply-immediately
```

### Issue 3: "Error creating DB Instance: ... already exists"

**Problem**: Database with same name exists

**Solution:**
- Change database identifier in `locals.tf`
- Or delete existing database

### Issue 4: Database creation timeout

**Problem**: RDS taking too long (>15 minutes)

**Check:**
- AWS service health
- Subnet configuration
- VPC settings

**Solution:** Usually just needs patience, can take 10-15 minutes

### Issue 5: "Insufficient DB instance capacity"

**Problem**: AWS region doesn't have capacity

**Solution:**
- Try different AZ
- Try different instance class
- Try different time of day

### Issue 6: High database costs

**Problem**: RDS costs more than expected

**Check:**
- Multi-AZ enabled? (doubles cost)
- Instance size too large?
- Unnecessary databases?

**Reduce costs:**
```hcl
# In locals.tf
instance_class = "db.t3.micro"  # Smallest size
multi_az = false                # Single AZ (dev only!)
```

---

## ⚠️ Important Notes

### Cost Considerations

**Monthly costs (2 databases, single-AZ):**
- RDS instances (2 x db.t3.micro): ~$15-20/month
- Storage (2 x 20 GB): ~$5/month
- Backups (within allocated storage): Free
- Data transfer: Minimal

**Total: ~$20-25/month**

**Multi-AZ costs double!**
- Use Multi-AZ only for production
- Dev/test can use single-AZ

**Cost savings:**
- Use smaller instance (t3.micro vs t3.small)
- Reduce storage size if possible
- Delete unused databases
- Stop database when not in use (manually in console)

### Security Best Practices

1. **Strong passwords**: Use password manager
2. **Never commit passwords** to Git
3. **Use Secrets Manager** for production:
   ```hcl
   # Instead of password in tfvars
   password = data.aws_secretsmanager_secret_version.db_password.secret_string
   ```
4. **Enable encryption** (enabled by default)
5. **Regular backups** (automated by AWS)
6. **Monitor access** via CloudWatch

### Backup and Recovery

**Automatic backups:**
- Daily snapshots
- 7-day retention (default)
- Point-in-time recovery within retention period

**Manual snapshots:**
```powershell
aws rds create-db-snapshot `
  --db-instance-identifier testdb `
  --db-snapshot-identifier testdb-snapshot-2025-12-12
```

**Restore from snapshot:**
```powershell
aws rds restore-db-instance-from-db-snapshot `
  --db-instance-identifier testdb-restored `
  --db-snapshot-identifier testdb-snapshot-2025-12-12
```

### Database Maintenance

**AWS automatically handles:**
- Security patches
- Minor version updates
- Hardware maintenance

**Maintenance window:**
- Default: AWS chooses optimal time
- Can specify preferred window
- Some updates require brief downtime

**To specify window:**
```hcl
# In locals.tf
preferred_maintenance_window = "Mon:03:00-Mon:04:00"  # UTC
```

### Performance Monitoring

**CloudWatch metrics:**
- CPU utilization
- Database connections
- Read/Write IOPS
- Storage space

**View metrics:**
```powershell
# In AWS Console: RDS → Database → Monitoring tab

# Or via CLI:
aws cloudwatch get-metric-statistics `
  --namespace AWS/RDS `
  --metric-name CPUUtilization `
  --dimensions Name=DBInstanceIdentifier,Value=testdb `
  --start-time 2025-12-12T00:00:00Z `
  --end-time 2025-12-12T23:59:59Z `
  --period 3600 `
  --statistics Average
```

### Scaling Considerations

**Vertical scaling (bigger instance):**
```hcl
# In locals.tf
instance_class = "db.t3.small"  # 2 vCPU, 2 GB RAM
# Apply terraform
```
**Downtime:** 3-5 minutes

**Storage scaling (more disk):**
```hcl
allocated_storage = "50"  # Increase from 20 GB
```
**Downtime:** None (online operation)

**Read replicas (scale reads):**
```hcl
# Create read replica for reporting/analytics
resource "aws_db_instance" "read_replica" {
  replicate_source_db = aws_db_instance.rds["default-db"].id
  instance_class      = "db.t3.micro"
}
```

### Destroy Warnings

⚠️ **Before destroying databases:**

1. **Backup data** manually
2. **Take final snapshot**
3. **Update applications** to stop using database

```powershell
# Take final snapshot
aws rds create-db-snapshot `
  --db-instance-identifier testdb `
  --db-snapshot-identifier testdb-final-backup

# Then destroy
terraform destroy
```

**Note:** By default, terraform creates final snapshot on destroy

---

## 🎓 Understanding RDS Concepts

### MySQL vs PostgreSQL vs Others

| Engine | Use Case | Pros | Cons |
|--------|----------|------|------|
| **MySQL** | Web apps, general purpose | Popular, well-supported | Less features than PostgreSQL |
| **PostgreSQL** | Complex queries, JSON data | Advanced features, standards compliant | Steeper learning curve |
| **MariaDB** | MySQL alternative | Fully compatible, more features | Less popular |
| **Aurora** | High performance | AWS-optimized, faster | More expensive |

### Single-AZ vs Multi-AZ

**Single-AZ:**
- One database in one availability zone
- If AZ fails, database is down
- Good for dev/test
- **Half the cost**

**Multi-AZ:**
- Primary in one AZ, standby in another
- Automatic failover if primary fails
- Good for production
- **Double the cost**

### Storage Types

| Type | Use Case | Performance | Cost |
|------|----------|-------------|------|
| **General Purpose (gp2)** | Most workloads | Moderate | Low |
| **Provisioned IOPS (io1)** | High performance | Very high | High |
| **Magnetic** | Legacy | Low | Very low |

**Default**: General Purpose (gp2) - Best for most cases

---

## 🎓 Next Steps

After RDS deployment:

1. ✅ Test database connections
2. ✅ Create application database schemas
3. ✅ Set up monitoring and alerts
4. ✅ Configure automated backups
5. ✅ Proceed to **[ECR](../ecr/README.md)** deployment

---

## 📞 Need Help?

- Check main [README](../../README.md)
- Review [RDS documentation](https://docs.aws.amazon.com/rds/)
- Check [MySQL documentation](https://dev.mysql.com/doc/)

---

**Last Updated**: December 2025  
**Terraform Version**: 1.3.0  
**AWS Provider Version**: 4.67.0  
**MySQL Version**: 5.7
