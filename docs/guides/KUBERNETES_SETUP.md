# Phase 2.3: Kubernetes Setup Guide (GCP/GKE)

**Estimated Time**: 30 minutes | **Difficulty**: Advanced | **Prerequisites**: DOCKER_SETUP.md, TESTING_FUNDAMENTALS.md

## Overview

In this guide, you'll deploy the voting app to Google Kubernetes Engine (GKE), the production-grade cloud platform. This is where the application runs at scale with automatic recovery, load balancing, and monitoring.

**What you'll learn**:
- ✅ How to set up a GKE cluster
- ✅ How to push Docker images to Google Container Registry
- ✅ How to deploy to Kubernetes with manifests
- ✅ How to test production deployments
- ✅ How to manage secrets securely
- ✅ How to verify deployment health

## Prerequisites

Before starting, ensure you have:

```bash
# Required
gcloud --version              # Google Cloud CLI
kubectl version --client     # Kubernetes CLI
gcloud config get-value project  # Should show your GCP project

# Verify authentication
gcloud auth list
gcloud config list
```

**System Requirements**:
- GCP Account with billing enabled
- Google Cloud Project created
- API permissions (Compute Engine, Kubernetes Engine, Container Registry)
- $10-20 budget for test deployment (3 e2-medium nodes)

**WARNING**: This incurs costs! See Cleanup section for cost management.

## Step 1: Set Up GCP Project

### 1.1 Create or Select Project

```bash
# List existing projects
gcloud projects list

# Set active project
gcloud config set project PROJECT_ID

# Get project details
gcloud config get-value project
gcloud config get-value account
```

**If creating new project**:
```bash
gcloud projects create voting-app-prod \
  --name="Voting App Production"

# Set it as active
gcloud config set project voting-app-prod
```

### 1.2 Enable Required APIs

```bash
# Enable Kubernetes Engine API
gcloud services enable container.googleapis.com

# Enable Compute Engine API
gcloud services enable compute.googleapis.com

# Enable Container Registry API
gcloud services enable containerregistry.googleapis.com

# Verify APIs are enabled
gcloud services list --enabled
```

### 1.3 Create Service Account (Optional but Recommended)

```bash
# Create service account
gcloud iam service-accounts create voting-app-deployer \
  --display-name="Voting App Deployer"

# Grant necessary roles
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member=serviceAccount:voting-app-deployer@PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/container.developer

# Create and download key
gcloud iam service-accounts keys create ~/voting-app-key.json \
  --iam-account=voting-app-deployer@PROJECT_ID.iam.gserviceaccount.com

# Activate the key
gcloud auth activate-service-account --key-file=~/voting-app-key.json
```

## Step 2: Push Docker Images to Google Container Registry

### 2.1 Configure Docker Authentication

```bash
# Configure Docker for GCP
gcloud auth configure-docker

# Verify configuration
cat ~/.docker/config.json
```

### 2.2 Tag Images for GCR

```bash
# Get project ID
PROJECT_ID=$(gcloud config get-value project)

# Tag backend image
docker tag voting-app-backend:local \
  gcr.io/${PROJECT_ID}/voting-app-backend:v1

# Tag frontend image
docker tag voting-app-frontend:local \
  gcr.io/${PROJECT_ID}/voting-app-frontend:v1

# Verify tags
docker images | grep gcr.io
```

### 2.3 Push Images to GCR

```bash
# Push backend
docker push gcr.io/${PROJECT_ID}/voting-app-backend:v1

# Push frontend
docker push gcr.io/${PROJECT_ID}/voting-app-frontend:v1

# Verify in GCR
gcloud container images list
gcloud container images describe gcr.io/${PROJECT_ID}/voting-app-backend:v1
```

**Output should show**:
```
NAME: gcr.io/YOUR_PROJECT/voting-app-backend
REPOSITORY_URL: gcr.io/YOUR_PROJECT/voting-app-backend
DIGEST: sha256:abc123...
CREATED: 2025-11-11
FULL_IMAGE_NAME: gcr.io/YOUR_PROJECT/voting-app-backend:v1
```

## Step 3: Create GKE Cluster

### 3.1 Create Cluster

