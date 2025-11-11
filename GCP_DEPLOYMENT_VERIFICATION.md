# 🚀 GCP DEPLOYMENT & VERIFICATION GUIDE

This guide will help you deploy the voting app to Google Cloud Platform and verify it works.

---

## 📋 Prerequisites

✅ **Already Verified:**
- `gcloud` CLI installed: `/usr/bin/gcloud`
- GCP Project: `diesel-skyline-474415-j6`
- Authenticated account: `octavian.sandulescu@gmail.com`
- Terraform: v1.13.5
- Google provider: v5.45.2

---

## 🎯 STEP-BY-STEP DEPLOYMENT

### STEP 1: Create Terraform Plan

```bash
cd /home/octavian/sandbox/voting-app/3-KUBERNETES/terraform
terraform plan -out=tfplan
```

**Expected Output:**
- Plan to create: GKE cluster, Cloud SQL, VPC, Firewall rules, Service accounts
- ~25-30 resources to create
- No errors

### STEP 2: Apply Terraform Configuration

```bash
cd /home/octavian/sandbox/voting-app/3-KUBERNETES/terraform
terraform apply tfplan
```

**Expected Duration:** 15-20 minutes
**What Gets Created:**
- GKE Cluster (3 nodes, n1-standard-2)
- Cloud SQL MySQL instance (db-f1-micro)
- VPC Network (10.0.0.0/8)
- Subnets and routing
- Service accounts and IAM

### STEP 3: Get Kubernetes Credentials

```bash
gcloud container clusters get-credentials voting-app-cluster --region us-central1 --project diesel-skyline-474415-j6
```

**Expected Output:**
```
Fetching cluster endpoint and auth data.
kubeconfig entry generated for voting-app-cluster.
```

### STEP 4: Verify Cluster Connection

```bash
kubectl cluster-info
kubectl get nodes
```

**Expected Output:**
- Cluster IP address
- 3 nodes in READY status

### STEP 5: Deploy Kubernetes Manifests

```bash
cd /home/octavian/sandbox/voting-app/3-KUBERNETES/k8s
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-secrets.yaml
kubectl apply -f 02-backend-deployment.yaml
kubectl apply -f 03-frontend-deployment.yaml
```

**Expected Output:**
```
namespace/voting-app created
secret/db-secret created
deployment.apps/backend created
service/backend created
deployment.apps/frontend created
service/frontend created
```

### STEP 6: Wait for LoadBalancer IP

```bash
kubectl get svc frontend -n voting-app -w
```

**Wait for external IP to be assigned:**
```
NAME       TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)        AGE
frontend   LoadBalancer   10.x.x.x      xx.xx.xx.xx    80:xxxxx/TCP   1m
```

This may take 2-3 minutes.

### STEP 7: Check Pod Status

```bash
kubectl get pods -n voting-app
kubectl get deployments -n voting-app
kubectl get services -n voting-app
```

**Expected Output:**
- 2 backend pods in RUNNING status
- 2 frontend pods in RUNNING status
- All services visible

### STEP 8: Check Pod Logs

```bash
# Backend logs
kubectl logs -f deployment/backend -n voting-app

# Frontend logs
kubectl logs -f deployment/frontend -n voting-app
```

**Expected Output:**
- Backend: "Running in kubernetes mode"
- Frontend: Nginx startup messages

---

## ✅ VERIFICATION TESTS

### TEST 1: Check Cluster Status

```bash
kubectl get nodes -o wide
```

### TEST 2: Check Pod Health

```bash
kubectl get pods -n voting-app -o wide
```

### TEST 3: Check Services

```bash
kubectl get svc -n voting-app
```

### TEST 4: Test Backend API

Replace `EXTERNAL_IP` with actual IP from LoadBalancer:

