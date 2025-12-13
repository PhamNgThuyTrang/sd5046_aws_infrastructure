# EKS - Kubernetes Cluster Guide

## 📋 Table of Contents
- [Overview](#overview)
- [What is EKS?](#what-is-eks)
- [What Gets Created](#what-gets-created)
- [Cluster Architecture](#cluster-architecture)
- [Prerequisites](#prerequisites)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [Configuration Files Explained](#configuration-files-explained)
- [Accessing Your Cluster](#accessing-your-cluster)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Important Notes](#important-notes)

---

## 🎯 Overview

The **eks** folder creates an **Amazon EKS (Elastic Kubernetes Service)** cluster - a managed Kubernetes environment where you can run containerized applications.

**Think of it as creating an automated fleet of servers that can run Docker containers.**

---

## 🔍 What is EKS?

### For Beginners:

**Kubernetes (K8s)** = A system that automatically manages containers (like Docker)
**EKS** = Amazon's managed Kubernetes service (they handle the hard parts)

**Analogy:**
- **Traditional Server**: One application per server
- **Containers**: Multiple isolated applications on one server
- **Kubernetes**: Automatically manages many containers across many servers
- **EKS**: AWS manages Kubernetes for you

### What Kubernetes Does:

1. **Automatic deployment** - Runs your applications
2. **Auto-scaling** - Adds more containers when busy
3. **Self-healing** - Restarts failed containers
4. **Load balancing** - Distributes traffic
5. **Rolling updates** - Updates without downtime

---

## 📦 What Gets Created

### 1. EKS Cluster

```
Name: eks-dev
Version: Kubernetes 1.26
Region: ap-southeast-1 (Singapore)

Control Plane:
  - Managed by AWS (you don't manage these servers)
  - High availability (multiple servers)
  - API endpoint for kubectl commands
  
Encryption:
  - KMS key for Kubernetes secrets
  - Secure etcd database
```

### 2. Worker Nodes (Self-Managed)

```
Node Group: mixed-1
Node Type: Spot + On-Demand mix
Node Sizes: t3a.micro, t3a.medium, t3a.large

Configuration:
  - Desired: 3 nodes
  - Maximum: 3 nodes
  - 10% on-demand, 90% spot instances
  
Instance Profile:
  - SSM (Systems Manager) access
  - ECR (Container Registry) pull access
  - CloudWatch logging
```

### 3. Networking Configuration

```
VPC: Uses network from previous step
Subnets: Private subnets (3 AZs)
  - dev-private-subnet-0 (ap-southeast-1a)
  - dev-private-subnet-1 (ap-southeast-1b)
  - dev-private-subnet-2 (ap-southeast-1c)

Security Groups:
  - Node-to-node communication (all ports)
  - Control plane to node (port 9443)
  - Nodes can access internet via NAT Gateway
```

### 4. Cluster Add-ons

```
CoreDNS: Service discovery and DNS
kube-proxy: Network routing for pods
VPC-CNI: AWS networking plugin
```

### 5. IAM Roles (IRSA - IAM Roles for Service Accounts)

**Purpose**: Allows Kubernetes pods to assume IAM roles

**Configured for:**
- ALB Ingress Controller (commented out)
- External DNS (for managing Route53 DNS)

### 6. Logging

```
Enabled Logs:
  - API server logs
  - Audit logs
  - Authenticator logs

Destination: CloudWatch Logs
Retention: Configurable
```

### 7. SSH Key Pair

```
Name: eks-key-dev
Purpose: SSH access to worker nodes
Location: ./ (current directory)
Files:
  - eks-key-dev.pem (private key)
  - eks-key-dev.pub (public key)
```

---

## 🏗️ Cluster Architecture

### Visual Diagram

```
┌────────────────────────────────────────────────────────────────┐
│                       AWS EKS Cluster                           │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐│
│  │         Control Plane (Managed by AWS)                      ││
│  │                                                              ││
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     ││
│  │  │   API        │  │   Scheduler  │  │   Controller │     ││
│  │  │   Server     │  │              │  │   Manager    │     ││
│  │  └──────────────┘  └──────────────┘  └──────────────┘     ││
│  │                                                              ││
│  │  ┌──────────────────────────────────────────────────────┐  ││
│  │  │              etcd (Encrypted with KMS)                │  ││
│  │  └──────────────────────────────────────────────────────┘  ││
│  └────────────────────────────────────────────────────────────┘│
│                            │                                    │
│                            │ kubectl commands                   │
│                            ▼                                    │
│  ┌────────────────────────────────────────────────────────────┐│
│  │           Worker Nodes (Your Applications Run Here)         ││
│  │                                                              ││
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     ││
│  │  │   Node 1     │  │   Node 2     │  │   Node 3     │     ││
│  │  │  (AZ-1a)     │  │  (AZ-1b)     │  │  (AZ-1c)     │     ││
│  │  │              │  │              │  │              │     ││
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │     ││
│  │  │ │   Pod    │ │  │ │   Pod    │ │  │ │   Pod    │ │     ││
│  │  │ │  (App1)  │ │  │ │  (App2)  │ │  │ │  (App3)  │ │     ││
│  │  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │     ││
│  │  │              │  │              │  │              │     ││
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │  │              │     ││
│  │  │ │   Pod    │ │  │ │   Pod    │ │  │              │     ││
│  │  │ │  (App4)  │ │  │ │  (App5)  │ │  │              │     ││
│  │  │ └──────────┘ │  │ └──────────┘ │  │              │     ││
│  │  └──────────────┘  └──────────────┘  └──────────────┘     ││
│  └────────────────────────────────────────────────────────────┘│
└────────────────────────────────────────────────────────────────┘
```

### High Availability Features

- **3 Availability Zones** - Cluster survives AZ failures
- **Control Plane** - AWS runs multiple replicas
- **Worker Nodes** - Spread across 3 AZs
- **Auto Scaling** - Can adjust node count (configured for fixed 3)

---

## 📚 Prerequisites

### 1. Previous Steps Completed
✅ **Bootstrap** - Deployed (provides KMS key)
✅ **Networks** - Deployed (provides VPC and subnets)

**Verify:**
```powershell
# Check bootstrap
cd ../bootstrap
terraform output kms_eks_alias_arn

# Check networks
cd ../networks
terraform output dev-private-subnet-0
```

### 2. Software Requirements
- ✅ **kubectl** installed (Kubernetes CLI)
- ✅ **aws-cli** installed and configured
- ✅ **Terraform** 1.3.0

**Install kubectl:**
```powershell
choco install kubernetes-cli
kubectl version --client
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

provider "kubernetes" {
  # Update profile in args
  args = [
    "--profile",
    "YOUR_AWS_PROFILE",  # ← Change this
    "--region",
    "ap-southeast-1",
    "eks",
    "get-token",
    "--cluster-name",
    module.eks.cluster_id
  ]
}
```

#### 2. Update `terraform.auto.tfvars`
```hcl
name         = "eks"
environment  = "dev"
project-name = "your-project-name"  # ← Change this
owner        = "your-name"          # ← Change this
```

### Deployment Steps

#### **Step 1: Navigate to EKS Folder**
```powershell
cd terraform/eks
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
- EKS cluster
- IAM roles for cluster and nodes
- Security groups
- Worker node group
- Key pair
- CloudWatch log group

**Expected output:**
```
Plan: 50+ to add, 0 to change, 0 to destroy.
```

#### **Step 4: Apply Configuration**
```powershell
terraform apply
```

Type `yes` when prompted.

⏱️ **Time**: 15-20 minutes (EKS takes time to provision)

**You will see:**
```
module.eks.aws_eks_cluster.this[0]: Creating...
module.eks.aws_eks_cluster.this[0]: Still creating... [5m0s elapsed]
module.eks.aws_eks_cluster.this[0]: Still creating... [10m0s elapsed]
...
```

**Expected output:**
```
Apply complete! Resources: 52 added, 0 changed, 0 destroyed.

Outputs:
cluster_endpoint = "https://xxxxx.eks.ap-southeast-1.amazonaws.com"
cluster_name = "eks-dev"
cluster_security_group_id = "sg-xxxxx"
```

#### **Step 5: Configure kubectl**

**Get cluster credentials:**
```powershell
aws eks update-kubeconfig `
  --region ap-southeast-1 `
  --name eks-dev `
  --profile YOUR_AWS_PROFILE
```

**Expected output:**
```
Added new context arn:aws:eks:ap-southeast-1:377414509754:cluster/eks-dev to C:\Users\YourName\.kube\config
```

---

## 📄 Configuration Files Explained

### 1. `eks.tf` - Main Cluster Configuration

**Key sections:**

**Cluster configuration:**
```hcl
module "eks" {
  cluster_name    = "eks-dev"
  cluster_version = "1.26"
  
  # Networking
  vpc_id     = data.terraform_remote_state.network.outputs.vpc.id
  subnet_ids = [private subnets]
  
  # Access
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  
  # Encryption
  cluster_encryption_config = [{
    provider_key_arn = data.terraform_remote_state.bootstrap.outputs.kms_eks_alias_arn
    resources        = ["secrets"]
  }]
}
```

**Worker nodes (self-managed):**
```hcl
self_managed_node_groups = {
  one = {
    name         = "mixed-1"
    max_size     = 3
    desired_size = 3
    
    use_mixed_instances_policy = true
    
    mixed_instances_policy = {
      instances_distribution = {
        on_demand_base_capacity = 1              # 1 on-demand
        on_demand_percentage_above_base = 10     # 10% on-demand, 90% spot
        spot_allocation_strategy = "capacity-optimized"
      }
      
      override = [
        { instance_type = "t3a.micro" }    # Cheapest
        { instance_type = "t3a.medium" }   # Medium
        { instance_type = "t3a.large" }    # Larger
      ]
    }
  }
}
```

### 2. `key_pair.tf` - SSH Keys

**Creates SSH keys for node access:**
```hcl
resource "tls_private_key" "eks" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "eks" {
  key_name   = "eks-key-dev"
  public_key = tls_private_key.eks.public_key_openssh
}

resource "local_file" "ssh_key" {
  filename        = "${path.module}/eks-key-dev.pem"
  content         = tls_private_key.eks.private_key_pem
  file_permission = "0400"  # Read-only for owner
}
```

### 3. `irsa_role_and_policies_*.tf` - Service Account Roles

**Purpose**: Allow Kubernetes pods to use AWS services

**External DNS example:**
```hcl
resource "aws_iam_role" "external_dns" {
  name = "irsa-external-dns-eks-dev"
  
  assume_role_policy = {
    # Allow specific Kubernetes service account to assume this role
    principals = {
      type = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
  }
}
```

**Currently commented out** - Uncomment when needed

### 4. `locals.tf` - Local Variables

**Defines:**
- Common tags
- Resource naming
- Configuration values

### 5. `provider.tf` - Terraform Configuration

**Configures:**
- AWS provider
- Kubernetes provider (for managing K8s resources)
- S3 backend
- Remote state references

### 6. `tags.tf` - Resource Tagging

**Standardizes tags** across all EKS resources

---

## 🔑 Accessing Your Cluster

### Configure kubectl

**Download cluster credentials:**
```powershell
aws eks update-kubeconfig `
  --region ap-southeast-1 `
  --name eks-dev `
  --profile YOUR_AWS_PROFILE
```

### Verify Connection

**Check cluster info:**
```powershell
kubectl cluster-info
```

**Expected output:**
```
Kubernetes control plane is running at https://xxxxx.eks.ap-southeast-1.amazonaws.com
CoreDNS is running at https://xxxxx.eks.ap-southeast-1.amazonaws.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

**List nodes:**
```powershell
kubectl get nodes
```

**Expected output:**
```
NAME                                           STATUS   ROLES    AGE   VERSION
ip-10-0-48-123.ap-southeast-1.compute.internal   Ready    <none>   5m    v1.26.x
ip-10-0-64-234.ap-southeast-1.compute.internal   Ready    <none>   5m    v1.26.x
ip-10-0-80-345.ap-southeast-1.compute.internal   Ready    <none>   5m    v1.26.x
```

### Basic kubectl Commands

**View all resources:**
```powershell
kubectl get all --all-namespaces
```

**Check system pods:**
```powershell
kubectl get pods -n kube-system
```

**View logs:**
```powershell
kubectl logs <pod-name> -n <namespace>
```

**Deploy a test application:**
```powershell
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl get services
```

---

## ✅ Verification

### Check Terraform Outputs

```powershell
terraform output
```

**Expected output:**
```
cluster_name = "eks-dev"
cluster_endpoint = "https://xxxxx.eks.ap-southeast-1.amazonaws.com"
cluster_security_group_id = "sg-xxxxx"
oidc_provider_arn = "arn:aws:iam::377414509754:oidc-provider/..."
```

### Verify in AWS Console

**EKS Console**: https://console.aws.amazon.com/eks/

**Check:**
1. Cluster status: ACTIVE
2. Kubernetes version: 1.26
3. Networking: Correct VPC and subnets
4. Add-ons: CoreDNS, kube-proxy, VPC-CNI
5. Logging: API, Audit, Authenticator enabled

**EC2 Console**: https://console.aws.amazon.com/ec2/

**Check:**
1. Worker nodes: 3 instances running
2. Instance types: Mix of t3a.micro/medium/large
3. Tags: eks-dev cluster tag
4. Security groups: Node security group

### Using AWS CLI

**Describe cluster:**
```powershell
aws eks describe-cluster --name eks-dev --region ap-southeast-1
```

**List node groups:**
```powershell
aws eks list-nodegroups --cluster-name eks-dev --region ap-southeast-1
```

**Check add-ons:**
```powershell
aws eks list-addons --cluster-name eks-dev --region ap-southeast-1
```

### Test Kubernetes

**Deploy test pod:**
```powershell
kubectl run test-pod --image=nginx --restart=Never
kubectl get pods
kubectl describe pod test-pod
kubectl delete pod test-pod
```

---

## 🔧 Troubleshooting

### Issue 1: "Error creating EKS Cluster: Timeout"

**Problem**: Cluster creation taking too long

**Solution**: Be patient, can take 15-20 minutes. If >30 minutes:
```powershell
# Check CloudWatch logs for errors
aws logs tail /aws/eks/eks-dev/cluster
```

### Issue 2: "You must be logged in to the server"

**Problem**: kubectl not configured

**Solution**: Update kubeconfig:
```powershell
aws eks update-kubeconfig --name eks-dev --region ap-southeast-1
```

### Issue 3: Nodes not joining cluster

**Problem**: Worker nodes stuck in NotReady state

**Check:**
1. Security group rules allow node-to-control-plane traffic
2. Nodes have internet access via NAT Gateway
3. IAM role has necessary permissions

**Debug:**
```powershell
kubectl get nodes
kubectl describe node <node-name>
```

### Issue 4: "error: You must be logged in to the server (Unauthorized)"

**Problem**: AWS credentials expired or incorrect

**Solution**: Refresh credentials:
```powershell
# For SSO
aws sso login --profile YOUR_PROFILE

# Update kubeconfig
aws eks update-kubeconfig --name eks-dev --region ap-southeast-1
```

### Issue 5: Pods can't pull images from ECR

**Problem**: Node IAM role missing ECR permissions

**Solution**: Verify node role has `AmazonEC2ContainerRegistryReadOnly` policy:
```powershell
aws iam list-attached-role-policies --role-name <node-role-name>
```

### Issue 6: High costs from worker nodes

**Problem**: Too many nodes or wrong instance types

**Solution**: Adjust node configuration in `eks.tf`:
```hcl
self_managed_node_groups = {
  one = {
    max_size     = 2        # ← Reduce
    desired_size = 2        # ← Reduce
    
    on_demand_percentage_above_base = 0  # ← 100% spot
  }
}
```

### Issue 7: "Error: Cluster encryption not working"

**Problem**: KMS key permissions

**Solution**: Update KMS policy in bootstrap to include EKS role

---

## ⚠️ Important Notes

### Cost Considerations

**Monthly costs:**
- EKS Control Plane: $72/month (fixed)
- Worker Nodes (3 x t3a.micro spot): ~$15-20/month
- Data transfer: Variable
- CloudWatch Logs: ~$5/month

**Total: ~$92-100/month minimum**

**Cost optimization:**
- Use spot instances (90% savings)
- Reduce number of nodes
- Use smaller instance types
- Stop cluster when not in use (control plane still charges!)

### Spot Instance Considerations

**Spot instances = Spare AWS capacity at 70-90% discount**

**Pros:**
- Massive cost savings
- Good for dev/test environments

**Cons:**
- Can be terminated with 2-minute warning
- Not recommended for production databases
- OK for stateless applications

**Configuration in this repo:**
- 1 on-demand instance (guaranteed)
- 2 spot instances (can be interrupted)

### Security Best Practices

1. **Private endpoints** - Enable endpoint_private_access
2. **Restrict public access** - Limit endpoint_public_access_cidrs
3. **Enable logging** - Monitor API calls and audit logs
4. **Use IRSA** - Grant pod-level permissions, not node-level
5. **Network policies** - Control pod-to-pod traffic
6. **Regular updates** - Keep Kubernetes version current

### Kubernetes Version

**Current version**: 1.26

**AWS supports last 3 versions:**
- Update at least once per year
- Test updates in dev environment first

**To upgrade:**
1. Update cluster version in terraform
2. Apply changes
3. Update nodes
4. Update add-ons

### Worker Node Management

**Self-managed vs EKS-managed:**
- **Self-managed** (this repo) - More control, more work
- **EKS-managed** - AWS handles updates, less control

**To switch to EKS-managed:**
- Comment out self_managed_node_groups
- Add eks_managed_node_groups configuration

### Accessing Worker Nodes

**SSH to nodes:**
```powershell
# Get node public IP (if in public subnet) or use bastion
ssh -i eks-key-dev.pem ec2-user@<node-ip>
```

**Using Session Manager (no SSH key needed):**
```powershell
aws ssm start-session --target <instance-id>
```

### Destroy Warnings

⚠️ **Before destroying EKS:**

1. Delete all Kubernetes resources (LoadBalancers, PVCs)
2. Wait for AWS resources to be cleaned up
3. Then run terraform destroy

```powershell
# Delete all workloads
kubectl delete all --all --all-namespaces

# Delete LoadBalancers (they create AWS ELBs)
kubectl delete svc --all --all-namespaces

# Now safe to destroy
terraform destroy
```

**Destruction time**: 10-15 minutes

---

## 🎓 Understanding Kubernetes Concepts

### What is a Pod?

**Pod** = Smallest deployable unit in Kubernetes
- Contains one or more containers
- Shares network and storage
- Scheduled on a node

### What is a Node?

**Node** = A worker machine (EC2 instance)
- Runs pods
- Managed by control plane
- Has kubelet agent

### What is a Service?

**Service** = Stable network endpoint for pods
- Load balances across pod replicas
- Types: ClusterIP, NodePort, LoadBalancer

### What is a Deployment?

**Deployment** = Manages pod replicas
- Ensures desired number of pods running
- Handles rolling updates
- Can scale up/down

### Common Kubernetes Commands

```powershell
# Get resources
kubectl get pods
kubectl get services
kubectl get deployments
kubectl get nodes

# Describe (detailed info)
kubectl describe pod <pod-name>
kubectl describe node <node-name>

# Logs
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # Follow logs

# Execute commands in pod
kubectl exec -it <pod-name> -- /bin/bash

# Apply configuration
kubectl apply -f deployment.yaml

# Delete resources
kubectl delete pod <pod-name>
kubectl delete deployment <deployment-name>
```

---

## 🎓 Next Steps

After EKS deployment:

1. ✅ Verify cluster is ACTIVE
2. ✅ Confirm nodes are Ready
3. ✅ Test deploying a sample application
4. ✅ Configure monitoring and logging
5. ✅ Proceed to **[EC2](../ec2/README.md)** for bastion hosts

---

## 📞 Need Help?

- Check main [README](../../README.md)
- Review [EKS documentation](https://docs.aws.amazon.com/eks/)
- Check [Kubernetes documentation](https://kubernetes.io/docs/)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)

---

**Last Updated**: December 2025  
**Terraform Version**: 1.3.0  
**AWS Provider Version**: 4.67.0  
**Kubernetes Version**: 1.26
