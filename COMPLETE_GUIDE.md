# Complete Project Structure & Deployment Guide

## 📁 Project Structure

```
voting-app/
├── .github/
│   └── workflows/
│       ├── ci.yml                          # Unit tests on every push
│       └── build-push-gcp.yml             # Build & push images to GCP
│
├── src/
│   ├── backend/
│   │   ├── main.py                         # FastAPI application
│   │   ├── database.py                     # SQLAlchemy models & connection
│   │   ├── Dockerfile                      # Backend container
│   │   ├── requirements.txt                # Python dependencies
│   │   └── tests/
│   │       ├── __init__.py
│   │       └── test_api.py                 # Backend tests
│   │
│   └── frontend/
│       ├── index.html                      # Main page
│       ├── style.css                       # Styles
│       ├── script.js                       # Frontend logic
│       ├── nginx.conf                      # Nginx config
│       └── Dockerfile                      # Frontend container
│
├── k8s/                                    # Kubernetes manifests
│   ├── 01-namespace-secret.yaml           # Namespace & DB credentials
│   ├── 02-backend-deployment.yaml         # Backend pods & service
│   ├── 03-frontend-deployment.yaml        # Frontend pods & service
│   └── 04-ingress.yaml                    # Ingress rules
│
├── terraform/                             # Infrastructure as Code
│   ├── main.tf                            # GKE, Cloud SQL, VPC
│   ├── variables.tf                       # Input variables
│   └── terraform.tfvars.example           # Template (copy & edit)
│
├── docs/
│   └── GCP_DEPLOYMENT.md                  # Detailed GCP guide
│
├── scripts (in root)/
│   ├── validate.sh                        # Check prerequisites
│   ├── setup-gcp.sh                       # Auto-configure
│   ├── deploy.sh                          # Deploy infrastructure & app
│   └── docker-compose.yml                 # Local development
│
├── docs (in root)/
│   ├── README.md                          # Project overview
│   ├── GCP_QUICKSTART.md                  # Quick start (3 minutes)
│   ├── LOCAL_TESTING.md                   # Local testing guide
│   ├── DEPLOYMENT_CHECKLIST.md            # Step-by-step checklist
│   └── .gitignore                         # Git ignore patterns
│
└── deploy.sh                              # Main deployment script
```

## 🚀 Quick Deployment Path

### Path 1: Local Development (Docker Compose)
```
5 minutes
│
├─ 1. Clone repo
├─ 2. docker-compose up --build
├─ 3. Open http://localhost
└─ ✓ Running locally
```

### Path 2: GCP Deployment (Recommended)
```
15-30 minutes
│
├─ 1. Clone repo
├─ 2. ./validate.sh
├─ 3. ./setup-gcp.sh
├─ 4. ./deploy.sh
├─ 5. Wait for GKE cluster creation
├─ 6. Wait for Cloud SQL initialization
├─ 7. Pods become ready
└─ ✓ Application live on GCP
```

## 📊 Architecture Overview

### Local (docker-compose)
```
┌──────────────────────────────┐
│   Docker Compose (Local)     │
│                              │
│  ┌──────────┐  ┌──────────┐ │
│  │Frontend  │  │Backend   │ │
│  │(Nginx)   │→ │(FastAPI) │ │
│  └──────────┘  └─────┬────┘ │
│                      │       │
│  ┌──────────────────┴─────┐ │
│  │     MySQL (Local)      │ │
│  │   votes table          │ │
│  └────────────────────────┘ │
│                              │
└──────────────────────────────┘
```

### GCP (Kubernetes + Cloud SQL)
```
┌─────────────────────────────────────────────────────────┐
│          Google Cloud Platform (GCP)                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  GKE Cluster (voting-app-cluster)                │ │
│  │                                                   │ │
│  │  ┌─────────────────────────────────────────────┐ │ │
│  │  │  Frontend Pods (Replicas: 2)               │ │ │
│  │  │  - LoadBalancer Service (External IP)      │ │ │
│  │  └────────────────┬──────────────────────────┘ │ │
│  │                   │                             │ │
│  │  ┌────────────────▼──────────────────────────┐ │ │
│  │  │  Backend Pods (Replicas: 2)              │ │ │
│  │  │  - ClusterIP Service                     │ │ │
│  │  │  - Cloud SQL Proxy Sidecar               │ │ │
│  │  └────────────────┬──────────────────────────┘ │ │
│  │                   │                             │ │
│  └───────────────────┼─────────────────────────────┘ │
│                      │                               │
│  ┌───────────────────▼────────────────────────────┐ │
│  │  Cloud SQL (MySQL 8.0)                        │ │
│  │  - Instance: voting-app-mysql                 │ │
│  │  - Database: votingapp                        │ │
│  │  - Private IP (VPC)                           │ │
│  └─────────────────────────────────────────────┘ │
│                                                   │
└─────────────────────────────────────────────────────────┘
```