```bash
EXTERNAL_IP="xx.xx.xx.xx"

# Test health check
curl http://$EXTERNAL_IP/api/health

# Get initial results
curl http://$EXTERNAL_IP/api/results

# Submit a vote for dogs
curl -X POST http://$EXTERNAL_IP/api/vote \
  -H "Content-Type: application/json" \
  -d '{"vote":"dogs"}'

# Get updated results
curl http://$EXTERNAL_IP/api/results
```

### TEST 5: Test Frontend UI

Open in browser:
```
http://EXTERNAL_IP
```

**Expected:**
- Page loads with voting interface
- Shows "Dogs" and "Cats" buttons
- Results display
- Can vote and see counts update

### TEST 6: API Endpoint Tests

```bash
EXTERNAL_IP="xx.xx.xx.xx"

# Test 1: Health check
echo "Test 1: Health check"
curl -s http://$EXTERNAL_IP/api/health | jq .
# Expected: {"status":"healthy","mode":"kubernetes"}

# Test 2: Get results
echo "Test 2: Get results"
curl -s http://$EXTERNAL_IP/api/results | jq .
# Expected: {"dogs":0,"cats":0,"total":0} (or current counts)

# Test 3: Submit vote
echo "Test 3: Submit vote for dogs"
curl -s -X POST http://$EXTERNAL_IP/api/vote \
  -H "Content-Type: application/json" \
  -d '{"vote":"dogs"}' | jq .
# Expected: {"message":"Vote recorded successfully"}

# Test 4: Verify vote was counted
echo "Test 4: Get results after vote"
curl -s http://$EXTERNAL_IP/api/results | jq .
# Expected: {"dogs":1,"cats":0,"total":1}

# Test 5: Submit vote for cats
echo "Test 5: Submit vote for cats"
curl -s -X POST http://$EXTERNAL_IP/api/vote \
  -H "Content-Type: application/json" \
  -d '{"vote":"cats"}' | jq .
# Expected: {"message":"Vote recorded successfully"}

# Test 6: Final results
echo "Test 6: Final results"
curl -s http://$EXTERNAL_IP/api/results | jq .
# Expected: {"dogs":1,"cats":1,"total":2}
```

---

## 📊 TROUBLESHOOTING

### Issue: Pods not running

```bash
# Check pod status
kubectl describe pod <pod-name> -n voting-app

# Check pod logs
kubectl logs <pod-name> -n voting-app

# Check events
kubectl get events -n voting-app
```

### Issue: LoadBalancer IP not assigned

```bash
# Wait a few more minutes
kubectl get svc frontend -n voting-app -w

# Check service status
kubectl describe svc frontend -n voting-app
```

### Issue: Database connection failed

```bash
# Check if Cloud SQL is running
gcloud sql instances list

# Check backend logs
kubectl logs deployment/backend -n voting-app

# Check if secrets are correct
kubectl get secret db-secret -n voting-app -o yaml
```

### Issue: Cannot access frontend

```bash
# Verify service type
kubectl get svc frontend -n voting-app

# Check if it's LoadBalancer (not ClusterIP)
kubectl describe svc frontend -n voting-app
```

---

## 🧹 CLEANUP (When Done)

To avoid GCP charges, destroy resources:

```bash
# Delete Kubernetes resources
kubectl delete namespace voting-app

# Destroy Terraform infrastructure
cd /home/octavian/sandbox/voting-app/3-KUBERNETES/terraform
terraform destroy
```

---

## 📈 EXPECTED COSTS

- **GKE Cluster (3 nodes):** ~$100/month
- **Cloud SQL (free tier):** $0
- **Network charges:** ~$5-10/month
- **Total when running:** ~$105-110/month

⚠️ **Remember to destroy when not testing!**

---

## 🎉 SUCCESS CRITERIA

✅ All 6 tests passed
✅ Frontend loads in browser
✅ API endpoints respond
✅ Votes are recorded
✅ Results are stored in database
✅ Pod logs show no errors

When all criteria met: **GCP deployment is successful!**
