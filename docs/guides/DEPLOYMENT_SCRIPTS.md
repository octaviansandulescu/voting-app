# Kubernetes Deployment Management Scripts

## 📋 Overview

Centralized scripts for managing the voting app deployment on GKE:

```
scripts/deployment/
├── manage-deployment.sh      # 🎛️  Central control (START, STOP, STATUS, etc.)
├── start-deployment.sh       # 🚀 Deploy application
├── stop-deployment.sh        # 🛑 Delete all resources
├── status-deployment.sh      # 📊 Check health
├── validate-deployment.sh    # 🧪 Test endpoints
└── check-deploy-status.sh    # ⚡ Quick status check
```

---

## 🎛️ Central Management Script

Use `manage-deployment.sh` as your main control:

### Start Deployment
```bash
./scripts/deployment/manage-deployment.sh start
```

**What it does:**
- ✅ Gets cluster credentials
- ✅ Creates namespace
- ✅ Deploys secrets
- ✅ Deploys Cloud SQL Proxy
- ✅ Deploys Backend
- ✅ Deploys Frontend
- ✅ Waits for all pods ready
- ✅ Shows LoadBalancer IP

**Time:** ~3-5 minutes

---

### Check Status
```bash
./scripts/deployment/manage-deployment.sh status
```

**Shows:**
- 📦 Pod status (running/not ready)
- 🚀 Deployment status
- 🌐 Service & IP info
- 📡 Frontend URL
- 💚 Health summary
- 📋 Recent events

---

### Validate Deployment
```bash
./scripts/deployment/manage-deployment.sh validate
```

**Tests:**
- ✅ Frontend connectivity
- ✅ API /results endpoint
- ✅ API /vote endpoint
- ✅ Database persistence
- ✅ Vote counts accuracy

---

### Stop Deployment
```bash
./scripts/deployment/manage-deployment.sh stop
```

**⚠️ WARNING:** This will:
- ❌ Delete all pods
- ❌ Delete services & load balancer
- ❌ Delete namespace
- ❌ Remove all data

**Confirmation required**

---

### Restart Deployment (Full Redeploy)
```bash
./scripts/deployment/manage-deployment.sh restart
```

**Equivalent to:**
1. `stop` - Delete everything
2. Wait 5 seconds
3. `start` - Deploy fresh

**Use case:** Clean rebuild from scratch

---

## 🚀 Individual Scripts

### start-deployment.sh
Complete deployment orchestration.

```bash
./scripts/deployment/start-deployment.sh
```

**Steps:**
1. Verify prerequisites (gcloud, kubectl)
2. Get cluster credentials
3. Create namespace
4. Create secrets
5. Deploy Cloud SQL Proxy
6. Deploy Backend
7. Deploy Frontend
8. Wait for readiness
9. Show access URL

**Output:**
```
Step 1/5: Creating secrets...
✅ Secrets created

Step 2/5: Deploying Cloud SQL Proxy...
✅ Cloud SQL Proxy deployment applied

Step 3/5: Deploying Backend...
✅ Backend deployment applied

Step 4/5: Deploying Frontend...
✅ Frontend deployment applied

Step 5/5: Waiting for deployments to be ready...
⏳ Backend deployment...
✅ Backend ready

⏳ Frontend deployment...
✅ Frontend ready

📡 Getting LoadBalancer IP...
✅ Frontend available at: http://35.184.176.208
```

---

### stop-deployment.sh
Delete all resources with confirmation.

```bash
./scripts/deployment/stop-deployment.sh
```

**Confirmation:**
```
⚠️  WARNING: This will DELETE all voting app resources!

This will delete:
  - All pods (frontend, backend, cloud-sql-proxy)
  - All services and load balancers
  - All persistent data in the namespace

Are you sure you want to continue? (yes/no): 
```

**If confirmed:**
1. Delete all deployments
2. Delete all services
3. Delete all secrets
4. Delete namespace
5. Wait for cleanup

---

### status-deployment.sh
Comprehensive health check.

```bash
./scripts/deployment/status-deployment.sh
```

**Output:**
```
📊 Cluster Information
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Cluster:   voting-cluster
Region:    us-central1
Project:   diesel-skyline-474415-j6
Namespace: voting-app

📦 Namespace Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
NAME        STATUS   AGE
voting-app  Active   2h

🐳 Pod Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Pods:   5
Running:      5

NAME                              READY   STATUS    RESTARTS
backend-0                         1/1     Running   0
backend-1                         1/1     Running   0
frontend-0                        1/1     Running   0
frontend-1                        1/1     Running   0
cloud-sql-proxy-0                 1/1     Running   0

🚀 Deployment Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
NAME                READY   UP-TO-DATE   AVAILABLE
backend             2/2     2            2
frontend            2/2     2            2
cloud-sql-proxy     1/1     1            1

🌐 Service Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
NAME              TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)
backend-service   ClusterIP      10.0.0.10     <none>          8000/TCP
frontend          LoadBalancer   10.0.0.11     35.184.176.208  80:30123/TCP
cloud-sql-proxy   ClusterIP      10.0.0.12     <none>          3306/TCP

📡 Frontend Access
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Frontend URL: http://35.184.176.208
✅ Frontend is responding

💚 Health Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Backend:         ✅ Ready
Frontend:        ✅ Ready
Cloud SQL Proxy: ✅ Ready

📚 Useful Commands
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
View logs:
  kubectl logs -n voting-app -l app=backend -f

Run validation tests:
  ./scripts/deployment/validate-deployment.sh

Restart deployment:
  ./scripts/deployment/stop-deployment.sh
  ./scripts/deployment/start-deployment.sh
```

