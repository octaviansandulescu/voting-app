# 🚀 GCP Deployment Commands

Three simple commands to manage your Voting App on GCP:

## 📋 Available Commands

### 1️⃣ **START - Deploy Application**
```bash
./start-gcp.sh
```

**What it does:**
- ✅ Sets up GCP configuration
- ✅ Enables required APIs
- ✅ Initializes Terraform
- ✅ Creates GKE cluster (~12-15 min)
- ✅ Creates Cloud SQL instance (~5-10 min)
- ✅ Builds Docker images (~3-5 min)
- ✅ Pushes images to Artifact Registry
- ✅ Deploys to Kubernetes (~3-5 min)
- ✅ Returns frontend URL

**Total time:** ~20-30 minutes

**Output:** 
```
📱 Frontend URL: http://35.x.x.x
✅ Application is ready to use!
```

---

### 2️⃣ **STATUS - Check Application Status**
```bash
./status-gcp.sh
```

**What it does:**
- 📊 Shows GKE cluster status
- 📊 Shows Cloud SQL instance status
- 📊 Shows Kubernetes pods and services
- 📊 Shows frontend URL (if available)
- 📊 Tests API connectivity
- 📊 Shows Terraform state resources

**Use:** Run anytime to check application health

**Output:**
```
🔍 GKE Cluster Status:
NAME                STATUS     LOCATION
voting-app-cluster  RUNNING    us-central1

🔍 Cloud SQL Instance Status:
NAME                 DATABASEVERSION  STATE
voting-app-mysql     MYSQL_8_0        RUNNABLE

✅ Frontend URL: http://35.x.x.x
✅ API is responding
```

---

### 3️⃣ **STOP - Delete All Resources**
```bash
./stop-gcp.sh
```

**What it does:**
- ⛔ Deletes Kubernetes namespace
- ⛔ Deletes GKE cluster (~5-10 min)
- ⛔ Deletes Cloud SQL instance (~2-5 min)
- ⛔ Destroys Terraform resources

**Total time:** ~10-20 minutes

**⚠️ WARNING:** This deletes EVERYTHING! Data cannot be recovered.

---

## 🔄 Typical Workflow

### First Time Setup
```bash
# Deploy everything
./start-gcp.sh

# Wait 20-30 minutes...
# You'll get the frontend URL
```

### Daily Checks
```bash
# Check status anytime
./status-gcp.sh
```

### When Done / Saving Costs
```bash
# Stop everything
./stop-gcp.sh

# Wait 10-20 minutes...
# All resources deleted
```

### Redeploy
```bash
# Deploy again after stopping
./start-gcp.sh
```

---

## 📊 Timeline Reference

| Operation | Duration |
|-----------|----------|
| GCP configuration | 30 sec |
| Enable APIs | 1 min |
| Terraform init | 1 min |
| Terraform plan | 2 min |
| GKE cluster creation | 12-15 min |
| Cloud SQL creation | 5-10 min |
| Docker build & push | 3-5 min |
| Kubernetes deployment | 3-5 min |
| **Total Deploy** | **20-30 min** |
| | |
| Stop & delete all | **10-20 min** |

---

## 💡 Use Cases

### Scenario 1: Development Testing
```bash
# Monday - Start
./start-gcp.sh

# Wednesday - Check status
./status-gcp.sh

# Friday - Stop (save costs)
./stop-gcp.sh
```

### Scenario 2: Demo / Presentation
```bash
# Before demo
./start-gcp.sh

# During demo
# Show application to audience

# After demo
./stop-gcp.sh
```

### Scenario 3: Continuous Deployment
```bash
# Deploy once
./start-gcp.sh

# Monitor continuously
./status-gcp.sh  # Run every 5 minutes

# Never stop (production)
```

---

## 🔍 What Each Script Does In Detail

### start-gcp.sh (Step by Step)
```
[1/7] Setting up GCP configuration
      - gcloud config set project
      - gcloud config set region

[2/7] Enabling required GCP APIs
      - Kubernetes Engine
      - Cloud SQL Admin
      - Compute Engine
      - Artifact Registry
      - Service Networking

[3/7] Initializing Terraform
      - terraform init
      - Downloads Google provider

[4/7] Planning Terraform resources
      - terraform plan
      - Shows what will be created

[5/7] Creating GCP infrastructure (~15-20 min)
      - GKE cluster
      - Cloud SQL
      - VPC network
      - Service networking

[6/7] Building and pushing Docker images
      - docker-compose build
      - docker push (frontend + backend)

[7/7] Deploying to Kubernetes
      - kubectl apply (namespaces, secrets, deployments)
      - Wait for rollout complete
      - Get LoadBalancer IP
```

