# 🚀 KUBERNETES DEPLOYMENT - QUICK START GUIDE

> **Status**: Ready for deployment on GCP  
> **Estimated Time**: 45-60 minutes (15-20 min waiting for GCP)

---

## 📋 What Was Created

### Terraform Infrastructure
```
3-KUBERNETES/terraform/
├── main.tf          ← GKE cluster, Cloud SQL, VPC
├── variables.tf     ← Configuration values
└── .tfplan          ← Deployment plan (generated)
```

### Kubernetes Manifests
```
3-KUBERNETES/k8s/
├── 00-namespace.yaml           ← voting-app namespace
├── 01-secrets.yaml             ← Database credentials
├── 02-backend-deployment.yaml  ← FastAPI deployment
└── 03-frontend-deployment.yaml ← Nginx deployment + LoadBalancer
```

### Testing Script
```
test-kubernetes-complete.sh ← Full automated deployment
```

---

## 🔧 Prerequisites

### Installed Locally
- ✓ `terraform` (v1.0+)
- ✓ `gcloud` CLI (Google Cloud)
- ✓ `kubectl` (Kubernetes)
- ✓ Docker (for building images)

### GCP Setup
- ✓ GCP Account with billing enabled
- ✓ Project: `diesel-skyline-474415-j6`
- ✓ Authenticated: `gcloud auth login`

### Verify Setup
```bash
# Check Terraform
terraform version

# Check gcloud
gcloud auth list
gcloud config get-value project

# Check kubectl
kubectl version --client

# Check Docker
docker --version
```

---

## 🚀 DEPLOYMENT STEPS

### Step 1: Initialize Terraform

```bash
cd 3-KUBERNETES/terraform

# Download providers
terraform init
```

Expected output:
```
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully configured!
```

### Step 2: Review Infrastructure Plan

```bash
# Show what will be created (no changes yet)
terraform plan -out=tfplan

# Key resources:
# - GKE Cluster (3 nodes)
# - Cloud SQL MySQL 8.0
# - VPC Network
# - Service Accounts & IAM
```

Expected summary:
```
Plan: X to add, 0 to change, 0 to destroy.
```

### Step 3: Create Infrastructure

```bash
# ⏳ WAIT: This takes 15-20 minutes!
terraform apply tfplan

# When done, you'll get:
# - kubernetes_cluster_name
# - sql_instance_connection_name
# - Database credentials
```

### Step 4: Get Kubernetes Credentials

```bash
# Configure kubectl to access GKE
gcloud container clusters get-credentials voting-app-cluster \
  --region us-central1 \
  --project diesel-skyline-474415-j6

# Verify connection
kubectl cluster-info
```

### Step 5: Deploy Application

```bash
cd ../k8s

# Create namespace
kubectl apply -f 00-namespace.yaml

# Create secrets (with Cloud SQL credentials)
kubectl apply -f 01-secrets.yaml

# Deploy backend
kubectl apply -f 02-backend-deployment.yaml

# Deploy frontend
kubectl apply -f 03-frontend-deployment.yaml

# Wait for LoadBalancer IP (2-3 minutes)
kubectl get svc -n voting-app
```

---

## 🧪 TESTING

### Check Deployments

```bash
# View all resources
kubectl get all -n voting-app

# Check pods
kubectl get pods -n voting-app

# Check services
kubectl get svc -n voting-app

# Expected output:
# backend-service    ClusterIP   10.x.x.x   8000/TCP
# frontend-service   LoadBalancer 10.x.x.x   80:xxxxx/TCP  35.192.x.x
```

### Get Frontend URL

```bash
# Get external IP
FRONTEND_IP=$(kubectl get svc frontend-service -n voting-app \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "http://$FRONTEND_IP"

# Open in browser: http://35.192.x.x
```

### Test API

```bash
# Port-forward to backend (if no external IP)
kubectl port-forward -n voting-app svc/backend-service 8000:8000 &

# Health check
curl http://localhost:8000/health
# Response: {"status":"ok","mode":"kubernetes"}

# Get results
curl http://localhost:8000/results
# Response: {"dogs":0,"cats":0,"total":0}

# Submit vote
curl -X POST http://localhost:8000/vote \
  -H "Content-Type: application/json" \
  -d '{"vote":"dogs"}'
# Response: {"success":true,"message":"Vote recorded successfully"}

# Verify
curl http://localhost:8000/results
# Response: {"dogs":1,"cats":0,"total":1}
```

### View Logs

```bash
# Backend logs
kubectl logs -n voting-app -l app=backend --tail=50

# Frontend logs
kubectl logs -n voting-app -l app=frontend --tail=50

# Real-time logs
kubectl logs -f -n voting-app -l app=backend
```

### Scale Deployments

```bash
# Scale backend to 3 replicas
kubectl scale deployment backend -n voting-app --replicas=3

# Scale frontend to 3 replicas
kubectl scale deployment frontend -n voting-app --replicas=3

# Verify
kubectl get pods -n voting-app
```

---

## 🛠️ Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n voting-app

# Check logs
kubectl logs <pod-name> -n voting-app

# Common issues:
# 1. Image not found → Push images to Docker Registry
# 2. Database connection failed → Check secrets
# 3. ReadinessProbe failing → Check app startup logs
```

### LoadBalancer IP stuck in "pending"

```bash
# Check service status
kubectl describe svc frontend-service -n voting-app