```bash
# Set variables
PROJECT_ID=$(gcloud config get-value project)
CLUSTER_NAME=voting-app-cluster
REGION=us-central1
ZONE=us-central1-a

# Create cluster (this takes ~5 minutes)
gcloud container clusters create ${CLUSTER_NAME} \
  --region ${REGION} \
  --num-nodes 3 \
  --machine-type e2-medium \
  --enable-ip-alias \
  --enable-stackdriver-kubernetes \
  --addons HttpLoadBalancing,HttpsLoadBalancing \
  --workload-pool=${PROJECT_ID}.svc.id.goog \
  --enable-autoscaling \
  --min-nodes 1 \
  --max-nodes 5

# This will take 3-5 minutes
```

**What each flag means**:
- `--region`: Deploy across zone (better availability)
- `--num-nodes 3`: Start with 3 nodes
- `--machine-type e2-medium`: Cost-effective machine type
- `--enable-ip-alias`: Use VPC-native networking
- `--enable-stackdriver-kubernetes`: Enable logging and monitoring
- `--workload-pool`: Enable Workload Identity
- `--enable-autoscaling`: Auto-scale based on load

### 3.2 Get Cluster Credentials

```bash
# Get credentials to use kubectl
gcloud container clusters get-credentials ${CLUSTER_NAME} \
  --region ${REGION}

# Verify connection
kubectl cluster-info
kubectl get nodes
```

**Expected output**:
```
NAME                                       STATUS   ROLES    AGE     VERSION
gke-voting-app-cluster-default-pool-abc    Ready    <none>   2m      v1.33.5-gke.1201000
gke-voting-app-cluster-default-pool-def    Ready    <none>   2m      v1.33.5-gke.1201000
gke-voting-app-cluster-default-pool-ghi    Ready    <none>   2m      v1.33.5-gke.1201000
```

### 3.3 Create Cluster Networking

```bash
# Create VPC for database
gcloud compute networks create voting-app-vpc \
  --subnet-mode custom

# Create subnet
gcloud compute networks subnets create voting-app-subnet \
  --network voting-app-vpc \
  --range 10.0.0.0/20 \
  --region ${REGION}

# Create service network for Cloud SQL
gcloud compute addresses create google-managed-services-voting-app-vpc \
  --global \
  --purpose=VPC_PEERING \
  --prefix-length=16 \
  --network=voting-app-vpc
```

## Step 4: Create Cloud SQL Database

### 4.1 Create MySQL Instance

```bash
# Create Cloud SQL instance (takes ~3 minutes)
gcloud sql instances create voting-app-db \
  --database-version=MYSQL_8_0 \
  --tier=db-f1-micro \
  --region=${REGION} \
  --network=voting-app-vpc

# Get instance details
gcloud sql instances describe voting-app-db
```

### 4.2 Create Database and User

```bash
# Get instance connection name
INSTANCE_CONNECTION_NAME=$(gcloud sql instances describe voting-app-db \
  --format='value(connectionName)')

echo "Connection name: ${INSTANCE_CONNECTION_NAME}"

# Create database
gcloud sql databases create voting_app_k8s \
  --instance=voting-app-db

# Create user
gcloud sql users create voting_user \
  --instance=voting-app-db \
  --password=SECURE_PASSWORD_HERE

# Test connection (optional, requires Cloud SQL Proxy)
```

### 4.3 Get Database IP

```bash
# Get private IP (for Kubernetes pods)
PRIVATE_IP=$(gcloud sql instances describe voting-app-db \
  --format='value(ipAddresses[0].ipAddress)')

echo "Database private IP: ${PRIVATE_IP}"

# Save for Kubernetes manifests
echo "DATABASE_HOST=${PRIVATE_IP}" > /tmp/db-config.txt
```

## Step 5: Create Kubernetes Secrets

### 5.1 Create Database Credentials Secret

```bash
# Create secret from literal values
kubectl create secret generic database-credentials \
  --from-literal=host=${PRIVATE_IP} \
  --from-literal=port=3306 \
  --from-literal=user=voting_user \
  --from-literal=password='SECURE_PASSWORD_HERE' \
  --from-literal=database=voting_app_k8s

# Verify secret created
kubectl get secret database-credentials
kubectl describe secret database-credentials

# View secret (WARNING: shows decoded values!)
kubectl get secret database-credentials -o yaml
```

