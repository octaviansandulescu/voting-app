# 🚀 GCP Deployment - Quick Reference Card

## Live Application
- **URL**: http://34.42.155.47
- **Status**: ✅ LIVE AND WORKING

---

## Quick Commands

### View Deployment Status
```bash
./check-gcp-status.sh
```

### Monitor in Real-time
```bash
./monitor-deployment.sh
```

### View Application Logs
```bash
# Frontend
kubectl logs -n voting-app -l app=frontend -f

# Backend
kubectl logs -n voting-app -l app=backend -f
```

### Test API Endpoints
```bash
# Health check
curl http://34.42.155.47/api/health

# Get results
curl http://34.42.155.47/api/results

# Submit vote
curl -X POST http://34.42.155.47/api/vote \
  -H "Content-Type: application/json" \
  -d '{"vote":"dogs"}'
```

### Access Database
```bash
gcloud sql connect voting-app-cluster-db \
  --user=voting_user \
  --database=voting_app_k8s
```

### Restart Components
```bash
# Restart frontend
kubectl rollout restart deployment/frontend -n voting-app

# Restart backend
kubectl rollout restart deployment/backend -n voting-app
```

### View Pod Status
```bash
kubectl get pods -n voting-app
```

### View Services
```bash
kubectl get svc -n voting-app
```

---

## Test Results (Latest)

| Endpoint | Method | Status | Response |
|----------|--------|--------|----------|
| / | GET | ✅ 200 | HTML page |
| /api/health | GET | ✅ 200 | {"status":"ok",...} |
| /api/results | GET | ✅ 200 | {"dogs":4,"cats":3,...} |
| /api/vote | POST | ✅ 200 | {"success":true,...} |

---

## Infrastructure Details

### GCP Project
- **Project ID**: diesel-skyline-474415-j6
- **Region**: us-central1

### Kubernetes
- **Cluster**: voting-app-cluster
- **Nodes**: 3 (e2-medium)
- **Namespace**: voting-app

### Database
- **Instance**: voting-app-cluster-db
- **Engine**: MySQL 8.0
- **Tier**: db-f1-micro
- **Database**: voting_app_k8s
- **User**: voting_user

### Container Registry
- **Frontend**: gcr.io/diesel-skyline-474415-j6/voting-app-frontend:v2
- **Backend**: gcr.io/diesel-skyline-474415-j6/voting-app-backend:latest

---

## Troubleshooting

### Application not responding?
1. Check pod status: `kubectl get pods -n voting-app`
2. Check logs: `kubectl logs -n voting-app -l app=frontend`
3. Restart deployment: `kubectl rollout restart deployment/frontend -n voting-app`

### API returning errors?
1. Check backend logs: `kubectl logs -n voting-app -l app=backend`
2. Verify database connection: `gcloud sql instances describe voting-app-cluster-db`
3. Test health endpoint: `curl http://34.42.155.47/api/health`

### Database not responding?
1. Check instance status: `gcloud sql instances describe voting-app-cluster-db`
2. Verify network connectivity from backend pods
3. Check Cloud SQL proxy logs

---

## Emergency Actions

### Scale Frontend to 3 replicas
```bash
kubectl scale deployment frontend --replicas=3 -n voting-app
```

### Scale Backend to 3 replicas
```bash
kubectl scale deployment backend --replicas=3 -n voting-app
```

### Force pull new image
```bash
kubectl set image deployment/frontend \
  frontend=gcr.io/diesel-skyline-474415-j6/voting-app-frontend:v2 \
  -n voting-app
```

### Tear Down Everything
```bash
./cleanup-gcp.sh
```

---

## External IP

**Frontend LoadBalancer**: 34.42.155.47

This is the public IP where the application is accessible.

---

**Last Updated**: 2025-11-11  
**System Status**: ✅ FULLY OPERATIONAL