---

### validate-deployment.sh
Integration test suite.

```bash
./scripts/deployment/validate-deployment.sh
```

**Tests:**
1. Frontend connectivity (PING)
2. HTTP connectivity (curl)
3. API /results endpoint
4. API /vote POST endpoint
5. Vote persistence
6. Vote count accuracy

---

### check-deploy-status.sh
Quick status snapshot.

```bash
./scripts/deployment/check-deploy-status.sh
```

Lightweight version of `status-deployment.sh` for quick checks.

---

## 🔄 Common Workflows

### Deploy Fresh Application
```bash
./scripts/deployment/manage-deployment.sh start
./scripts/deployment/manage-deployment.sh status
./scripts/deployment/manage-deployment.sh validate
```

### Monitor Live Logs
```bash
# In separate terminal, keep status running
watch -n 5 './scripts/deployment/manage-deployment.sh status'

# In another, view backend logs
kubectl logs -n voting-app -l app=backend -f
```

### Full Redeploy (Clean Slate)
```bash
./scripts/deployment/manage-deployment.sh restart
```

### Test Just the Deployment
```bash
./scripts/deployment/manage-deployment.sh validate
```

### Troubleshoot Issues
```bash
# Check status
./scripts/deployment/manage-deployment.sh status

# View events
kubectl get events -n voting-app --sort-by='.lastTimestamp'

# Check specific pod
kubectl describe pod backend-0 -n voting-app
kubectl logs backend-0 -n voting-app
```

---

## 🐛 Troubleshooting

### Problem: Pods not starting
```bash
# Check status
./scripts/deployment/manage-deployment.sh status

# Describe problematic pod
kubectl describe pod <pod-name> -n voting-app

# View events
kubectl get events -n voting-app --sort-by='.lastTimestamp'
```

### Problem: Services not working
```bash
# Check if services are created
kubectl get svc -n voting-app

# Check if LoadBalancer has IP
kubectl get svc frontend -n voting-app -o wide
```

### Problem: API not responding
```bash
# Check backend is running
kubectl get pods -n voting-app -l app=backend

# View backend logs
kubectl logs -n voting-app -l app=backend -f

# Test from inside pod
kubectl exec -it backend-0 -n voting-app -- curl localhost:8000/results
```

### Problem: Database connection fails
```bash
# Check Cloud SQL Proxy
kubectl get pods -n voting-app -l app=cloud-sql-proxy

# Test proxy connectivity from backend
kubectl exec -it backend-0 -n voting-app -- \
  nc -zv cloud-sql-proxy 3306
```

---

## 📊 Script Dependencies

```
manage-deployment.sh
├── start-deployment.sh
│   └── Uses: infrastructure/kubernetes/01-secrets.yaml
│   └── Uses: infrastructure/kubernetes/04-cloud-sql-proxy-deployment.yaml
│   └── Uses: infrastructure/kubernetes/02-backend-deployment.yaml
│   └── Uses: infrastructure/kubernetes/03-frontend-deployment.yaml
│
├── stop-deployment.sh
│
├── status-deployment.sh
│   └── Uses: kubectl (get pods, services, deployments, events)
│
├── validate-deployment.sh
│   └── Uses: curl (API testing)
│   └── Uses: mysql (database testing)
│
└── restart
    ├── stop-deployment.sh
    └── start-deployment.sh
```

---

## 🔑 Configuration

Scripts use these defaults:
- **Cluster:** `voting-cluster`
- **Region:** `us-central1`
- **Namespace:** `voting-app`
- **Project:** Current gcloud project

To change, edit the script:
```bash
# In start-deployment.sh, stop-deployment.sh, status-deployment.sh
CLUSTER_NAME="voting-cluster"  # Change here
REGION="us-central1"           # Change here
NAMESPACE="voting-app"         # Change here
```

---

## 🎓 Learning Resources

- [Kubernetes Deployment Manifest](../../infrastructure/kubernetes/)
- [Cloud SQL Proxy Setup](./CLOUD_SQL_PROXY_SETUP.md)
- [Troubleshooting Guide](../TROUBLESHOOTING.md)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