### 5.2 Create Docker Registry Secret (for GCR access)

```bash
# Create secret for pulling images from GCR
kubectl create secret docker-registry gcr-secret \
  --docker-server=gcr.io \
  --docker-username=_json_key \
  --docker-password="$(cat ~/voting-app-key.json)" \
  --docker-email=voting-app-deployer@${PROJECT_ID}.iam.gserviceaccount.com

# Verify
kubectl get secret gcr-secret
```

## Step 6: Create Kubernetes Namespace

### 6.1 Create Namespace

```bash
# Create namespace for our application
kubectl create namespace voting-app

# Set as default namespace
kubectl config set-context --current --namespace=voting-app

# Verify
kubectl get namespace
kubectl config view --minify | grep namespace
```

### 6.2 Create Secrets in Namespace

```bash
# Create secrets in namespace
kubectl -n voting-app create secret generic database-credentials \
  --from-literal=host=${PRIVATE_IP} \
  --from-literal=port=3306 \
  --from-literal=user=voting_user \
  --from-literal=password='SECURE_PASSWORD_HERE' \
  --from-literal=database=voting_app_k8s

# Verify
kubectl -n voting-app get secrets
```

## Step 7: Deploy Manifests

### 7.1 Review Kubernetes Manifests

Check `3-KUBERNETES/k8s/` directory:

```bash
ls -la 3-KUBERNETES/k8s/

# Should have:
# 00-namespace.yaml
# 01-secrets.yaml
# 02-backend-deployment.yaml
# 03-frontend-deployment.yaml
# 04-services.yaml (if exists)
```

### 7.2 Update Manifests with Your Project

```bash
# Replace PROJECT_ID placeholders
sed -i "s/YOUR_PROJECT_ID/${PROJECT_ID}/g" 3-KUBERNETES/k8s/*.yaml

# Replace DATABASE_IP
sed -i "s/PRIVATE_IP/${PRIVATE_IP}/g" 3-KUBERNETES/k8s/*.yaml

# Verify replacements
grep -n "PROJECT_ID\|PRIVATE_IP" 3-KUBERNETES/k8s/*.yaml
# Should return nothing
```

### 7.3 Apply Manifests

```bash
# Apply manifests in order
kubectl apply -f 3-KUBERNETES/k8s/00-namespace.yaml
kubectl apply -f 3-KUBERNETES/k8s/01-secrets.yaml
kubectl apply -f 3-KUBERNETES/k8s/02-backend-deployment.yaml
kubectl apply -f 3-KUBERNETES/k8s/03-frontend-deployment.yaml

# Or apply all at once
kubectl apply -f 3-KUBERNETES/k8s/

# Verify
kubectl -n voting-app get all
```

## Step 8: Verify Deployment

### 8.1 Check Pod Status

```bash
# Get pods (wait for them to be Ready)
kubectl -n voting-app get pods

# Watch pods coming up
kubectl -n voting-app get pods -w

# Quit with Ctrl+C
```

**Expected output**:
```
NAME                               READY   STATUS    RESTARTS   AGE
voting-app-backend-6d8f7c8d5-abc   1/1     Running   0          2m
voting-app-backend-6d8f7c8d5-def   1/1     Running   0          2m
voting-app-frontend-8b4f9c9e6-ghi  1/1     Running   0          2m
voting-app-frontend-8b4f9c9e6-jkl  1/1     Running   0          2m
```

### 8.2 Check Services

```bash
# Get services
kubectl -n voting-app get services

# Expected:
# NAME                 TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)
# voting-app-backend   ClusterIP      10.0.0.100    <none>         8000/TCP
# voting-app-frontend  LoadBalancer   10.0.0.101    34.42.155.47   80:30123/TCP
```

### 8.3 Get External IP

```bash
# Get LoadBalancer external IP
EXTERNAL_IP=$(kubectl -n voting-app get service voting-app-frontend \
  --output jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "External IP: ${EXTERNAL_IP}"

# May take 1-2 minutes to assign
# Retry if blank
```

## Step 9: Test Production Deployment

