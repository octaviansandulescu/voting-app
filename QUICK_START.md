# 🚀 Quick Start Guide

## Start Here in 5 Minutes

### Option 1: Docker (Easiest)
```bash
cd voting-app
docker-compose up -d
open http://localhost
```

### Option 2: Kubernetes
```bash
./scripts/deployment/start-deployment.sh
./scripts/deployment/status-deployment.sh
# Get LoadBalancer IP and open in browser
```

### Option 3: Local (Python)
```bash
cd voting-app
python3 -m venv .venv
source .venv/bin/activate
pip install -r src/backend/requirements.txt
python src/backend/main.py
```

---

## Test the API

```bash
# Get votes
curl http://localhost/api/results

# Cast a vote
curl -X POST http://localhost/api/vote \
  -H "Content-Type: application/json" \
  -d '{"vote":"dogs"}'
```

---

## Key Commands

| Task | Command |
|------|---------|
| Start Docker | `docker-compose up -d` |
| Stop Docker | `docker-compose down` |
| Deploy to K8s | `./scripts/deployment/start-deployment.sh` |
| Check K8s status | `./scripts/deployment/status-deployment.sh` |
| Stop K8s | `./scripts/deployment/stop-deployment.sh` |
| View logs | `docker-compose logs -f backend` |
| Run tests | `pytest src/backend/tests/` |

---

## Documentation

- 📖 **README.md** - Full learning path
- 🔒 **SECURITY.md** - Best practices
- 🧪 **TESTING_FUNDAMENTALS.md** - Why tests matter
- 🐳 **DOCKER_SETUP.md** - Docker guide
- ☸️ **KUBERNETES_SETUP.md** - K8s guide
- 🚀 **DEPLOYMENT_SCRIPTS.md** - Script reference
- 📊 **FINAL_STATUS.md** - Project overview

---

## Status

✅ DOCKER: Ready
✅ KUBERNETES: Ready  
✅ SECURITY: Hardened
✅ DOCUMENTATION: Complete

---

**That's it! You're ready to go!** 🎉
