# 🔧 GCP MANAGEMENT SCRIPTS GUIDE

**Purpose**: Manage the complete lifecycle of your GCP voting app deployment
- Monitor status ✓
- Debug issues ✓
- Clean up resources safely ✓
- Prevent unexpected costs ✓

---

## 📊 Script 1: Status Check Script

### Purpose
Check the status of all components:
- GCP infrastructure (GKE, Cloud SQL, VPC)
- Kubernetes cluster and pods
- Services and LoadBalancer IP
- Application health
- Database connectivity
- Cost estimates

### Usage

```bash
./check-gcp-status.sh
```

**Time**: 1-2 minutes
**Cost**: FREE (just reading information)

### What It Shows

#### 1. GCP CLI Status
- gcloud authentication
- Current project
- Account info

#### 2. GKE Cluster Status
- Cluster name and status (RUNNING/STOPPING/etc)
- Cluster location
- Master version
- Node count

#### 3. GKE Nodes
- Node pool names
- Machine types
- Node count
- Status

#### 4. Cloud SQL Status
- Instance name
- Current state (RUNNABLE/STOPPED/etc)
- Database version (MySQL 8.0)
- Disk size

#### 5. Kubernetes Connection
- Cluster endpoint
- Connection status

#### 6. Kubernetes Namespace
- Namespace existence
- Namespace status (Active/Terminating)

#### 7. Deployments
- Backend deployment (replicas, status)
- Frontend deployment (replicas, status)
- Ready vs desired pods

#### 8. Pods Status
- All running pods
- Pod count by status
- Pod details (name, status, IP, node)

#### 9. Services & LoadBalancer
- Service types
- Cluster IPs
- LoadBalancer external IP
- Frontend access URL

#### 10. Application Health
- API health endpoint test
- Results endpoint test
- Response verification

#### 11. Resource Usage & Cost Estimates
- Current node count
- Cluster creation time
- Hourly cost estimate
- Daily cost estimate
- Monthly cost estimate
- Warning to cleanup

#### 12. Persistent Volumes
- Storage usage
- Volume claims

### Example Output

```
[STEP] GKE Cluster Status
✓ Cluster 'voting-app-cluster' exists
✓ Cluster status: RUNNING
ℹ Location: us-central1
ℹ Master version: 1.28.3
ℹ Node count: 3

[STEP] Kubernetes Pods
NAME                     READY   STATUS      RESTARTS   AGE
backend-5d7fc8cd8f-abc   1/1     Running     0          2m
backend-5d7fc8cd8f-def   1/1     Running     0          2m
frontend-7k9mxl2b3p-ghi  1/1     Running     0          1m
frontend-7k9mxl2b3p-jkl  1/1     Running     0          1m

ℹ Running pods: 4
ℹ Pending pods: 0

[STEP] Kubernetes Services & LoadBalancer
NAME       TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)
backend    ClusterIP      10.36.0.1     <none>         8000/TCP
frontend   LoadBalancer   10.36.0.2     35.224.XX.XX   80:30123/TCP

✓ Frontend LoadBalancer IP: 35.224.XX.XX
ℹ Access frontend at: http://35.224.XX.XX
ℹ API health: http://35.224.XX.XX/api/health

[STEP] Application Health
✓ Backend health check: PASS
✓ Results endpoint: PASS
```

### Use Cases

**When to run:**
- After deployment to verify everything is running
- Before running demos
- During troubleshooting
- To check current costs
- Before cleanup to verify status

**Debugging with status:**

If backend pods not ready:
```bash
./check-gcp-status.sh
# See "Backend: 1/2 ready"
# Then check logs:
kubectl logs deployment/backend -n voting-app
```

If LoadBalancer IP not assigned:
```bash
./check-gcp-status.sh
# See "LoadBalancer IP not yet assigned"
# Wait a few minutes and run again
```

If API tests fail:
```bash
./check-gcp-status.sh
# Check "Application Health" section
# If failed, check pod logs
kubectl describe pod <pod-name> -n voting-app
```

---

## 🧹 Script 2: Cleanup Script

### Purpose
Safely remove ALL GCP resources to:
- Stop costs
- Clean up infrastructure
- Reset for next deployment
- Free up project resources

### Usage

```bash
./cleanup-gcp.sh
```

**Time**: 10-15 minutes
**Cost Impact**: Saves $105-110/month

