# GCP Deployment Guide

## Prerequisites

1. **GCP Account** with billing enabled
2. **Tools installed:**
   - `gcloud` CLI
   - `kubectl`
   - `terraform`
   - `docker`

## Setup Steps

### 1. Authenticate to GCP

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### 2. Enable Required APIs

```bash
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable iam.googleapis.com
```

### 3. Create Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
project_id         = "your-gcp-project-id"
region             = "europe-west1"
db_root_password   = "your-secure-password"
```

### 4. Create GitHub Secrets for CI/CD

Add these secrets to your GitHub repository:

- `GCP_PROJECT_ID`: Your GCP project ID
- `WIF_PROVIDER`: Workload Identity Federation provider (for secure auth)
- `WIF_SERVICE_ACCOUNT`: Service account email

For Workload Identity Federation setup, follow: https://github.com/google-github-actions/auth

### 5. Deploy to GCP

Make the deploy script executable:
```bash
chmod +x deploy.sh
```

Run the deployment:
```bash
export GCP_PROJECT_ID=your-project-id
export GCP_REGION=europe-west1
./deploy.sh
```

### 6. Verify Deployment

```bash
# Check pods
kubectl get pods -n voting-app

# Check services
kubectl get svc -n voting-app

# View backend logs
kubectl logs -f deployment/backend -n voting-app

# Access frontend
kubectl port-forward svc/frontend 8080:80 -n voting-app
# Then open http://localhost:8080
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│         GCP Project (your-project-id)           │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │      GKE Cluster (voting-app-cluster)    │  │
│  │                                          │  │
│  │  ┌────────────────────────────────────┐ │  │
│  │  │   Frontend Pod (Nginx)             │ │  │
│  │  │   - Replicas: 2                    │ │  │
│  │  └────────────────────────────────────┘ │  │
│  │                 ↓                        │  │
│  │  ┌────────────────────────────────────┐ │  │
│  │  │   Backend Pod (FastAPI)            │ │  │
│  │  │   - Replicas: 2                    │ │  │
│  │  │   - Cloud SQL Proxy Sidecar        │ │  │
│  │  └────────────────────────────────────┘ │  │
│  │                 ↓                        │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │   Cloud SQL (MySQL 8.0)                 │  │
│  │   - Instance: voting-app-mysql          │  │
│  │   - Database: votingapp                 │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Managing Deployments

### Update Backend Image

```bash
# Build and push new image (automatic via GitHub Actions on main branch)
# Or manually:
gcloud auth configure-docker europe-west1-docker.pkg.dev
docker build -t europe-west1-docker.pkg.dev/YOUR_PROJECT/voting-app-docker/voting-backend:v1 ./src/backend
docker push europe-west1-docker.pkg.dev/YOUR_PROJECT/voting-app-docker/voting-backend:v1

# Update deployment
kubectl set image deployment/backend \
  backend=europe-west1-docker.pkg.dev/YOUR_PROJECT/voting-app-docker/voting-backend:v1 \
  -n voting-app
```

### Scale Replicas

```bash
kubectl scale deployment/backend --replicas=3 -n voting-app
kubectl scale deployment/frontend --replicas=3 -n voting-app
```

### View Logs

```bash
# Backend logs
kubectl logs -f deployment/backend -n voting-app

# Frontend logs
kubectl logs -f deployment/frontend -n voting-app

# Cloud SQL logs
gcloud sql operations list --instance=voting-app-mysql
```

## Cleanup

To destroy all resources:

```bash
# Delete Kubernetes resources
kubectl delete namespace voting-app

# Destroy Terraform infrastructure
cd terraform
terraform destroy
```

## Troubleshooting

### Pod is in CrashLoopBackOff

```bash
kubectl describe pod <pod-name> -n voting-app
kubectl logs <pod-name> -n voting-app
```

### Cloud SQL connection issues

```bash
# Check Cloud SQL instance status
gcloud sql instances describe voting-app-mysql

# Check if Cloud SQL proxy is running
kubectl logs -f <pod-name> -c cloud-sql-proxy -n voting-app
```

### Frontend not loading

```bash
# Check Nginx logs
kubectl logs -f deployment/frontend -n voting-app

# Check if backend service is accessible
kubectl exec -it <frontend-pod> -n voting-app -- sh
# Inside pod: curl http://backend:8000/results
```

## Security Considerations

1. **Database Credentials**: Store in Kubernetes Secrets (or Google Secret Manager)
2. **Private Network**: Cloud SQL is on private VPC
3. **Cloud SQL Proxy**: Used for secure connections
4. **Network Policies**: Restrict traffic between pods
5. **RBAC**: Service accounts with minimal permissions

## Cost Optimization

- Use preemptible nodes for non-production
- Set resource requests/limits
- Use VPC-native networking
- Implement pod autoscaling (HPA)

## Next Steps

1. Set up Argo CD for GitOps deployment
2. Configure Cloud Monitoring for observability
3. Set up Cloud Build for CI/CD
4. Configure custom domain with Cloud DNS