# May take 2-3 minutes for IP assignment
# If stuck > 5 min, check GCP Load Balancer quota
```

### Database connection errors

```bash
# Verify Cloud SQL instance
gcloud sql instances list

# Check IP address
gcloud sql instances describe voting-app-db --format="value(ipAddresses[0].ipAddress)"

# Update secrets if IP changed
kubectl edit secret db-credentials -n voting-app
```

### Out of resources

```bash
# Check node resources
kubectl describe nodes

# Check resource requests
kubectl describe deployment backend -n voting-app

# Scale down if needed
kubectl scale deployment backend -n voting-app --replicas=1
```

---

## 🧹 Cleanup

### Delete Application

```bash
# Remove Kubernetes resources
kubectl delete namespace voting-app

# This deletes: pods, services, deployments, etc.
```

### Delete Infrastructure

```bash
cd 3-KUBERNETES/terraform

# Remove ALL GCP resources (cluster, Cloud SQL, VPC, etc.)
terraform destroy

# ⏳ Takes 10-15 minutes
# ⚠️ This is PERMANENT - data cannot be recovered!
```

---

## 📊 Architecture

```
                     Internet
                        │
                        ▼
                  LoadBalancer (80)
                        │
            ┌──────────────────────────┐
            │                          │
            ▼                          ▼
         Frontend Pod 1            Frontend Pod 2
         (Nginx, Port 80)          (Nginx, Port 80)
            │ proxy_pass             │
            │ /api/* -> backend:8000 │
            └──────────────────────────┘
                        │
            ┌──────────────────────────┐
            │                          │
            ▼                          ▼
         Backend Pod 1             Backend Pod 2
         (FastAPI, Port 8000)      (FastAPI, Port 8000)
            │                        │
            └────────────┬───────────┘
                         │
                         ▼
                   Cloud SQL MySQL
                   (Database)
```

---

## 📈 Performance Monitoring

```bash
# CPU/Memory usage
kubectl top nodes
kubectl top pods -n voting-app

# Event logs
kubectl get events -n voting-app --sort-by='.lastTimestamp'

# Pod restart count
kubectl get pods -n voting-app -o wide

# Resource limits
kubectl describe node
```

---

## 🔒 Security Notes

### Current Setup
- ⚠️ Database credentials in Kubernetes Secrets (base64, NOT encrypted!)
- ⚠️ Cloud SQL publicly accessible (0.0.0.0/0)
- ⚠️ Database password in plain text in environment

### Production Improvements
1. Use **Cloud SQL Proxy** instead of direct connection
2. Use **Workload Identity** for authentication
3. Use **Google Secret Manager** for secrets
4. Enable **Cloud SQL encryption**
5. Restrict **firewall rules** (not 0.0.0.0/0)
6. Use **Network Policies** for pod communication
7. Enable **Pod Security Policies**
8. Use **RBAC** for access control

---

## 📝 Files Generated

| File | Purpose |
|------|---------|
| `main.tf` | GKE cluster, Cloud SQL, networking |
| `variables.tf` | Configuration defaults |
| `00-namespace.yaml` | Kubernetes namespace |
| `01-secrets.yaml` | Database credentials |
| `02-backend-deployment.yaml` | Backend + ClusterIP service |
| `03-frontend-deployment.yaml` | Frontend + LoadBalancer service |
| `test-kubernetes-complete.sh` | Automated deployment script |

---

## ✅ Success Criteria

- [ ] Terraform init succeeds
- [ ] Terraform plan shows resources to create
- [ ] Terraform apply completes (15-20 min)
- [ ] GKE cluster appears in `gcloud container clusters list`
- [ ] Cloud SQL instance appears in `gcloud sql instances list`
- [ ] kubectl can access cluster
- [ ] Namespace `voting-app` created
- [ ] Pods running (backend, frontend)
- [ ] LoadBalancer has external IP
- [ ] Application accessible at http://EXTERNAL_IP
- [ ] Vote submission works
- [ ] Database persistence verified

---

## 🎯 Next Steps

After successful Kubernetes deployment:

1. **Monitor**: `kubectl logs -f -n voting-app -l app=backend`
2. **Test**: Open http://EXTERNAL_IP in browser
3. **Scale**: `kubectl scale deployment backend -n voting-app --replicas=5`
4. **Debug**: Check logs if issues arise
5. **Cleanup**: `terraform destroy` when done

---

## 📞 Commands Reference

```bash
# Terraform
terraform init          # Initialize
terraform plan         # Preview changes
terraform apply tfplan # Create resources
terraform destroy      # Delete everything

# kubectl
kubectl get all -n voting-app          # View all resources
kubectl describe pod <name> -n voting-app  # Details
kubectl logs <name> -n voting-app      # Show logs
kubectl exec -it <name> -n voting-app -- /bin/sh  # SSH into pod
kubectl scale deployment <name> --replicas=N  # Change replicas
kubectl port-forward svc/<svc> 8000:8000  # Port forward

# gcloud
gcloud container clusters list          # List clusters
gcloud container clusters describe <name>  # Cluster details
gcloud sql instances list              # List databases
gcloud sql instances describe <name>   # Database details
gcloud container clusters get-credentials <name> --region <region>
```

---

**Status: ✅ Ready for Deployment**  
**Next: Run test-kubernetes-complete.sh or follow manual steps above**