### 9.1 Test Backend API

```bash
# Health check
curl http://${EXTERNAL_IP}:8000/health

# Should show: {"status": "healthy", "mode": "kubernetes"}
```

### 9.2 Test Frontend

```bash
# Open browser
open http://${EXTERNAL_IP}

# Or with curl
curl -I http://${EXTERNAL_IP}
```

### 9.3 Test Vote Submission

```bash
# Submit vote via curl
curl -X POST http://${EXTERNAL_IP}/api/vote \
  -H "Content-Type: application/json" \
  -d '{"vote": "dogs"}'

# Get results
curl http://${EXTERNAL_IP}/api/results

# Should persist in Cloud SQL database
```

## Step 10: Check Logs

### 10.1 View Pod Logs

```bash
# Get backend logs
kubectl -n voting-app logs -f deployment/voting-app-backend

# Get frontend logs
kubectl -n voting-app logs -f deployment/voting-app-frontend

# Get logs from specific pod
kubectl -n voting-app logs -f voting-app-backend-6d8f7c8d5-abc
```

### 10.2 Check Events

```bash
# Get cluster events
kubectl -n voting-app get events

# Watch events
kubectl -n voting-app get events -w
```

## Step 11: Run Tests in Production

### 11.1 Run Tests in Pod

```bash
# Get a backend pod name
POD_NAME=$(kubectl -n voting-app get pods -l app=voting-app-backend \
  -o jsonpath='{.items[0].metadata.name}')

# Run tests inside pod
kubectl -n voting-app exec -it ${POD_NAME} -- pytest tests/ -v

# Run specific test
kubectl -n voting-app exec -it ${POD_NAME} -- \
  pytest tests/test_api.py::test_health_endpoint -v
```

### 11.2 Run Integration Tests

```bash
# Port-forward to backend
kubectl -n voting-app port-forward svc/voting-app-backend 8000:8000 &

# Run tests against production
BACKEND_URL=http://localhost:8000 pytest tests/ -v

# Stop port-forward
pkill -f "port-forward"
```

## Step 12: Monitor Deployment

### 12.1 Check Resource Usage

```bash
# CPU and memory usage
kubectl -n voting-app top pods
kubectl -n voting-app top nodes
```

### 12.2 Check Pod Details

```bash
# Detailed pod information
kubectl -n voting-app describe pod voting-app-backend-6d8f7c8d5-abc

# Check for errors or warnings
```

### 12.3 View GCP Monitoring

```bash
# Open GCP Console
gcloud compute ssh voting-app-cluster --zone=${ZONE}

# Or view in GCP Console UI
# https://console.cloud.google.com/kubernetes/workloads
```

## Step 13: Update Deployment

### 13.1 Update Image Version

```bash
# Rebuild and push new image
docker build -t voting-app-backend:v2 -f src/backend/Dockerfile src/backend/
docker tag voting-app-backend:v2 gcr.io/${PROJECT_ID}/voting-app-backend:v2
docker push gcr.io/${PROJECT_ID}/voting-app-backend:v2

# Update deployment
kubectl -n voting-app set image deployment/voting-app-backend \
  voting-app-backend=gcr.io/${PROJECT_ID}/voting-app-backend:v2

# Watch rollout
kubectl -n voting-app rollout status deployment/voting-app-backend

# If something goes wrong, rollback
kubectl -n voting-app rollout undo deployment/voting-app-backend
```

### 13.2 Scale Deployment

```bash
# Scale to 5 replicas
kubectl -n voting-app scale deployment voting-app-backend --replicas=5

# Verify
kubectl -n voting-app get pods
```

## Step 14: Troubleshooting

### Issue: Pod stuck in "Pending" state

```bash
# Check pod details
kubectl -n voting-app describe pod POD_NAME

# Check if nodes have resources
kubectl get nodes
kubectl describe node NODE_NAME

# Might need to add more nodes
gcloud container clusters resize voting-app-cluster --num-nodes 5
```

### Issue: "ImagePullBackOff" error

```bash
# Image not found in GCR
# Check image name matches exactly
gcloud container images list

# Verify image pushed correctly
gcloud container images describe gcr.io/${PROJECT_ID}/voting-app-backend:v1

# May need to check Docker authentication
gcloud auth configure-docker
```