### What It Does

#### Stage 1: Delete Kubernetes Namespace
- Lists all pods in namespace
- Asks for confirmation
- Deletes namespace
- Waits for deletion to complete

**What gets deleted:**
- All deployments
- All pods
- All services
- Persistent volumes
- Secrets
- Configuration maps

#### Stage 2: Delete Terraform Infrastructure
- Checks Terraform is initialized
- Shows destroy plan
- Lists resources to be deleted
- Asks for confirmation
- Executes destroy
- Removes state files

**What gets deleted:**
- GKE cluster (3 nodes)
- Cloud SQL instance (MySQL)
- VPC network
- Subnets
- Firewall rules
- Service accounts
- Load balancers

#### Stage 3: Verify Cleanup
- Checks GKE clusters
- Checks Cloud SQL instances
- Checks VPC networks
- Checks service accounts
- Confirms all removed

#### Stage 4: Final Cleanup
- Removes kubeconfig entries
- Cleans local files
- Removes kubectl context

### Example Cleanup Session

```bash
$ ./cleanup-gcp.sh

╔════════════════════════════════════════════════════════════════════════╗
║              GCP CLEANUP SCRIPT                                        ║
║              Remove ALL Voting App Resources                           ║
╚════════════════════════════════════════════════════════════════════════╝

⚠ WARNING: This will DELETE all GCP resources!
⚠ This action cannot be undone!

Do you want to continue with cleanup? (yes/no): yes

[STEP] Checking Prerequisites
✓ gcloud found
✓ kubectl found
✓ Terraform found

[STEP] Stage 1: Delete Kubernetes Namespace
⚠ This will delete the voting app deployment from Kubernetes
ℹ Namespace: voting-app
ℹ Pods to delete:
  - backend-5d7fc8cd8f-abc
  - backend-5d7fc8cd8f-def
  - frontend-7k9mxl2b3p-ghi
  - frontend-7k9mxl2b3p-jkl

Delete Kubernetes namespace and all resources? (yes/no): yes

ℹ Deleting namespace voting-app...
namespace "voting-app" deleted
ℹ Waiting for namespace deletion...
.....

✓ Kubernetes namespace deleted

[STEP] Stage 2: Delete Terraform Infrastructure
⚠ This will destroy ALL GCP resources created by Terraform:
  • GKE cluster (voting-app-cluster)
  • Cloud SQL instance (MySQL)
  • VPC network
  • Service accounts
  • All associated resources

Destroy all Terraform resources? (yes/no): yes

ℹ Destroying infrastructure...
Apply complete! Resources destroyed.

✓ Terraform infrastructure destroyed

[STEP] Stage 3: Verifying Cleanup
ℹ Checking GKE clusters...
✓ GKE cluster removed
ℹ Checking Cloud SQL instances...
✓ Cloud SQL instance removed
ℹ Checking VPC networks...
✓ VPC network removed
ℹ Checking service accounts...
✓ Service accounts removed

[STEP] Stage 4: Final Cleanup
ℹ Cleaning kubeconfig...
✓ Kubeconfig cleaned

╔════════════════════════════════════════════════════════════════════════╗
║                                                                        ║
║              CLEANUP COMPLETE                                         ║
║                                                                        ║
╚════════════════════════════════════════════════════════════════════════╝

✓ Kubernetes resources deleted
✓ Terraform infrastructure destroyed
✓ GCP resources removed
✓ No active resources remaining

Cost Impact:
  • Previous monthly cost: ~$105-110
  • Current monthly cost: $0
  • Savings: $105-110/month
```

### Important Notes

**Confirmation prompts:**
- Script asks for confirmation before each major action
- Type "yes" (not just "y")
- Type "no" to cancel

**What is NOT deleted:**
- GitHub repository
- Local code files
- Terraform code
- Documentation
- Scripts

**After cleanup:**
- GKE cluster gone
- Cloud SQL gone
- Network cleaned up
- No charges will accrue
- Can re-deploy anytime with `./test-gcp-deployment.sh`

---

## 🔄 Complete Workflow

### Full Deployment & Testing Cycle

```bash
# 1. Deploy
./test-gcp-deployment.sh
# Wait 20-25 minutes

# 2. Check status
./check-gcp-status.sh
# Verify everything running

# 3. Run demos
# Browser: http://EXTERNAL_IP
# Test voting functionality

# 4. Check again
./check-gcp-status.sh
# Verify app still healthy

# 5. Cleanup when done
./cleanup-gcp.sh
# Remove all resources
```

