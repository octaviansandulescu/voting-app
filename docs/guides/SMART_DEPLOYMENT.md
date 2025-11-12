# Deployment Scripts - Smart Resource Detection

## Overview

The deployment scripts now feature **intelligent auto-detection** of GCP resources. They automatically:

- 🔍 **Detect** active Kubernetes clusters
- 🔎 **Find** existing namespaces
- 🗄️ **Locate** Cloud SQL instances
- ✨ **Create** resources if missing
- ⚠️ **Validate** everything before operations

No more hardcoded cluster or namespace names!

---

## Scripts

### 1. `detect-resources.sh` - Resource Discovery

**Purpose**: Auto-detects GCP resources for current project

**What it detects**:
- Kubernetes clusters (name, zone)
- Application namespaces
- Cloud SQL instances

**Exports variables**:
```bash
PROJECT_ID      # GCP project ID
CLUSTER_NAME    # Kubernetes cluster name
CLUSTER_ZONE    # Cluster zone (e.g., us-central1-a)
NAMESPACE       # Application namespace (voting-app)
SQL_INSTANCE    # Cloud SQL instance name
```

**Usage** (automatically sourced by other scripts):
```bash
# Manual usage if needed
source scripts/deployment/detect-resources.sh
echo "Cluster: $CLUSTER_NAME"
echo "Zone: $CLUSTER_ZONE"
echo "Namespace: $NAMESPACE"
```

---

### 2. `start-deployment.sh` - Deploy Application

**Purpose**: Deploy voting app to Kubernetes cluster

**Behavior**:
1. Checks prerequisites (gcloud, kubectl)
2. Detects existing cluster (or creates one with Terraform)
3. Gets cluster credentials
4. Creates/uses namespace
5. Applies all manifests

**Usage**:
```bash
./scripts/deployment/start-deployment.sh
```

**What happens**:
```
✅ Checking prerequisites
🔍 Detecting cluster
   (if not found, runs terraform apply)
🔑 Getting cluster credentials
📦 Setting up namespace
🚀 Applying manifests
   - Secrets
   - Backend deployment
   - Frontend deployment
   - Services
✅ Deployment complete
```

**Next step**:
```bash
./scripts/deployment/status-deployment.sh
```

---

### 3. `status-deployment.sh` - Check Health

**Purpose**: Comprehensive deployment health check

**Displays**:
- Cluster info (name, zone, project)
- Namespace status
- Pod status (running/pending/failed)
- Deployment readiness
- Services and IPs
- Frontend access URL
- API test results
- Cloud SQL status
- Overall health summary

**Usage**:
```bash
./scripts/deployment/status-deployment.sh
```

**Output example**:
```
📊 Cluster Information
  Cluster:   voting-cluster
  Zone:      us-central1-a
  Namespace: voting-app

🐳 Pod Status
  Total Pods:   4
  Running:      4

📡 Frontend Access
  ✅ Frontend URL: http://34.56.78.90
  ✅ Frontend responding (HTTP 200)

🧪 API Test
  ✅ API Endpoint: http://34.56.78.90/api/results
  Response: {"dogs":32,"cats":24}

💚 Health Summary
  Backend:  ✅ Ready
  Frontend: ✅ Ready
```

---

### 4. `stop-deployment.sh` - Remove Application

**Purpose**: Delete all voting app resources (keeps cluster)

**Behavior**:
1. Detects cluster and namespace
2. Requests confirmation
3. Deletes namespace (removes all pods, services, data)
4. Cluster remains for redeployment

**Usage**:
```bash
./scripts/deployment/stop-deployment.sh
```

**Confirmation**:
```
⚠️  WARNING: This will DELETE all voting app resources!

Cluster:   voting-cluster
Namespace: voting-app

This will delete:
  - All pods
  - All services
  - All persistent data

⛔ Type 'DELETE' to confirm:
```

**When to use**:
- Testing redeploys
- Cleanup before restarting
- Preserving cluster for other projects

---

### 5. `cleanup-resources.sh` - Complete Removal

**Purpose**: Delete EVERYTHING (cluster + namespace + database)

**Behavior**:
1. Detects all resources
2. Requests confirmation (requires "DELETE" to confirm)
3. Deletes namespace
4. Deletes cluster (5-10 minutes)
5. Deletes Cloud SQL instance (5-10 minutes)

**Usage**:
```bash
./scripts/deployment/cleanup-resources.sh
```

**Confirmation**:
```
⚠️  WARNING: This will DELETE the following resources:

  🔴 Kubernetes Cluster
     - Name: voting-cluster
     - Zone: us-central1-a
     - Pods: 4

  🔴 Cloud SQL Database
     - Instance: voting-app-db
     - ⚠️  ALL DATA WILL BE LOST

⛔ Type 'DELETE' to confirm complete removal:
```