### Issue: Database connection fails

```bash
# Check database is running
gcloud sql instances describe voting-app-db

# Verify pod can reach database
kubectl -n voting-app exec -it POD_NAME -- \
  mysql -h ${PRIVATE_IP} -u voting_user -p

# Check firewall rules
gcloud compute firewall-rules list
```

### Issue: "LoadBalancer stuck in pending"

```bash
# Check service events
kubectl -n voting-app describe service voting-app-frontend

# IP assignment takes 1-3 minutes
# Wait and retry
kubectl get service -w

# Or check GCP Console for load balancer
gcloud compute forwarding-rules list
```

## Step 15: Cleanup (Stop Costs!)

### ⚠️ IMPORTANT: Stop Paying!

This is critical - if you don't do this, you'll be charged!

```bash
# Step 1: Delete Kubernetes resources
kubectl -n voting-app delete all --all

# Step 2: Delete namespace
kubectl delete namespace voting-app

# Step 3: Delete GKE cluster (this is expensive!)
gcloud container clusters delete voting-app-cluster \
  --region ${REGION}

# Step 4: Delete Cloud SQL instance
gcloud sql instances delete voting-app-db

# Step 5: Delete service account
gcloud iam service-accounts delete \
  voting-app-deployer@${PROJECT_ID}.iam.gserviceaccount.com

# Step 6: Clean up local files
rm -f ~/voting-app-key.json
```

### Verify Cleanup

```bash
# Check nothing is running
gcloud container clusters list
gcloud sql instances list
gcloud compute forwarding-rules list

# All should be empty
```

## Step 16: Security Checklist

- ✅ Secrets are stored in Kubernetes Secret objects (not in environment)
- ✅ Database password is strong (20+ characters)
- ✅ Images are pushed to private GCR (not public)
- ✅ Cloud SQL is private (not public IP)
- ✅ Service account has minimum required permissions
- ✅ RBAC is configured (if using)
- ✅ Network policies restrict traffic (if configured)
- ✅ No secrets in logs or pod descriptions
- ✅ All tests pass in production

Check for secrets:
```bash
# Ensure no secrets in Kubernetes resources
kubectl -n voting-app get all -o yaml | grep -i password

# Should return nothing
```

## Step 17: Cost Estimation

**Approximate GKE Costs**:
- 3 e2-medium nodes: ~$20-30/month each = $60-90/month
- Cloud SQL db-f1-micro: ~$10/month
- Network/Load Balancer: ~$5/month
- **Total: ~$75-105/month** (if running continuously)

**Cost Savings**:
- Delete cluster when not in use (saves ~$80/month)
- Use preemptible nodes (saves ~70%)
- Resize cluster to 1 node when not testing (saves ~$60/month)

**To minimize costs**:
```bash
# Resize to 1 node
gcloud container clusters resize voting-app-cluster --num-nodes 1

# Or delete completely (see Step 15)
```

## Testing Checklist - Production Deployment

- ✅ All pods are Running and Ready
- ✅ API endpoints respond (health, results, vote)
- ✅ Frontend displays correctly
- ✅ Votes persist in database
- ✅ Environment detection shows "kubernetes"
- ✅ No errors in pod logs
- ✅ Autoscaling is configured
- ✅ Backups are enabled (if production)
- ✅ All tests pass in pods

## Next Steps

Congratulations! You've deployed to production! 🚀

**What you've learned**:
- How to use GCP and GKE
- How to push images to Cloud Registry
- How to deploy Kubernetes manifests
- How to manage production infrastructure
- How to secure databases and secrets

**Remember to clean up!** See Step 15 to avoid charges.

**Ready for CI/CD?** → Move to `docs/guides/TESTING_CICD.md`

## Resources

- **GKE Documentation**: https://cloud.google.com/kubernetes-engine/docs
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Cloud SQL**: https://cloud.google.com/sql/docs
- **GCP Pricing Calculator**: https://cloud.google.com/products/calculator

---

**Questions?** Review SECURITY.md or check GCP documentation.

**Ready for automation?** Continue to `docs/guides/TESTING_CICD.md` →
