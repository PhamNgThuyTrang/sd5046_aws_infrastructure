# ECR - Container Registry Guide

## 📋 Table of Contents
- [Overview](#overview)
- [What is ECR?](#what-is-ecr)
- [What Gets Created](#what-gets-created)
- [Prerequisites](#prerequisites)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [Configuration Files Explained](#configuration-files-explained)
- [Using ECR](#using-ecr)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Important Notes](#important-notes)

---

## 🎯 Overview

The **ecr** folder creates **Amazon ECR (Elastic Container Registry)** - a Docker container image repository where you store your application container images.

**Think of it as a secure storage warehouse for your Docker images.**

---

## 🔍 What is ECR?

### For Beginners:

**Docker Image** = Packaged application with everything it needs to run
**Container Registry** = Storage for Docker images
**ECR** = Amazon's managed container registry

**Analogy:**
- **GitHub**: Stores code
- **ECR**: Stores packaged applications (Docker images)
- **Docker Hub**: Public registry (anyone can access)
- **ECR**: Private registry (only you can access)

### Why Use ECR?

1. **Integrated with AWS** - Works seamlessly with EKS
2. **Secure** - Private by default, IAM-controlled
3. **Fast** - Low latency when deploying to EKS
4. **Scalable** - Handles any number of images
5. **Cost-effective** - Pay only for storage used

### Docker Workflow with ECR

```
1. Write application code
2. Create Dockerfile
3. Build Docker image locally
4. Push image to ECR
5. EKS pulls image from ECR
6. EKS runs containers from image
```

---

## 📦 What Gets Created

### ECR Repository

```
Repository Name: nashtech-devops-ecr-mgmt
Environment: Management (mgmt)
Region: ap-southeast-1
Registry URL: 377414509754.dkr.ecr.ap-southeast-1.amazonaws.com

Features:
  - Image scanning: Optional (scan for vulnerabilities)
  - Encryption: AES-256
  - Lifecycle policies: Optional (auto-delete old images)
  - IAM permissions: Pull/Push access control

Access:
  - EKS clusters can pull images
  - Authorized users can push images
  - Private (not publicly accessible)
```

### Repository Configuration

```
Image tag mutability: MUTABLE
  - Can overwrite tags (e.g., "latest")
  - Good for development
  - Consider IMMUTABLE for production

Scan on push: Disabled (by default)
  - Enable to scan images for security vulnerabilities
  - AWS Inspector checks for CVEs

Encryption: Server-side encryption
  - Images encrypted at rest
  - Automatic
```

---

## 📚 Prerequisites

### 1. Previous Steps (Optional)

ECR is independent but typically used with:
- ✅ **EKS** - To run containers from ECR images
- ✅ **EC2** - To build and push images

### 2. Software Requirements

- ✅ **Docker** installed locally
- ✅ **AWS CLI** configured
- ✅ **Terraform** 1.3.0

**Install Docker:**
```powershell
# Docker Desktop for Windows
choco install docker-desktop

# Verify installation
docker --version
```

---

## 🚀 Step-by-Step Deployment

### Update Configuration

#### 1. Update `main.tf`

```hcl
module "ecr" {
  source      = "../modules/ecr"
  
  name        = "ecr"
  project     = "your-project-name"  # ← Change this
  environment = "mgmt"
  owner       = "your-name"          # ← Change this
}
```

### Deployment Steps

#### **Step 1: Navigate to ECR Folder**
```powershell
cd terraform/ecr
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
- 1 ECR repository

**Expected output:**
```
Plan: 1 to add, 0 to change, 0 to destroy.
```

#### **Step 4: Apply Configuration**
```powershell
terraform apply
```

Type `yes` when prompted.

⏱️ **Time**: ~30 seconds

**Expected output:**
```
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:
repository_url = "377414509754.dkr.ecr.ap-southeast-1.amazonaws.com/nashtech-devops-ecr-mgmt"
```

---

## 📄 Configuration Files Explained

### 1. `main.tf` - ECR Module Call

**Creates ECR repository:**
```hcl
module "ecr" {
  source = "../modules/ecr"
  
  name        = "ecr"
  project     = "nashtech-devops"
  environment = "mgmt"
  owner       = "datton94"
}
```

**Simple configuration:**
- No networking required
- No complex dependencies
- Just creates a repository

### 2. `provider.tf` - Terraform Configuration

**Configures:**
- AWS provider
- No backend (can add if needed)

**Note:** ECR doesn't use remote state by default in this setup

---

## 🐳 Using ECR

### Authenticate Docker to ECR

**Get login password:**
```powershell
aws ecr get-login-password --region ap-southeast-1 | `
  docker login --username AWS --password-stdin `
  377414509754.dkr.ecr.ap-southeast-1.amazonaws.com
```

**Expected output:**
```
Login Succeeded
```

### Build and Push Docker Image

#### **Step 1: Create Sample Application**

```powershell
# Create project folder
mkdir my-app
cd my-app

# Create simple Node.js app
@"
const http = require('http');
const server = http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hello from ECR!\n');
});
server.listen(3000);
console.log('Server running on port 3000');
"@ | Out-File -FilePath server.js -Encoding utf8

# Create Dockerfile
@"
FROM node:18-alpine
WORKDIR /app
COPY server.js .
EXPOSE 3000
CMD ["node", "server.js"]
"@ | Out-File -FilePath Dockerfile -Encoding utf8
```

#### **Step 2: Build Docker Image**

```powershell
# Build image
docker build -t my-app:latest .

# Expected output:
# Successfully built abc123def456
# Successfully tagged my-app:latest
```

#### **Step 3: Tag Image for ECR**

```powershell
# Replace with your repository URL
$ECR_REPO = "377414509754.dkr.ecr.ap-southeast-1.amazonaws.com/nashtech-devops-ecr-mgmt"

docker tag my-app:latest ${ECR_REPO}:latest
docker tag my-app:latest ${ECR_REPO}:v1.0.0
```

#### **Step 4: Push to ECR**

```powershell
docker push ${ECR_REPO}:latest
docker push ${ECR_REPO}:v1.0.0
```

**Expected output:**
```
The push refers to repository [377414509754.dkr.ecr.ap-southeast-1.amazonaws.com/nashtech-devops-ecr-mgmt]
latest: digest: sha256:abc123... size: 1234
```

### Pull Image from ECR

**On any AWS resource (EC2, EKS):**

```powershell
# Authenticate
aws ecr get-login-password --region ap-southeast-1 | `
  docker login --username AWS --password-stdin `
  377414509754.dkr.ecr.ap-southeast-1.amazonaws.com

# Pull image
docker pull ${ECR_REPO}:latest

# Run container
docker run -d -p 3000:3000 ${ECR_REPO}:latest
```

### Deploy to EKS from ECR

**Kubernetes deployment:**

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: 377414509754.dkr.ecr.ap-southeast-1.amazonaws.com/nashtech-devops-ecr-mgmt:latest
        ports:
        - containerPort: 3000
```

**Deploy:**
```powershell
kubectl apply -f deployment.yaml
kubectl get pods
```

---

## ✅ Verification

### Check Terraform Outputs

```powershell
terraform output
```

**Expected output:**
```
repository_url = "377414509754.dkr.ecr.ap-southeast-1.amazonaws.com/nashtech-devops-ecr-mgmt"
```

### Verify in AWS Console

**ECR Console**: https://console.aws.amazon.com/ecr/

**Check:**
1. Repository exists: `nashtech-devops-ecr-mgmt`
2. Region: ap-southeast-1
3. Encryption: Enabled

### Using AWS CLI

**List repositories:**
```powershell
aws ecr describe-repositories --region ap-southeast-1
```

**List images in repository:**
```powershell
aws ecr list-images `
  --repository-name nashtech-devops-ecr-mgmt `
  --region ap-southeast-1
```

**Get image details:**
```powershell
aws ecr describe-images `
  --repository-name nashtech-devops-ecr-mgmt `
  --region ap-southeast-1
```

### Test Image Pull

**Pull test:**
```powershell
# Authenticate
aws ecr get-login-password --region ap-southeast-1 | `
  docker login --username AWS --password-stdin `
  377414509754.dkr.ecr.ap-southeast-1.amazonaws.com

# List local images
docker images | Select-String nashtech-devops

# Pull image (if you pushed one)
docker pull 377414509754.dkr.ecr.ap-southeast-1.amazonaws.com/nashtech-devops-ecr-mgmt:latest
```

---

## 🔧 Troubleshooting

### Issue 1: "no basic auth credentials"

**Problem**: Not logged in to ECR

**Solution:**
```powershell
aws ecr get-login-password --region ap-southeast-1 | `
  docker login --username AWS --password-stdin `
  377414509754.dkr.ecr.ap-southeast-1.amazonaws.com
```

### Issue 2: "denied: Your authorization token has expired"

**Problem**: ECR login expired (valid for 12 hours)

**Solution:** Re-authenticate (same command as above)

### Issue 3: "denied: User is not authorized"

**Problem**: IAM permissions insufficient

**Check permissions:**
```powershell
# Your user needs these policies:
# - AmazonEC2ContainerRegistryPowerUser (for push/pull)
# - AmazonEC2ContainerRegistryReadOnly (for pull only)
```

**Grant permission:**
```powershell
aws iam attach-user-policy `
  --user-name YOUR_USERNAME `
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
```

### Issue 4: "repository does not exist"

**Problem**: Wrong repository name or region

**Check:**
```powershell
# List all repositories
aws ecr describe-repositories --region ap-southeast-1

# Verify repository name matches
```

### Issue 5: EKS can't pull images from ECR

**Problem**: EKS node IAM role missing ECR permissions

**Solution:**

Node role should have `AmazonEC2ContainerRegistryReadOnly` policy.

**Check in EKS node IAM role** (created by EKS module):
```powershell
aws iam list-attached-role-policies --role-name <eks-node-role-name>
```

### Issue 6: "image pull backoff" in Kubernetes

**Problem**: Image doesn't exist or wrong tag

**Debug:**
```powershell
# Check image exists
aws ecr describe-images `
  --repository-name nashtech-devops-ecr-mgmt `
  --region ap-southeast-1

# Check pod events
kubectl describe pod <pod-name>

# Check image pull secrets (usually not needed for ECR)
kubectl get secrets
```

---

## ⚠️ Important Notes

### Cost Considerations

**ECR Pricing:**
- **Storage**: $0.10 per GB per month
- **Data transfer OUT**: $0.09 per GB
- **Data transfer IN**: Free
- **Data transfer to EKS in same region**: Free

**Example costs:**
- 10 images @ 500 MB each = 5 GB = $0.50/month
- 100 pulls per month (within AWS) = Free
- Very affordable!

**Cost optimization:**
- Delete old/unused images
- Use lifecycle policies to auto-delete
- Compress images (multi-stage builds)

### Image Management Best Practices

**Tagging strategy:**
```bash
# Bad
docker tag app:latest

# Good
docker tag app:v1.0.0
docker tag app:git-abc123f
docker tag app:2025-12-12-prod
```

**Why?**
- `latest` is mutable (can change)
- Version tags are clear
- Easy rollback to previous versions

**Multi-tagging:**
```powershell
# Tag with multiple identifiers
docker tag app:v1.0.0 ${ECR_REPO}:v1.0.0
docker tag app:v1.0.0 ${ECR_REPO}:latest
docker tag app:v1.0.0 ${ECR_REPO}:prod
```

### Lifecycle Policies

**Auto-delete old images:**

**Create lifecycle policy:**
```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
```

**Apply via CLI:**
```powershell
aws ecr put-lifecycle-policy `
  --repository-name nashtech-devops-ecr-mgmt `
  --lifecycle-policy-text file://policy.json
```

### Image Scanning

**Enable vulnerability scanning:**

```powershell
aws ecr put-image-scanning-configuration `
  --repository-name nashtech-devops-ecr-mgmt `
  --image-scanning-configuration scanOnPush=true
```

**View scan results:**
```powershell
aws ecr describe-image-scan-findings `
  --repository-name nashtech-devops-ecr-mgmt `
  --image-id imageTag=latest
```

### Security Best Practices

1. **Use specific versions** - Don't rely on `:latest`
2. **Scan images** for vulnerabilities
3. **Minimize image size** - Fewer packages = smaller attack surface
4. **Don't store secrets** in images (use AWS Secrets Manager)
5. **Use multi-stage builds** to reduce image size
6. **Sign images** for integrity verification

### Docker Image Optimization

**Multi-stage build example:**

```dockerfile
# Build stage
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Runtime stage
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY server.js ./
USER node
EXPOSE 3000
CMD ["node", "server.js"]
```

**Benefits:**
- Smaller final image (alpine base)
- Only production dependencies
- Runs as non-root user
- Secure and efficient

### Cross-Region Replication

**For multi-region deployments:**

**Enable replication:**
```powershell
aws ecr put-replication-configuration `
  --replication-configuration '{
    "rules": [{
      "destinations": [{
        "region": "us-west-2",
        "registryId": "377414509754"
      }]
    }]
  }'
```

### Destroy Considerations

**Before destroying ECR:**
1. Delete all images first (or they'll be deleted with repository)
2. Update any Kubernetes deployments to use different registry

```powershell
# List images
aws ecr list-images --repository-name nashtech-devops-ecr-mgmt

# Delete all images
aws ecr batch-delete-image `
  --repository-name nashtech-devops-ecr-mgmt `
  --image-ids "$(aws ecr list-images --repository-name nashtech-devops-ecr-mgmt --query 'imageIds[*]' --output json)"

# Then destroy
terraform destroy
```

---

## 🎓 Understanding Container Concepts

### What is a Docker Image?

**Docker Image** = Template for running containers
- Like a snapshot of a computer with your app installed
- Contains: OS files, app code, dependencies
- Immutable (doesn't change)

**Layers:**
```
┌────────────────────────┐
│  Your application code │  ← Smallest layer
├────────────────────────┤
│  Application runtime   │
│  (Node.js, Python)     │
├────────────────────────┤
│  Operating system base │  ← Largest layer
│  (Alpine Linux)        │
└────────────────────────┘
```

### What is a Container?

**Container** = Running instance of an image
- Like starting a program from the image template
- Isolated from other containers
- Can have multiple containers from one image

**Analogy:**
- **Image**: Recipe for a cake
- **Container**: Actual cake you bake from the recipe

### Docker vs VM

| Feature | Virtual Machine | Docker Container |
|---------|-----------------|------------------|
| **Boot time** | Minutes | Seconds |
| **Size** | GBs | MBs |
| **Performance** | Slower | Near-native |
| **Isolation** | Full OS | Process-level |
| **Use case** | Different OSes | Same OS, different apps |

### Registry vs Repository

**Registry** = Service that stores images (ECR is a registry)
**Repository** = Collection of related images (your app images)

```
ECR Registry (377414509754.dkr.ecr.ap-southeast-1.amazonaws.com)
  ├── Repository: nashtech-devops-ecr-mgmt
  │   ├── Image: v1.0.0
  │   ├── Image: v1.0.1
  │   └── Image: latest
  └── Repository: another-app
      ├── Image: v2.0.0
      └── Image: latest
```

---

## 🎓 Next Steps

After ECR deployment:

1. ✅ Push a sample application image
2. ✅ Configure EKS to pull from ECR
3. ✅ Set up CI/CD to auto-push images
4. ✅ Enable image scanning for security
5. ✅ Configure lifecycle policies

### Complete Application Deployment Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Developer writes code                                     │
│ 2. Creates Dockerfile                                        │
│ 3. Builds image: docker build -t app:v1.0.0                │
│ 4. Pushes to ECR: docker push <ECR_URL>:v1.0.0             │
│ 5. Updates K8s deployment with new image tag               │
│ 6. EKS pulls image from ECR                                 │
│ 7. EKS runs containers from image                           │
│ 8. Application is live!                                     │
└─────────────────────────────────────────────────────────────┘
```

---

## 📞 Need Help?

- Check main [README](../../README.md)
- Review [ECR documentation](https://docs.aws.amazon.com/ecr/)
- Check [Docker documentation](https://docs.docker.com/)
- [ECR Best Practices](https://docs.aws.amazon.com/AmazonECR/latest/userguide/best-practices.html)

---

**Last Updated**: December 2025  
**Terraform Version**: 1.3.0  
**AWS Provider Version**: 4.67.0  
**Docker**: Any recent version
