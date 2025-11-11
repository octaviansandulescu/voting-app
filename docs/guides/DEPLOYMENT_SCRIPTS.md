# Kubernetes Deployment Scripts

## 🎯 Three Essential Scripts

| Script | Purpose | Time |
|--------|---------|------|
| `./scripts/deployment/start-deployment.sh` | Deploy application | ~3-5 min |
| `./scripts/deployment/status-deployment.sh` | Check health | ~10 sec |
| `./scripts/deployment/stop-deployment.sh` | Delete resources | ~1 min |

---

## 🚀 Deploy Application

```bash
./scripts/deployment/start-deployment.sh
```

**Does:**
- ✅ Gets cluster credentials
- ✅ Creates namespace & secrets
- ✅ Deploys Backend & Frontend
- ✅ Waits for pods ready
- ✅ Shows LoadBalancer URL

**Output:**
```
✅ Namespace created
✅ Secrets created
✅ Backend deployment applied
✅ Frontend deployment applied
✅ Backend ready
✅ Frontend ready
✅ Frontend available at: http://35.184.176.208
```

---

## 📊 Check Status

```bash
./scripts/deployment/status-deployment.sh
```

**Shows:**
- 🐳 Pod status (running/not ready)
- 🚀 Deployment status
- 🌐 Services & LoadBalancer IP
- 📡 Frontend URL
- 💚 Health summary

**Example output:**
```
Cluster:   voting-cluster
Namespace: voting-app
Pods: 4/4 Running ✅

Backend:  ✅ Ready
Frontend: ✅ Ready

Frontend: http://35.184.176.208 ✅
```

---

## 🛑 Stop & Delete

```bash
./scripts/deployment/stop-deployment.sh
```

**⚠️ WARNING:** Deletes everything:
- ❌ All pods & services
- ❌ Load balancer
- ❌ All data
- ❌ Namespace

**Requires confirmation** before executing.

---

## 🔄 Workflow

### 1️⃣ Deploy
```bash
./scripts/deployment/start-deployment.sh
```

### 2️⃣ Check Status
```bash
./scripts/deployment/status-deployment.sh
```

### 3️⃣ Test
```bash
# Get URL from status output
curl http://35.184.176.208/api/results
# Output: {"dogs": 87, "cats": 42, "total": 129}
```

### 4️⃣ Vote
```bash
curl -X POST http://35.184.176.208/api/vote \
  -H "Content-Type: application/json" \
  -d '{"vote":"dogs"}'
```

### 5️⃣ Clean Up
```bash
./scripts/deployment/stop-deployment.sh
```

---

## 🐛 Troubleshooting

### Pods not starting?
```bash
./scripts/deployment/status-deployment.sh
kubectl describe pod backend-0 -n voting-app
```

### LoadBalancer IP not assigned?
```bash
# Wait 1-5 minutes and retry
./scripts/deployment/status-deployment.sh
```

### Check logs
```bash
kubectl logs -n voting-app -l app=backend -f
```

---

## 🔧 Configuration

Edit in each script:

```bash
CLUSTER_NAME="voting-cluster"  # Your GKE cluster
REGION="us-central1"           # Your region
NAMESPACE="voting-app"         # Your namespace
```

---

## 📖 See Also

- [`README.md`](../../README.md) - Main guide
- [`DEPLOYMENT_STATUS.md`](../../DEPLOYMENT_STATUS.md) - Status & next steps
- [`CLOUD_SQL_PROXY_SETUP.md`](CLOUD_SQL_PROXY_SETUP.md) - Advanced security setup