**When to use**:
- Full cleanup before archiving project
- Starting completely fresh
- Removing all GCP resources to avoid costs

**Re-deploy after cleanup**:
```bash
cd 3-KUBERNETES/terraform && terraform apply
./scripts/deployment/start-deployment.sh
```

---

## Common Workflows

### Deploy Fresh
```bash
# If Terraform not initialized, scripts handle it
./scripts/deployment/start-deployment.sh

# Watch it deploy
./scripts/deployment/status-deployment.sh

# Check API
curl http://<EXTERNAL_IP>/api/results
```

### Redeploy After Testing
```bash
# Stop the app (keep cluster)
./scripts/deployment/stop-deployment.sh

# Wait for deletion
sleep 30

# Redeploy
./scripts/deployment/start-deployment.sh

# Verify
./scripts/deployment/status-deployment.sh
```

### Perform Cleanup (Full Removal)
```bash
# Delete everything
./scripts/deployment/cleanup-resources.sh

# Verify all gone
gcloud container clusters list
gcloud sql instances list
```

---

## Error Handling

### No Cluster Found
```
❌ No Kubernetes cluster found!

To create a cluster and deploy:
  cd 3-KUBERNETES/terraform && terraform apply
  ./scripts/deployment/start-deployment.sh
```

**Solution**: Run Terraform first:
```bash
cd 3-KUBERNETES/terraform
terraform init
terraform apply
```

### Namespace Not Found
```
❌ No application namespace found!
```

**Solution**: Script will create it automatically on `start-deployment.sh`

### LoadBalancer IP Pending
```
⏳ LoadBalancer IP pending
   (normal on first deployment, check again in 1-5 min)
```

**Solution**: Wait and rerun status:
```bash
sleep 60
./scripts/deployment/status-deployment.sh
```

---

## Advanced Usage

### Get Just the Cluster Name
```bash
source scripts/deployment/detect-resources.sh
echo $CLUSTER_NAME
```

### List All Detected Resources
```bash
source scripts/deployment/detect-resources.sh
echo "Cluster:    $CLUSTER_NAME"
echo "Zone:       $CLUSTER_ZONE"
echo "Namespace:  $NAMESPACE"
echo "SQL:        $SQL_INSTANCE"
echo "Project:    $PROJECT_ID"
```

### Test API Manually
```bash
# Get LoadBalancer IP
IP=$(kubectl get svc frontend -n voting-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test results endpoint
curl http://$IP/api/results

# Submit vote
curl -X POST http://$IP/api/vote \
  -H "Content-Type: application/json" \
  -d '{"vote":"dogs"}'
```

### View Cluster Logs
```bash
kubectl logs -n voting-app -l app=backend -f
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `gcloud CLI not found` | Install gcloud: `curl https://sdk.cloud.google.com \| bash` |
| `kubectl not found` | Install kubectl: `gcloud components install kubectl` |
| `Cluster 404 error` | Cluster not at expected location, scripts will auto-detect |
| `Permission denied` | Check GCP permissions: `gcloud auth login` |
| `LoadBalancer pending` | Normal - wait 2-5 minutes, rerun status check |
| `Pods not starting` | Check logs: `kubectl logs -n voting-app --all-containers=true` |

---

## Features Summary

### Smart Detection ✨
- Auto-finds cluster by name
- Prefers "voting-app" namespace, falls back gracefully
- Handles missing resources gracefully

### Automation 🤖
- Auto-creates cluster if missing
- Auto-initializes Terraform
- Auto-applies manifests in correct order

### User-Friendly 👥
- Clear confirmation prompts
- Helpful error messages
- Progress indicators
- Next-step suggestions

### Production-Ready 🚀
- Proper error handling
- Timeout management
- Validation before actions
- Comprehensive logging

---

## Integration

These scripts are designed to work together:

```
start-deployment.sh
    ↓
status-deployment.sh (verify health)
    ↓
stop-deployment.sh (pause without losing cluster)
    ↓
start-deployment.sh (redeploy)
    ↓
cleanup-resources.sh (final cleanup)
```

All scripts source `detect-resources.sh` for consistent resource discovery.

---

## See Also

- **DEPLOYMENT_SCRIPTS.md** - Overview of all 3 original scripts
- **KUBERNETES_SETUP.md** - Detailed Kubernetes configuration
- **TROUBLESHOOTING.md** - Common issues and solutions
- **3-KUBERNETES/terraform/** - Infrastructure as Code