## 🔄 Deployment Workflow

### 1. **Local Development** → **Testing**
```bash
# Start local environment
docker-compose up --build

# Run tests
cd src/backend
TESTING=true pytest tests/ -v

# Manual testing in browser
# http://localhost
```

### 2. **Push to GitHub** → **CI/CD**
```bash
git push origin main

# GitHub Actions runs:
# - Unit tests (backend)
# - Linting (if configured)
# - Build Docker images
# - Push to GCP Artifact Registry
```

### 3. **Deploy to GCP** → **Production**
```bash
# Automatic setup
./validate.sh    # Check prerequisites
./setup-gcp.sh   # Auto-configure

# Deploy
./deploy.sh      # Create GCP infrastructure + deploy app
```

## 🔐 Security Layers

| Layer | Technology | Protection |
|-------|-----------|-----------|
| **Network** | VPC + Private IPs | No direct internet access to DB |
| **Database** | Cloud SQL IAM Auth | Secure credentials in K8s Secrets |
| **Communication** | Cloud SQL Proxy | Encrypted tunnel to database |
| **RBAC** | Kubernetes RBAC | Service accounts with minimal permissions |
| **Secrets** | K8s Secrets | Encrypted at rest |

## 📈 Scaling Options

### Manual Scaling
```bash
# Scale backend
kubectl scale deployment/backend --replicas=5 -n voting-app

# Scale frontend
kubectl scale deployment/frontend --replicas=5 -n voting-app
```

### Auto-Scaling (Optional - requires HPA)
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## 💰 Cost Estimation (Monthly)

| Resource | Cost | Notes |
|----------|------|-------|
| GKE Cluster | ~$20-30 | 1 e2-medium node |
| Cloud SQL | ~$15-20 | db-f1-micro (shared) |
| Network | ~$1-5 | Egress charges |
| Artifact Registry | ~$0.10 | Minimal storage |
| **Total** | **~$40-60** | First month premium |

**Cost Reduction Tips:**
- Use preemptible nodes (-70%)
- Use Cloud SQL shared instance (-50%)
- Delete cluster when not in use

## 📚 Key Files & Their Purpose

| File | Purpose | Modified For |
|------|---------|-------------|
| `main.tf` | Define GCP infrastructure | Your project ID, region |
| `terraform.tfvars` | Variable values | DB password, region |
| `01-namespace-secret.yaml` | K8s namespace & secrets | DB credentials |
| `02-backend-deployment.yaml` | Backend configuration | Image registry URL |
| `03-frontend-deployment.yaml` | Frontend configuration | Image registry URL |
| `setup-gcp.sh` | Automate configuration | Usually no changes needed |
| `deploy.sh` | Orchestrate deployment | Usually no changes needed |

## ✅ Verification Checklist

```bash
# After deployment, verify:

# 1. Pods running
kubectl get pods -n voting-app
# Expected: backend-XXX, frontend-XXX pods in Running state

# 2. Services created
kubectl get svc -n voting-app
# Expected: backend ClusterIP, frontend LoadBalancer with EXTERNAL-IP

# 3. Frontend URL
kubectl get svc frontend -n voting-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
# Expected: Public IP address

# 4. Database connected
kubectl logs deployment/backend -n voting-app | grep "Database connected"
# Expected: Success message

# 5. API working
curl http://<FRONTEND-IP>/api/results
# Expected: {"dogs":0,"cats":0} or current vote count
```

## 🆘 Getting Help

| Issue | Command | Docs |
|-------|---------|------|
| Setup prerequisites | `./validate.sh` | [GCP_QUICKSTART.md](GCP_QUICKSTART.md) |
| Auto-configure GCP | `./setup-gcp.sh` | [GCP_QUICKSTART.md](GCP_QUICKSTART.md) |
| Deploy to GCP | `./deploy.sh` | [GCP_DEPLOYMENT.md](docs/GCP_DEPLOYMENT.md) |
| Local testing | `docker-compose up` | [LOCAL_TESTING.md](LOCAL_TESTING.md) |
| Step-by-step guide | Review checklist | [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) |
| Detailed info | Full guide | [GCP_DEPLOYMENT.md](docs/GCP_DEPLOYMENT.md) |

## 🎯 Next Advanced Steps (Optional)

1. **Argo CD** - GitOps continuous deployment
2. **Monitoring** - Google Cloud Monitoring / Prometheus
3. **Logging** - Google Cloud Logging / ELK
4. **CI/CD Advanced** - Cloud Build integration
5. **Custom Domain** - Cloud DNS setup
6. **SSL/TLS** - Cert-Manager integration
7. **Multi-region** - Cross-region deployment

---

**Ready to deploy?** Start with:
```bash
./validate.sh
./setup-gcp.sh
./deploy.sh
```
