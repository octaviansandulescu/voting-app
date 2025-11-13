# ❓ Frequently Asked Questions (FAQ)

Quick answers to common questions about the Voting App project.

---

## 🎯 General Questions

### Q: What is this project?
**A:** A simple voting application (Dogs vs Cats) that demonstrates:
- Full-stack development (Frontend + Backend + Database)
- Containerization with Docker
- Orchestration with Kubernetes
- Infrastructure as Code with Terraform
- Deployment to Google Cloud Platform (GCP)

**Use case:** Learning DevOps practices and cloud deployment.

---

### Q: Is this production-ready?
**A:** **No**, this is an educational/demo project. For production, you would need to add:

**Security:**
- ✅ HTTPS/SSL certificates
- ✅ Authentication & authorization
- ✅ Input validation & sanitization
- ✅ Rate limiting
- ✅ Security headers
- ✅ Secrets management (Vault, Secret Manager)

**Reliability:**
- ✅ High availability (multiple zones)
- ✅ Auto-scaling
- ✅ Backup & disaster recovery
- ✅ Monitoring & alerting
- ✅ Logging (ELK stack, Cloud Logging)

**Performance:**
- ✅ CDN for static assets
- ✅ Database connection pooling
- ✅ Caching (Redis, Memcached)
- ✅ Load testing

---

### Q: How much does it cost to run on GCP?
**A:** Estimated costs (as of 2025):

| Component | Type | Monthly Cost |
|-----------|------|--------------|
| GKE Cluster (3 nodes) | e2-medium preemptible | ~$50 |
| Cloud SQL | db-f1-micro | ~$15 |
| Load Balancer | Standard | ~$20 |
| Network egress | Varies | ~$5-10 |
| **TOTAL** | | **~$90-100/month** |

**To save costs:**
- Use preemptible nodes (done ✅)
- Stop cluster when not in use
- Use smaller instance types
- Delete resources after testing: `./scripts/deployment/cleanup-resources.sh`

**Free tier:** Some GCP services have free tier, but GKE cluster is not free.

---

### Q: Can I use this with AWS or Azure instead of GCP?
**A:** Yes! You would need to adapt:

**AWS (EKS):**
- Terraform provider: `aws`
- Cluster: EKS instead of GKE
- Database: RDS MySQL instead of Cloud SQL
- Load Balancer: ALB/NLB

**Azure (AKS):**
- Terraform provider: `azurerm`
- Cluster: AKS instead of GKE
- Database: Azure Database for MySQL
- Load Balancer: Azure Load Balancer

The application code (frontend/backend) remains the same! Only infrastructure changes.

---

### Q: What programming languages are used?
**A:**
- **Backend:** Python (FastAPI or Flask)
- **Frontend:** HTML, CSS, JavaScript (vanilla)
- **Database:** MySQL 8.0
- **IaC:** Terraform (HCL)
- **Scripts:** Bash

---

## 🐳 Docker Questions

### Q: Do I need Docker Desktop or can I use Docker Engine?
**A:** Either works! 
- **Docker Desktop:** Easiest for Windows/Mac (includes GUI)
- **Docker Engine:** Linux native (command-line only)

Both include Docker Compose.

---

### Q: Why use Docker Compose instead of plain Docker?
**A:** Docker Compose manages multiple containers together:
- Single command to start all services: `docker-compose up`
- Automatic networking between containers
- Environment variables from `.env` file
- Service dependencies (backend waits for database)

Without Compose, you'd need multiple `docker run` commands with complex networking flags.

---

### Q: How do I see what's inside a container?
**A:**
```bash
# Enter container shell
docker-compose exec backend bash

# View files
docker-compose exec backend ls -la /app

# Check Python packages
docker-compose exec backend pip list

# Test database connection
docker-compose exec backend python -c "import database; print('DB OK')"
```

---

### Q: Can I modify code without rebuilding images?
**A:** Yes, using volume mounts!

Edit `docker-compose.yml`:
```yaml
backend:
  volumes:
    - ./src/backend:/app  # Mount source code
  command: uvicorn main:app --reload  # Enable hot reload
```

Now changes to Python files reload automatically!

---

## ☸️ Kubernetes Questions

### Q: What's the difference between Docker Compose and Kubernetes?
**A:**

| Docker Compose | Kubernetes |
|----------------|------------|
| Single machine | Multi-machine cluster |
| Development/testing | Production |
| Simple YAML | Complex YAML manifests |
| No auto-scaling | Auto-scaling built-in |
| No self-healing | Self-healing (restarts failed pods) |
| No load balancing | Load balancing built-in |

**Rule of thumb:** Use Docker Compose locally, Kubernetes in production.

---

### Q: Why do pods keep restarting?
**A:** Check logs for the reason:
```bash
kubectl logs -n voting-app <POD_NAME>
```

Common causes:
1. **Application crash:** Fix code bug
2. **Failed health check:** Increase `initialDelaySeconds`
3. **Out of memory:** Increase memory limits
4. **Can't connect to database:** Check secrets/networking

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md#error-crashloopbackoff)

