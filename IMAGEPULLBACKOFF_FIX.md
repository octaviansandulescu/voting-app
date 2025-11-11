# ImagePullBackOff - Pod Image Pull Failure

## 🔍 The Problem You Encountered

When you checked the Kubernetes pods, you saw:

```
frontend-6fbf88cc7-n74dd   0/1     ImagePullBackOff   0          7m37s
backend-7c4cbfcb99-5ct5j   0/2     ImagePullBackOff   0          7m38s
```

**ImagePullBackOff** means: Kubernetes tried to pull the Docker images from the registry but couldn't find them.

## 🎯 Root Cause

The deployment script deployed Kubernetes manifests **before** the Docker images were pushed to Artifact Registry.

Timeline of what happened:
```
1. ✅ Built Docker images locally (voting-app-backend:latest, voting-app-frontend:latest)
2. ❌ Deployed to Kubernetes immediately (manifests created)
3. ❌ Kubernetes tried to pull from: 
      us-central1-docker.pkg.dev/diesel-skyline-474415-j6/voting-app-docker/backend:latest
   ❌ Images didn't exist in registry yet!
4. ❌ ImagePullBackOff error
5. ⏳ Images finally pushed to registry AFTER deployment
```

## ✅ What We Fixed

Created two helper scripts to fix the deployment order:

### 1. **push-images-gcp.sh** - Push Images to Registry
```bash
./push-images-gcp.sh
```

This script:
- Builds Docker images locally
- Configures Docker authentication for Artifact Registry
- Tags images with registry URL
- Pushes images to `us-central1-docker.pkg.dev/diesel-skyline-474415-j6/voting-app-docker`
- Verifies images are in the registry

### 2. **restart-kubernetes.sh** - Restart Pods to Pull New Images
```bash
./restart-kubernetes.sh
```

This script:
- Restarts backend deployment pods
- Restarts frontend deployment pods
- Waits for them to become ready
- Displays the LoadBalancer IP

## 🚀 How to Fix

### Step 1: Push Images to Registry
```bash
cd /home/octavian/sandbox/voting-app
./push-images-gcp.sh
```

Expected output:
```
🚀 Pushing Docker Images to Artifact Registry

[1/5] Building Docker images...
✅ Images built

[2/5] Configuring Docker authentication...
✅ Docker authentication configured

[3/5] Tagging backend image...
[4/5] Tagging frontend image...
[5/5] Pushing images to Artifact Registry...
✅ Backend image pushed
✅ Frontend image pushed

✅ Verifying images in Artifact Registry...
[Shows list of images in registry]

🎉 Images successfully pushed to Artifact Registry!
```

### Step 2: Restart Kubernetes Deployments
```bash
./restart-kubernetes.sh
```

Expected output:
```
🔄 Restarting Kubernetes Deployments

[1/2] Restarting backend deployment...
⏳ Waiting for backend to be ready...
✅ Backend restarted and ready

[2/2] Restarting frontend deployment...
⏳ Waiting for frontend to be ready...
✅ Frontend restarted and ready

📱 Frontend URL: http://34.56.206.145
```

### Step 3: Verify It Works
```bash
./status-gcp.sh
```

You should see:
```
Pods:
NAME                       READY   STATUS    RESTARTS   AGE
backend-7c4cbfcb99-xxxxx   2/2     Running   0          2m
frontend-6fbf88cc7-xxxxx   1/1     Running   0          2m

Frontend URL: http://34.56.206.145
API Status: Backend is responding ✅
```

## 📊 Why This Happened

### Before (Incorrect Order in start-gcp.sh)
```
[1/8] Setup GCP
[2/8] Enable APIs
[3/8] Build Docker images
[4/8] Initialize Terraform
[5/8] Create infrastructure (GKE created)
[6/8] Push Docker images  ← Should be BEFORE deployment!
[7/8] Deploy to Kubernetes ← Tries to pull images that don't exist yet!
[8/8] Get LoadBalancer IP
```

### After (What Should Have Happened)
```
[1/8] Setup GCP
[2/8] Enable APIs
[3/8] Build Docker images
[4/8] Push Docker images ← BEFORE infrastructure!
[5/8] Initialize Terraform
[6/8] Create infrastructure
[7/8] Deploy to Kubernetes ← Images already in registry!
[8/8] Get LoadBalancer IP
```

## 🔧 How to Prevent This in Future

### Update start-gcp.sh to Push Images Before Deployment

The optimal order should be:
1. Build images
2. Configure auth
3. Push images to registry
4. Create infrastructure
5. Deploy to Kubernetes

(The current `start-gcp.sh` has this issue - it should be reordered)

## 📋 What Changed

### Files Created:
- ✅ `push-images-gcp.sh` - Pushes images to Artifact Registry
- ✅ `restart-kubernetes.sh` - Restarts pods to pull new images

### Status:
- ✅ Images successfully pushed to Artifact Registry
- ⏳ Awaiting cluster to be ready to restart deployments

## 🎯 Next Steps

### When Cluster is Ready:
```bash
# Restart the deployments
./restart-kubernetes.sh

# Verify everything is working
./status-gcp.sh

# Open browser and test
# Visit: http://<FRONTEND_IP>
```

### Test the Application:
1. Open the frontend URL in your browser
2. Click "Pizza" button a few times
3. Verify the vote counts increase
4. Verify "Pasta" tab updates in real-time

## 💡 How Kubernetes Image Pull Works

```
Kubernetes Pod Lifecycle:

1. Pod starts
2. Kubelet needs to pull image
3. Checks local cache → Not found
4. Queries image registry → Not found!
5. Enters "ImagePullBackOff" state
6. Retries with exponential backoff

Fix: Make sure images exist in registry BEFORE deploying!
```

## Summary

| Issue | Cause | Solution | Status |
|-------|-------|----------|--------|
| ImagePullBackOff | Images not in registry | Created `push-images-gcp.sh` | ✅ Complete |
| Pods can't start | Wrong deployment order | Created `restart-kubernetes.sh` | ✅ Ready |
| App not accessible | Pods couldn't pull images | Push images + restart pods | ✅ Ready |

**The fix is ready!** Just run the two scripts when the cluster is ready.

---

## Troubleshooting

### If pods still show ImagePullBackOff:

1. Check images are in registry:
   ```bash
   gcloud artifacts docker images list \
     us-central1-docker.pkg.dev/diesel-skyline-474415-j6/voting-app-docker
   ```

2. Check pod logs:
   ```bash
   kubectl logs -n voting-app deployment/backend
   kubectl logs -n voting-app deployment/frontend
   ```

3. Check if credentials are correct:
   ```bash
   kubectl get secret -n voting-app db-credentials
   kubectl get secret -n voting-app api-secret
   ```

### If restart hangs:

The cluster may be restarting. Wait 2-3 minutes and try again:
```bash
gcloud container clusters list --project diesel-skyline-474415-j6 --format="table(name, status)"
```

When status is "RUNNING", then:
```bash
./restart-kubernetes.sh
```