### stop-gcp.sh (Step by Step)
```
[1/4] Deleting Kubernetes namespace
      - kubectl delete namespace voting-app

[2/4] Deleting GKE cluster (~5-10 min)
      - gcloud container clusters delete

[3/4] Deleting Cloud SQL instance (~2-5 min)
      - gcloud sql instances delete

[4/4] Destroying Terraform resources
      - terraform destroy
      - Removes VPC, subnets, etc.
```

### status-gcp.sh (Checks)
```
✓ GKE cluster status (running/stopped)
✓ Cloud SQL instance status (runnable/stopped)
✓ Kubernetes pods (running count)
✓ Kubernetes services (IP addresses)
✓ Frontend LoadBalancer IP
✓ API connectivity test
✓ Terraform resource count
```

---

## 🚨 Troubleshooting

### LoadBalancer IP is "Pending"
```bash
# Wait 1-2 minutes
sleep 60

# Check again
./status-gcp.sh
```

### GKE cluster creation failed
```bash
# Check GCP quotas
gcloud compute project-info describe --project=$PROJECT_ID

# Retry
./stop-gcp.sh
./start-gcp.sh
```

### "gcloud: command not found"
```bash
# Install Google Cloud SDK
# https://cloud.google.com/sdk/docs/install

# Or on Ubuntu:
sudo apt-get install google-cloud-cli
```

### "kubectl: command not found"
```bash
# Install kubectl
# https://kubernetes.io/docs/tasks/tools/

# Or on Ubuntu:
gcloud components install kubectl
```

---

## 💰 Cost Estimation

| Resource | Cost/Hour | Cost/Day | Cost/Month |
|----------|-----------|----------|-----------|
| GKE (1 node e2-medium) | $0.03 | $0.72 | ~$22 |
| Cloud SQL (db-f1-micro) | $0.07 | $1.68 | ~$50 |
| Network egress | $0.01 | $0.24 | ~$7 |
| **TOTAL** | **$0.11** | **$2.64** | **~$79** |

**💡 Tip:** Stop resources when not in use to save money!

---

## 🎯 Best Practices

### ✅ DO:
- Check status with `./status-gcp.sh` regularly
- Stop resources when not using them with `./stop-gcp.sh`
- Keep backups if you have important data
- Monitor costs in GCP console

### ❌ DON'T:
- Leave resources running 24/7 unless necessary
- Delete terraform files if you want to preserve state
- Modify resources directly in GCP console (use these scripts)
- Ignore error messages (they help you troubleshoot)

---

## 📚 Related Commands

### Manual Checks
```bash
# GKE cluster status
gcloud container clusters list --project=$PROJECT_ID

# Cloud SQL status
gcloud sql instances list --project=$PROJECT_ID

# Kubernetes pods
kubectl get pods -n voting-app

# View application logs
kubectl logs -n voting-app -l app=backend
kubectl logs -n voting-app -l app=frontend

# Port forward to backend (local testing)
kubectl port-forward -n voting-app svc/backend 8000:8000

# Scale deployment
kubectl scale deployment frontend -n voting-app --replicas=3
```

---

## 🔐 Security Notes

- ✅ Cloud SQL uses private IP (no public access)
- ✅ Kubernetes uses namespaces (voting-app isolation)
- ✅ GCP service accounts with minimal IAM roles
- ✅ Secrets managed securely
- ✅ No hardcoded passwords in code

---

## 📞 Quick Help

```bash
# See what will be deployed (without actually deploying)
cd terraform && terraform plan && cd ..

# See what exists
./status-gcp.sh

# See resource details
terraform state show google_container_cluster.primary

# SSH into a pod for debugging
kubectl exec -it <pod-name> -n voting-app -- /bin/bash
```

---

## 🎓 Learning Path

1. **Understand the flow**: Read this README
2. **Check status**: `./status-gcp.sh`
3. **Deploy first time**: `./start-gcp.sh`
4. **Monitor**: `./status-gcp.sh` every 5 minutes
5. **Test application**: Visit the frontend URL
6. **Clean up**: `./stop-gcp.sh`
7. **Redeploy**: `./start-gcp.sh`

---

**Last Updated:** November 11, 2025  
**Version:** 1.0.0  
**Status:** ✅ Production Ready