---

## 🛠️ Troubleshooting with Scripts

### Issue: Pods not starting

```bash
./check-gcp-status.sh
# Look for "Pending pods" section

# Then get pod details
kubectl describe pod <pod-name> -n voting-app

# And check logs
kubectl logs <pod-name> -n voting-app
```

### Issue: LoadBalancer IP taking too long

```bash
./check-gcp-status.sh
# Look for LoadBalancer IP status

# Wait a few minutes (can take 5-10 min)
# Run again:
./check-gcp-status.sh
```

### Issue: API tests failing

```bash
./check-gcp-status.sh
# Look at "Application Health" section

# If failed, check backend logs:
kubectl logs deployment/backend -n voting-app

# Check pod details:
kubectl describe deployment backend -n voting-app
```

### Issue: Cleanup stuck

```bash
# Check what's still there:
./check-gcp-status.sh

# Run cleanup with more verbosity:
./cleanup-gcp.sh

# Check GCP Console manually:
# https://console.cloud.google.com
```

---

## 📋 Quick Commands Reference

### Status Checking
```bash
./check-gcp-status.sh                              # Full status
kubectl get pods -n voting-app                     # Just pods
kubectl get svc -n voting-app                      # Just services
kubectl get nodes                                  # Just nodes
```

### Debugging
```bash
kubectl logs deployment/backend -n voting-app      # Backend logs
kubectl logs deployment/frontend -n voting-app     # Frontend logs
kubectl describe deployment backend -n voting-app  # Full deployment info
kubectl top nodes                                  # Node resources
kubectl top pods -n voting-app                     # Pod resources
```

### Cleanup
```bash
./cleanup-gcp.sh                                   # Full cleanup
kubectl delete namespace voting-app                # Just delete K8s
cd 3-KUBERNETES/terraform && terraform destroy     # Just destroy infra
```

---

## 📈 Cost Tracking

### Using status script to track costs:

```bash
./check-gcp-status.sh
# Look for "Cost Estimation" section

# Example output:
# Hourly: ~$0.15
# Daily (24h): ~$3.6
# Monthly: ~$108
```

### Cost calculations:
- 3 GKE nodes: ~$0.05/hour each = $0.15/hour
- Cloud SQL: FREE (f1-micro tier)
- Network: ~$0.01/hour
- **Total**: ~$3.6/day or ~$108/month

### Saving money:
- Don't leave running 24/7
- Use for testing/demos only
- **Always cleanup after testing**
- Run `./cleanup-gcp.sh` when done

---

## ⚠️ Important Safety Notes

### Before Cleanup
- Save any important data
- Screenshots of demos
- Verify all testing complete

### Cleanup Sequence
1. Kubernetes namespace deleted first
2. GCP infrastructure destroyed
3. Verification step
4. Final cleanup

### Cannot Be Undone
- Cleanup is permanent
- Data will be lost
- Need to re-deploy to use again

### Cost Prevention
- Set billing alerts in GCP Console
- Always cleanup after testing
- Check status regularly

---

## 🎯 Usage Summary

| Task | Command | Time | Cost |
|------|---------|------|------|
| Check status | `./check-gcp-status.sh` | 1-2 min | FREE |
| Full deployment | `./test-gcp-deployment.sh` | 20-25 min | ~$2 |
| Cleanup | `./cleanup-gcp.sh` | 10-15 min | Saves $105-110/mo |
| Debug pods | `kubectl logs ...` | 1-2 min | FREE |
| Quick check | `kubectl get pods` | < 1 min | FREE |

---

## 📞 Help & Support

### Check documentation:
- GCP_QUICK_START.md - Quick reference
- GCP_DEPLOYMENT_VERIFICATION.md - Detailed guide
- docs/TROUBLESHOOTING.md - Problem solving

### Check status:
```bash
./check-gcp-status.sh
```

### View logs:
```bash
kubectl logs deployment/backend -n voting-app
```

---

## ✨ Final Notes

- **Always cleanup when done** - prevents charges
- **Check status regularly** - monitor health
- **Keep scripts updated** - use latest versions
- **Document your testing** - remember what you tested

---

**Questions?** Check the troubleshooting docs or status script output!
