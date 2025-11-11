# GCP Deployment - Quick Start Guide

Your GCP Project: **diesel-skyline-474415-j6**
Region: **us-central1**

## 🚀 3-Minute Setup

### Step 1: Validate Environment
```bash
./validate.sh
```

This checks:
- ✓ gcloud CLI
- ✓ kubectl
- ✓ terraform
- ✓ GCP authentication
- ✓ All required files

### Step 2: Auto-Configure
```bash
./setup-gcp.sh
```

This automatically:
- Generates secure DB password
- Creates `terraform/terraform.tfvars`
- Updates Kubernetes manifests
- Enables required GCP APIs
- Configures image registry paths

### Step 3: Deploy to GCP
```bash
./deploy.sh
```

This will:
1. Initialize Terraform
2. Validate configuration
3. Create GCP infrastructure (GKE, Cloud SQL, VPC, etc.)
4. Deploy Kubernetes manifests
5. Wait for pods to be ready
6. Display frontend URL

## 📋 What Gets Created

### Google Cloud Infrastructure
- **GKE Cluster**: `voting-app-cluster` (1 node, e2-medium)
- **Cloud SQL**: MySQL 8.0 instance `voting-app-mysql`
- **Artifact Registry**: For Docker images
- **VPC Network**: Private networking

### Kubernetes Services
- **Backend**: 2 replicas FastAPI + Cloud SQL Proxy
- **Frontend**: 2 replicas Nginx
- **Database**: Cloud SQL (external to cluster)

### Estimated Costs
- GKE: ~$0.10/hour (first 3 nodes free)
- Cloud SQL: ~$0.02/hour (f1-micro tier)
- **Total: ~$10-20/month** for this setup

## ✅ Useful Commands

### Check Deployment Status
```bash
kubectl get pods -n voting-app
kubectl get svc -n voting-app
```

### View Logs
```bash
# Backend logs
kubectl logs -f deployment/backend -n voting-app

# Frontend logs
kubectl logs -f deployment/frontend -n voting-app
```

### Get Frontend URL
```bash
kubectl get svc frontend -n voting-app
# Copy the EXTERNAL-IP and open in browser
```

### Scale Applications
```bash
kubectl scale deployment/backend --replicas=3 -n voting-app
kubectl scale deployment/frontend --replicas=3 -n voting-app
```

## 🔧 Troubleshooting

### Pod is stuck in "Pending"
```bash
kubectl describe pod <pod-name> -n voting-app
```

### Cloud SQL connection issues
```bash
# Check if Cloud SQL is ready
gcloud sql instances describe voting-app-mysql

# Check Cloud SQL Proxy logs
kubectl logs <backend-pod> -c cloud-sql-proxy -n voting-app
```

### Need to rebuild images?
```bash
# Build backend
docker build -t us-central1-docker.pkg.dev/diesel-skyline-474415-j6/voting-app-docker/voting-backend:latest ./src/backend

# Push to Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev
docker push us-central1-docker.pkg.dev/diesel-skyline-474415-j6/voting-app-docker/voting-backend:latest

# Update deployment
kubectl set image deployment/backend backend=us-central1-docker.pkg.dev/diesel-skyline-474415-j6/voting-app-docker/voting-backend:latest -n voting-app
```

## 📖 Full Documentation

See [GCP_DEPLOYMENT.md](../docs/GCP_DEPLOYMENT.md) for detailed information about:
- Manual setup steps
- Architecture details
- Security best practices
- Advanced configurations
- Cleanup instructions

## 🛑 When Done - Cleanup

To avoid charges, delete all resources:

```bash
# Delete Kubernetes resources
kubectl delete namespace voting-app

# Destroy GCP infrastructure
cd terraform
terraform destroy
cd ..
```

---

**Questions?** Check the main [README.md](../README.md) or [GCP_DEPLOYMENT.md](../docs/GCP_DEPLOYMENT.md)
