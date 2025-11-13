# 🚀 QUICK START - Get Running in 5 Minutes!

Choose your deployment method based on your experience level:

---

## 🐳 Option 1: Local with Docker Compose (EASIEST - 5 min)

**Best for:** Complete beginners, quick testing

### Step 1: Clone and Start
```bash
git clone https://github.com/octaviansandulescu/voting-app.git
cd voting-app
docker-compose up -d
```

### Step 2: Access Application
- **Frontend:** http://localhost
- **API:** http://localhost:8000/results

### Step 3: Test Voting
1. Open http://localhost in browser
2. Click "Vote for Dogs" or "Vote for Cats"
3. See results update in real-time!

### Step 4: Stop Everything
```bash
docker-compose down
```

**Expected Time:** 5 minutes ⏱️

---

## 🐋 Option 2: Docker (ISOLATED - 10 min)

**Best for:** Testing without affecting localhost, learning Docker

### Step 1: Navigate to Docker Setup
```bash
cd 2-DOCKER
```

### Step 2: Configure Environment
```bash
cp .env.docker.example .env.docker
# Edit .env.docker if needed (optional)
```

### Step 3: Build and Start
```bash
docker-compose -f docker-compose.yml up -d
```

### Step 4: Access Application
- Check the LoadBalancer IP in output
- Access: http://<DOCKER_IP>

**Expected Time:** 10 minutes ⏱️

---

## ☸️ Option 3: Kubernetes on GCP (PRODUCTION-LIKE - 30 min)

**Best for:** Learning Kubernetes, production deployment

### Prerequisites
- Google Cloud account with billing enabled
- `gcloud`, `kubectl`, `terraform` installed

### Step 1: Setup GCP Credentials
```bash
# Login to Google Cloud
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Create service account key
gcloud iam service-accounts keys create ~/certs/gke-default-sa-key.json \
  --iam-account=YOUR_SA_EMAIL
```

### Step 2: Set Environment Variables
```bash
export GCP_CREDENTIALS=~/certs/gke-default-sa-key.json
export GOOGLE_APPLICATION_CREDENTIALS="$GCP_CREDENTIALS"
```

### Step 3: Deploy Everything
```bash
cd voting-app
./scripts/deployment/start-deployment.sh
```

### Step 4: Wait for Completion (~15-20 min)
The script will:
- ✅ Create GKE cluster (3 nodes)
- ✅ Create Cloud SQL database
- ✅ Deploy backend and frontend
- ✅ Configure LoadBalancer

### Step 5: Access Application
```bash
# Get the external IP
kubectl get svc frontend-service -n voting-app

# Access in browser
http://<EXTERNAL_IP>
```

### Step 6: Check Status
```bash
./scripts/deployment/status-deployment.sh
```

### Step 7: Cleanup (to save costs)
```bash
./scripts/deployment/cleanup-resources.sh
# Type: DELETE
```

**Expected Time:** 30 minutes ⏱️
**Cost:** ~$2-3/day if left running

---

## 🆘 Quick Troubleshooting

### Problem: Port already in use
```bash
# Stop conflicting services
sudo systemctl stop mysql
docker-compose down
```

### Problem: Docker containers not starting
```bash
# Check logs
docker-compose logs backend
docker-compose logs db

# Restart
docker-compose restart
```

### Problem: Can't access Kubernetes application
```bash
# Check pods
kubectl get pods -n voting-app

# Check logs
kubectl logs -n voting-app deployment/backend
kubectl logs -n voting-app deployment/frontend
```

---

## ✅ Verification Checklist

After deployment, verify everything works:

- [ ] Frontend loads in browser
- [ ] Can vote for Dogs
- [ ] Can vote for Cats
- [ ] Vote counts update correctly
- [ ] API endpoint returns JSON: `/api/results`
- [ ] Data persists after refresh

---

## 📚 Next Steps

1. **Read Architecture:** [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
2. **Learn Deployment:** [docs/guides/](docs/guides/)
3. **Customize Application:** Edit `src/frontend/index.html`
4. **Add Features:** Modify `src/backend/main.py`

---

## 🎯 Learning Path

**Week 1:** Local Docker Compose → Understand application structure
**Week 2:** Docker isolated environment → Learn containerization
**Week 3:** Kubernetes deployment → Learn orchestration
**Week 4:** CI/CD pipeline → Automate deployments

---

## 💡 Tips for Success

- Start with **Local Docker Compose** first
- Read error messages carefully
- Check logs when things fail: `docker-compose logs` or `kubectl logs`
- Ask questions in Issues section
- Experiment in non-production first!

---

**Ready to start? Pick Option 1 above and begin! 🚀**