---

### Q: How do I access pods for debugging?
**A:**
```bash
# Shell into pod
kubectl exec -it -n voting-app <POD_NAME> -- bash

# View logs
kubectl logs -n voting-app <POD_NAME> -f

# Describe pod (see events)
kubectl describe pod -n voting-app <POD_NAME>

# Port forward (access pod directly)
kubectl port-forward -n voting-app <POD_NAME> 8000:8000
# Now access: http://localhost:8000
```

---

### Q: How do I update the application after code changes?
**A:**

**Method 1: Rebuild and push image**
```bash
# Build new image
cd src/backend
docker build -t gcr.io/PROJECT_ID/voting-app-backend:v2 .

# Push to registry
docker push gcr.io/PROJECT_ID/voting-app-backend:v2

# Update deployment
kubectl set image deployment/backend -n voting-app \
  backend=gcr.io/PROJECT_ID/voting-app-backend:v2
```

**Method 2: Rolling restart (same image)**
```bash
kubectl rollout restart deployment/backend -n voting-app
```

---

### Q: How do I scale the application?
**A:**
```bash
# Scale backend to 5 replicas
kubectl scale deployment backend -n voting-app --replicas=5

# Scale frontend to 3 replicas
kubectl scale deployment frontend -n voting-app --replicas=3

# View scaled pods
kubectl get pods -n voting-app

# Auto-scale based on CPU
kubectl autoscale deployment backend -n voting-app \
  --min=2 --max=10 --cpu-percent=80
```

---

## 🗄️ Database Questions

### Q: How do I access the database directly?
**A:**

**Docker Compose:**
```bash
docker-compose exec db mysql -u voting_user -p
# Enter password from .env file
```

**Kubernetes:**
```bash
# Get Cloud SQL IP
kubectl get secret db-credentials -n voting-app -o jsonpath='{.data.DB_HOST}' | base64 -d

# Connect from local machine
mysql -h CLOUD_SQL_IP -u voting_user -p
```

---

### Q: How do I reset the database?
**A:**

**Docker Compose:**
```bash
# Delete volume and recreate
docker-compose down -v
docker-compose up -d
# init.sql runs automatically
```

**Kubernetes:**
```bash
# Delete and recreate db-init job
kubectl delete job db-init -n voting-app
kubectl apply -f 3-KUBERNETES/k8s/01-db-init-job.yaml -n voting-app

# Or manually via MySQL
mysql -h CLOUD_SQL_IP -u voting_user -p
> DROP TABLE votes;
> CREATE TABLE votes (...);
```

---

### Q: Where is the data stored?
**A:**

**Docker Compose:**
- Volume: `mysql_data` (persists between restarts)
- Location: Docker's data directory (Linux: `/var/lib/docker/volumes/`)

**Kubernetes:**
- Cloud SQL instance (fully managed by Google)
- Automatic backups enabled
- Data persists even if cluster is deleted

---

### Q: Can I use PostgreSQL instead of MySQL?
**A:** Yes! You would need to:
1. Change Docker image: `mysql:8.0` → `postgres:15`
2. Update backend code: MySQL driver → PostgreSQL driver (psycopg2)
3. Update SQL syntax (minor differences)
4. Update Terraform: `google_sql_database_instance` database_version

---

## 🚀 Deployment Questions

### Q: What's the deployment process?
**A:**

**For Kubernetes:**
```
1. terraform apply          → Create infrastructure (cluster, database)
2. generate-secrets.sh      → Extract DB credentials from Terraform
3. kubectl apply            → Deploy application manifests
4. Wait for LoadBalancer IP → Access application
```

Automated in: `./scripts/deployment/start-deployment.sh`

---

### Q: How do I deploy to a different GCP region?
**A:** Edit Terraform variables:

`3-KUBERNETES/terraform/variables.tf`:
```hcl
variable "region" {
  default = "europe-west1"  # Change from us-central1
}

variable "zone" {
  default = "europe-west1-b"
}
```

Then:
```bash
terraform destroy -auto-approve
terraform apply -auto-approve
```

---

### Q: Can I deploy without Terraform?
**A:** Yes, but you'd need to:
1. Create GKE cluster manually (gcloud or Console)
2. Create Cloud SQL instance manually
3. Manually create secrets with DB credentials
4. Apply Kubernetes manifests

Terraform automates all this! But manual is good for learning.

---

### Q: How do I set up CI/CD?
**A:** Example GitHub Actions workflow:

`.github/workflows/deploy.yml`:
```yaml
name: Deploy to GKE
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_CREDENTIALS }}
      - run: |
          docker build -t gcr.io/$PROJECT/backend:$GITHUB_SHA ./src/backend
          docker push gcr.io/$PROJECT/backend:$GITHUB_SHA
          kubectl set image deployment/backend backend=gcr.io/$PROJECT/backend:$GITHUB_SHA
```

