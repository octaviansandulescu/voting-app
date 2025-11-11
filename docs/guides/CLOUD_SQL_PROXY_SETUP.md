# Cloud SQL Proxy Setup - Secure Database Access

## 🎯 Overview

Instead of connecting directly to Cloud SQL IP (which is exposed and unstable), use **Cloud SQL Proxy**:

- ✅ Secure: Uses IAM authentication (no passwords)
- ✅ Stable: DNS service name instead of IP
- ✅ Encrypted: TLS connections
- ✅ Auditable: GCP Cloud Audit Logs

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Kubernetes Pod (Backend)                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │ FastAPI Application                              │  │
│  │ Connection: mysql+pymysql://voting_user@...     │  │
│  │ Host: cloud-sql-proxy (DNS resolution)          │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓ (port 3306)
┌─────────────────────────────────────────────────────────┐
│  Cloud SQL Proxy Pod (Same cluster)                     │
│  ┌──────────────────────────────────────────────────┐  │
│  │ cloud-sql-proxy service (listening on 3306)     │  │
│  │ Authentication: Workload Identity (IAM)         │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓ (TLS encrypted)
┌─────────────────────────────────────────────────────────┐
│  Google Cloud SQL (Managed MySQL)                       │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Database: voting_app_k8s                         │  │
│  │ Private IP: 35.202.121.162 (not directly used)  │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 📋 Prerequisites

1. **GCP Project with**:
   - Kubernetes cluster (GKE)
   - Cloud SQL instance
   - Workload Identity enabled

2. **Tools**:
   - `gcloud` CLI
   - `kubectl` CLI

3. **Permissions**:
   - Project Editor or Cloud SQL Admin role

---

## 🚀 Setup Instructions

### Step 1: Create Cloud IAM Service Account

```bash
# Set variables
PROJECT_ID="your-project-id"  # e.g., diesel-skyline-474415-j6
REGION="us-central1"
INSTANCE_NAME="voting-app-db"  # Your Cloud SQL instance name

# Create service account
gcloud iam service-accounts create cloud-sql-proxy \
  --display-name="Cloud SQL Proxy for Kubernetes"
```

### Step 2: Grant Cloud SQL Client Role

```bash
# Give the service account permission to connect to Cloud SQL
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:cloud-sql-proxy@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"
```

### Step 3: Setup Workload Identity

```bash
# Allow Kubernetes ServiceAccount to act as GCP Service Account
gcloud iam service-accounts add-iam-policy-binding \
  cloud-sql-proxy@${PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:${PROJECT_ID}.svc.id.goog[voting-app/cloud-sql-proxy-sa]"
```

### Step 4: Annotate Kubernetes ServiceAccount

```bash
# Link K8s ServiceAccount to GCP Service Account
kubectl annotate serviceaccount cloud-sql-proxy-sa \
  -n voting-app \
  iam.gke.io/gcp-service-account=cloud-sql-proxy@${PROJECT_ID}.iam.gserviceaccount.com
```

### Step 5: Update Cloud SQL Proxy Manifest

Edit `infrastructure/kubernetes/04-cloud-sql-proxy-deployment.yaml`:

```yaml
# Line 43 - Replace with your Cloud SQL instance:
command:
  - /cloud_sql_proxy
  - --instances=PROJECT_ID:REGION:INSTANCE_NAME=tcp:0.0.0.0:3306
```

Example:
```yaml
command:
  - /cloud_sql_proxy
  - --instances=diesel-skyline-474415-j6:us-central1:voting-app-db=tcp:0.0.0.0:3306
```

### Step 6: Deploy Cloud SQL Proxy

```bash
# Apply the manifest
kubectl apply -f infrastructure/kubernetes/04-cloud-sql-proxy-deployment.yaml

# Verify it's running
kubectl get pods -n voting-app -l app=cloud-sql-proxy
# Should show: cloud-sql-proxy-xxxx   1/1   Running
```

### Step 7: Verify Connectivity

```bash
# Test from backend pod
kubectl exec -it backend-0 -n voting-app -- /bin/bash

# Inside pod, test connection:
mysql -h cloud-sql-proxy -u voting_user -p -D voting_app_k8s
# Enter password: (from secrets)
# Should succeed!
```

---

## ✅ Benefits vs Direct IP Connection

| Aspect | Direct IP | Cloud SQL Proxy |
|--------|-----------|-----------------|
| Security | Passwords in config | IAM authentication |
| IP Stability | Changes on restart | DNS stays same |
| Encryption | Not enforced | TLS by default |
| Audit Trail | Limited | Full GCP audit logs |
| VPC Network | Requires peering | Works cross-VPC |
| Cost | Same | Same |
| Complexity | Simple | Moderate |

---

## 🔍 Troubleshooting

### Problem: Pod can't connect to Cloud SQL

```bash
# Check Cloud SQL Proxy is running
kubectl get pods -n voting-app -l app=cloud-sql-proxy

# Check logs
kubectl logs -n voting-app -l app=cloud-sql-proxy

# Check Service
kubectl get svc -n voting-app cloud-sql-proxy
```

### Problem: "Authentication failed"

```bash
# Verify Workload Identity is configured
kubectl describe sa -n voting-app cloud-sql-proxy-sa
# Should show annotation: iam.gke.io/gcp-service-account

# Verify service account permissions
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:cloud-sql-proxy*"
```

### Problem: "Connection refused"

```bash
# Verify backend pod can reach Cloud SQL Proxy
kubectl exec -it backend-0 -n voting-app -- \
  nc -zv cloud-sql-proxy 3306
# Should show: succeeded!
```

---

## 📚 Environment Configuration

After setup, backends connect with:

```env
# From infrastructure/kubernetes/01-secrets.yaml
DB_HOST=cloud-sql-proxy      # DNS name (stable!)
DB_PORT=3306
DB_USER=voting_user
DB_PASSWORD=<from-secrets>
DB_NAME=voting_app_k8s
```

No hardcoded IPs! ✅

---

## 🔄 Scaling & Updates

### Scale Cloud SQL Proxy (if needed)

```bash
# Increase replicas for redundancy
kubectl scale deployment cloud-sql-proxy -n voting-app --replicas=2
```

### Update Cloud SQL Proxy Version

```bash
# Edit deployment
kubectl edit deployment cloud-sql-proxy -n voting-app

# Change image version and save
# New version will rollout automatically
```

---

## 🛡️ Security Best Practices

1. **Use Workload Identity** (never JSON keys!)
   - Automatic token rotation
   - No keys stored in Kubernetes

2. **Limit permissions**
   - Service account has only cloudsql.client role
   - No admin access

3. **Enable audit logging**
   - GCP audits all connection attempts
   - See Cloud Audit Logs in GCP Console

4. **Use VPC-SC** (optional)
   - Additional network security
   - Prevents data exfiltration

5. **Monitor connections**
   - Cloud SQL proxy logs all connections
   - Set up alerts in Cloud Monitoring

---

## 📖 References

- [Cloud SQL Proxy Documentation](https://cloud.google.com/sql/docs/mysql/cloud-sql-proxy)
- [Workload Identity Setup](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [Cloud SQL Best Practices](https://cloud.google.com/sql/docs/mysql/best-practices)