See: [docs/guides/GITHUB_ACTIONS_SETUP.md](docs/guides/GITHUB_ACTIONS_SETUP.md)

---

## 🔒 Security Questions

### Q: Is it safe to commit `.env` files?
**A:** **NO!** Never commit files with secrets:
- `.env` contains database passwords
- Service account keys contain GCP credentials

**Already committed?**
1. Revoke/regenerate credentials immediately
2. Remove from Git history: `git filter-branch` or BFG Repo-Cleaner
3. Add to `.gitignore`

---

### Q: How do I manage secrets securely?
**A:**

**Development:** `.env` files (not committed to Git)

**Production options:**
1. **Kubernetes Secrets** (current approach)
2. **Google Secret Manager** (recommended)
3. **HashiCorp Vault** (enterprise)
4. **Sealed Secrets** (GitOps-friendly)

---

### Q: Is the database publicly accessible?
**A:** 
- **Yes** in current setup (authorized_networks: `0.0.0.0/0`)
- Protected by password authentication
- **For production:** Use VPC peering or Private IP instead

---

## 📚 Learning Questions

### Q: I'm a beginner. Where should I start?
**A:**

**Week 1:** Local setup
- Follow [QUICKSTART.md](QUICKSTART.md) Option 1
- Modify frontend HTML
- Add a new vote option

**Week 2:** Docker
- Read Docker Compose file
- Build images manually
- Experiment with volumes

**Week 3:** Kubernetes basics
- Learn kubectl commands
- Deploy to GKE
- Read logs and debug

**Week 4:** Terraform
- Understand infrastructure code
- Modify variables
- Add a new resource

---

### Q: What should I learn to understand this project?
**A:**

**Prerequisites:**
- Linux command line basics
- Git basics
- Basic networking (ports, IPs)

**Technologies to learn:**
1. **Docker** (4-8 hours) → [Docker Getting Started](https://docs.docker.com/get-started/)
2. **Kubernetes** (8-16 hours) → [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
3. **Terraform** (4-8 hours) → [Terraform Tutorial](https://learn.hashicorp.com/terraform)
4. **Python basics** (optional, for backend)
5. **HTML/CSS/JS** (optional, for frontend)

---

### Q: How can I extend this project?
**A:**

**Easy:**
- Add more vote options (e.g., Birds, Fish)
- Change styling (CSS)
- Add vote history view

**Medium:**
- Add user authentication
- Add voting limits (1 vote per IP)
- Add charts/graphs for results
- Add admin dashboard

**Advanced:**
- Add real-time updates (WebSockets)
- Add multiple voting categories
- Add user profiles
- Migrate to microservices architecture

---

### Q: Can I use this for my portfolio?
**A:** **YES!** This project demonstrates:
- Full-stack development
- Docker & containerization
- Kubernetes orchestration
- Cloud deployment (GCP)
- Infrastructure as Code
- DevOps practices

**Make it unique:**
- Customize the voting topic
- Add features
- Improve UI design
- Deploy to production domain
- Write blog post about your experience

---

## 🛠️ Technical Questions

### Q: Why FastAPI instead of Flask?
**A:** Both work! Current project uses FastAPI because:
- Modern async support
- Automatic API documentation (Swagger)
- Type hints and validation
- Better performance

Feel free to swap for Flask/Django/Express.js!

---

### Q: Why MySQL instead of PostgreSQL or MongoDB?
**A:** 
- MySQL: Most common, easy Cloud SQL setup
- Could use PostgreSQL (more features, better JSON support)
- MongoDB wouldn't fit well (simple relational data)

Choice doesn't matter much for this simple app.

---

### Q: Why preemptible nodes?
**A:** **Cost savings!**
- Preemptible: ~60-80% cheaper
- Downside: Can be terminated anytime (max 24h)
- Fine for dev/test, not for production

For production: Use regular nodes or mix (some preemptible for scaling).

---

### Q: What happens if a preemptible node is terminated?
**A:** Kubernetes automatically:
1. Detects node failure
2. Reschedules pods to other nodes
3. Creates new node (if using node pool autoscaling)

Your app stays available (if you have multiple replicas)!

---

## 🤝 Contributing Questions

### Q: Can I contribute to this project?
**A:** **YES!** Contributions welcome:
- Fix bugs
- Add features
- Improve documentation
- Add tests

See: [CONTRIBUTING.md](CONTRIBUTING.md) (TODO)

---

### Q: I found a bug. What should I do?
**A:**
1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Search existing GitHub Issues
3. If new: Open Issue with:
   - Description of bug
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details

---

### Q: How do I propose a new feature?
**A:**
1. Open GitHub Issue with `enhancement` label
2. Describe the feature and use case
3. Wait for discussion/approval
4. Fork, implement, and create Pull Request

---

## 💬 Still Have Questions?

- 📖 Check [documentation](docs/)
- 🐛 See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- 💬 Open GitHub Issue
- 📧 Contact maintainers

**Happy learning! 🚀**
