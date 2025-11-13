# 🗳️ Voting App - Complete DevOPS Learning Course

> **A comprehensive hands-on DevOPS tutorial for junior developers**  
> **Testing First | Security First | DevOPS Culture**

## 👋 Welcome!

This is a complete production-ready DevOPS learning project with **three independent deployment methods**:

1. 🏠 **LOCAL Mode** - On-premise deployment (no containers)
2. 🐳 **DOCKER Mode** - Containerized deployment with Docker Compose
3. ☸️ **KUBERNETES Mode** - Production deployment on Google Cloud Platform (GCP)

Each mode is **completely independent** - choose based on your learning goals!

---

## 🚀 Quick Start for Beginners

**New to DevOps?** Start here:

| Guide | Time | Level | What You'll Do |
|-------|------|-------|----------------|
| **[📖 QUICKSTART](QUICKSTART.md)** | 5 min | Beginner | Get app running locally with Docker Compose |
| **[🎓 TUTORIAL](docs/TUTORIAL.md)** | 30 min | Beginner | Step-by-step deploy to Kubernetes on GCP |
| **[❓ FAQ](FAQ.md)** | - | All | Common questions answered |
| **[🐛 TROUBLESHOOTING](TROUBLESHOOTING.md)** | - | All | Fix common errors |

**Want to dive in immediately?** Run these 3 commands:
```bash
git clone https://github.com/octaviansandulescu/voting-app.git
cd voting-app
docker-compose up -d
# Open: http://localhost
```

---

## 🎯 What You'll Learn

This course teaches **hands-on DevOPS** through practical, real-world examples:

- ✅ **Testing First Mindset** - Write tests before deployment
- ✅ **Security Best Practices** - Protect secrets and follow standards
- ✅ **Docker & Containerization** - Package apps reliably
- ✅ **Kubernetes Orchestration** - Manage containers at scale
- ✅ **Infrastructure as Code** - Automate infrastructure with Terraform
- ✅ **CI/CD Pipelines** - Automate testing and deployment with GitHub Actions
- ✅ **Monitoring & Observability** - Prometheus, Grafana, and logging
- ✅ **Cloud Deployment** - Production deployment on Google Cloud Platform

---

## 📖 Recommended Learning Path

### ⭐ **START HERE - Beginner Path (2-3 hours total)**

Follow this **exact sequence** for optimal learning:

#### **Phase 1: Foundation (35 minutes)**

1. **⭐⭐⭐ [1. DevOPS Concepts](docs/guides/CONCEPTS.md)** (10 min) 
   - What is DevOPS?
   - Why testing and security matter
   - Deployment basics
   - *Prerequisite for all other modules*

2. **⭐⭐⭐ [2. Testing Fundamentals](docs/guides/TESTING_FUNDAMENTALS.md)** (15 min) **← THIS IS CRITICAL!**
   - Why tests prevent production failures
   - Introduction to pytest
   - Write your first test
   - Test-driven development (TDD) mindset
   - *You'll run tests in every subsequent module*

3. **⭐⭐⭐ [3. Security Best Practices](docs/guides/SECURITY.md)** (10 min) **← BEFORE DEPLOYING!**
   - Never commit secrets to GitHub
   - Environment variables management
   - .gitignore rules
   - Security checklist
   - *Critical to understand before any deployment*

#### **Phase 2: Deployment Methods (65 minutes)**

4. **[4. LOCAL Deployment](docs/guides/LOCAL_SETUP.md)** (20 min)
   - Deploy without Docker
   - Run tests locally
   - Understand the full application flow
   - *Best for learning the application structure*

5. **[5. DOCKER Deployment](docs/guides/DOCKER_SETUP.md)** (15 min)
   - Containerize the application
   - Run tests in containers
   - Use docker-compose
   - *Best for understanding containerization*

6. **[6. KUBERNETES Deployment](docs/guides/KUBERNETES_SETUP.md)** (30 min)
   - Deploy to Google Cloud Platform
   - Use Terraform for infrastructure
   - Run tests in production
   - Application goes LIVE!
   - *Best for learning enterprise deployment*

#### **Phase 3: Automation & Monitoring (25 minutes)**

7. **[7. Testing & CI/CD Pipeline](docs/guides/TESTING_CICD.md)** (10 min)
   - GitHub Actions workflows
   - Automated test execution on every push
   - Continuous deployment
   - *Automates everything you learned manually*

   **⭐ Setup GitHub Actions (5 minutes):**
   - **Quick Setup**: [QUICK_SETUP_SECRETS.md](QUICK_SETUP_SECRETS.md) ← **START HERE**
     - Just add 2 secrets to GitHub
     - Follow 3 simple steps
   - **Full OIDC Guide**: [docs/guides/GITHUB_OIDC_SETUP.md](docs/guides/GITHUB_OIDC_SETUP.md)
     - Complete documentation
     - All configuration details
   - **Legacy Method**: [docs/guides/GITHUB_ACTIONS_SETUP.md](docs/guides/GITHUB_ACTIONS_SETUP.md)
     - Old approach with JSON keys

8. **[8. Monitoring Setup](docs/guides/MONITORING_SETUP.md)** (15 min)
   - Prometheus metrics collection
   - Grafana dashboards
   - Application monitoring
   - *Production observability*

#### **Optional Deep Dives**

- [Architecture Deep Dive](docs/architecture/ARCHITECTURE.md) - System design details
- [API Documentation](docs/api/README.md) - Endpoint reference
- [Troubleshooting Guide](docs/troubleshooting/TROUBLESHOOTING.md) - Fix common issues

---

## 🚀 Quick Start (Choose One)

### **Option A: LOCAL Mode (Fastest)**

```bash
# 1. Navigate to local deployment
cd deployment/local

# 2. Copy environment template
cp .env.local.example .env.local

# 3. Install dependencies
./install.sh

# 4. Run tests first!
../run-all-tests.sh

# 5. Start application
./start.sh

# 6. Open in browser
# Frontend: http://localhost:3000
# API: http://localhost:8000

# 7. View logs
./view-logs.sh

# 8. Stop services
./stop.sh
```

### **Option B: DOCKER Mode (Recommended)**

```bash
# 1. Navigate to docker deployment
cd deployment/docker

# 2. Copy environment template
cp .env.docker.example .env.docker

# 3. Run tests in containers
docker-compose run --rm backend pytest

# 4. Start application
docker-compose up --build

# 5. Open in browser
# Frontend: http://localhost
# API: http://localhost/api

# 6. View logs
docker-compose logs -f

# 7. Stop services
docker-compose down
```

### **Option C: KUBERNETES Mode (Production)**

#### **Using Terraform + kubectl (Full Control)**

```bash
# 1. Navigate to kubernetes deployment
cd 3-KUBERNETES

# 2. Configure GCP project (if deploying to GCP)
nano terraform/terraform.tfvars

# 3. Deploy infrastructure
terraform init
terraform apply

# 4. Wait for deployment to complete (~5-10 minutes)
kubectl get pods -n voting-app -w

# 5. Get the external IP (dynamically assigned)
kubectl get svc frontend-service -n voting-app

# 6. Open application in browser
# Copy the EXTERNAL-IP from step 5
# http://<EXTERNAL-IP>

# 7. View logs
kubectl logs -n voting-app -l app=backend -f

# 8. Clean up when done (deletes all GCP resources)
terraform destroy
```

#### **Using Deployment Scripts**

Once Kubernetes cluster is created, use these 3 essential scripts:

```bash
# 🚀 Deploy application
./scripts/deployment/start-deployment.sh

# 📊 Check status
./scripts/deployment/status-deployment.sh

# 🛑 Stop & delete everything
./scripts/deployment/stop-deployment.sh
```

**Simple workflow:**
1. Deploy: `./scripts/deployment/start-deployment.sh`
2. Check: `./scripts/deployment/status-deployment.sh`
3. Get URL from status output
4. Test: `curl http://<IP>/api/results`
5. Vote: `curl -X POST http://<IP>/api/vote -H "Content-Type: application/json" -d '{"vote":"dogs"}'`

**📖 Full Documentation:** [Deployment Scripts Guide](docs/guides/DEPLOYMENT_SCRIPTS.md)

---

## 📋 Prerequisites

### For LOCAL Mode
```
✓ Python 3.11 or higher
✓ MySQL 8.0 or higher  
✓ Git
✓ ~500 MB disk space
```

### For DOCKER Mode
```
✓ Docker Desktop (includes Docker + Docker Compose)
✓ Git
✓ ~2 GB disk space
✓ 4 GB RAM minimum
```

### For KUBERNETES Mode
```
✓ Google Cloud Platform free account (always free tier available)
✓ gcloud CLI installed and configured
✓ kubectl installed
✓ Terraform 1.0 or higher
✓ Git
✓ ~5 GB disk space
```

---

## 🧪 Testing (Very Important!)

Tests are **critical** in DevOPS. Every deployment should be tested.

### Run Tests Locally

```bash
# Run all tests
./scripts/testing/run-all-tests.sh

# Run only unit tests (fastest)
./scripts/testing/run-unit-tests.sh

# Run integration tests
./scripts/testing/run-integration-tests.sh

# Run end-to-end tests
./scripts/testing/run-e2e-tests.sh

# Run with coverage report
pytest --cov=src/backend src/backend/tests/
```

### Test Coverage

The project includes:

- **Unit Tests** - Backend API functions, database operations
- **Integration Tests** - Docker Compose and Kubernetes integration
- **E2E Tests** - Complete voting workflow simulation
- **Security Tests** - Vulnerability scanning and secret detection

**All tests must pass before any deployment!**

---

## 🔒 Security (Very Important!)

**⚠️ NEVER commit sensitive data to GitHub!**

This project follows enterprise security practices:

### Files That Are IGNORED (never committed)
```
.env                     # Secrets for LOCAL mode
.env.local               # Local environment
.env.docker              # Docker environment
terraform.tfvars         # GCP credentials
terraform.tfstate*       # Infrastructure state
.terraform/              # Terraform cache
*.key                    # SSH keys
*.pem                    # Certificates
```

### Files That Are Public (safe to commit)
```
.env.example             # Template with no real values
.env.local.example       # Template with no real values
terraform.tfvars.example # Template with no real values
```

### Security Checklist

Before any deployment, verify:

- [ ] No `.env` file committed to git
- [ ] No terraform state files committed
- [ ] `.gitignore` includes all sensitive files
- [ ] All secrets stored in environment variables
- [ ] Database passwords generated securely
- [ ] No hardcoded API keys in code
- [ ] No credentials in container images

Run security audit:
```bash
./scripts/devops/security-audit.sh
```

---

## 🏗️ Project Structure

```
voting-app/
│
├── 📚 docs/                               # DOCUMENTATION
│   ├── guides/
│   │   ├── CONCEPTS.md                   # 1. Start here
│   │   ├── TESTING_FUNDAMENTALS.md       # 2. Learn testing
│   │   ├── SECURITY.md                   # 3. Learn security
│   │   ├── LOCAL_SETUP.md                # 4. Deploy locally
│   │   ├── DOCKER_SETUP.md               # 5. Containerize
│   │   ├── KUBERNETES_SETUP.md           # 6. Deploy to production
│   │   ├── TESTING_CICD.md               # 7. Automate tests
│   │   └── MONITORING_SETUP.md           # 8. Monitor production
│   ├── architecture/
│   │   └── ARCHITECTURE.md               # Deep dive
│   ├── api/
│   │   └── README.md                     # API reference
│   └── troubleshooting/
│       ├── DOCKER_ISSUES.md
│       ├── KUBERNETES_ISSUES.md
│       └── DATABASE_ISSUES.md
│
├── 💻 src/                                # APPLICATION CODE
│   ├── backend/
│   │   ├── main.py                       # FastAPI application
│   │   ├── database.py                   # MySQL connection
│   │   ├── config.py                     # Environment config
│   │   ├── requirements.txt               # Python dependencies
│   │   ├── pytest.ini                    # Test configuration
│   │   └── tests/
│   │       ├── test_api.py               # API tests
│   │       ├── test_database.py          # Database tests
│   │       └── test_hello_world.py       # Example test
│   └── frontend/
│       ├── index.html                    # Voting UI
│       ├── style.css                     # Styling
│       ├── script.js                     # Frontend logic
│       └── nginx.conf                    # Nginx config
│
├── 🚀 deployment/                         # DEPLOYMENT CONFIGS
│   ├── local/
│   │   ├── README.md                     # LOCAL mode guide
│   │   └── scripts/                      # Local scripts
│   ├── docker/
│   │   ├── README.md                     # DOCKER mode guide
│   │   ├── docker-compose.yml            # Docker Compose config
│   │   └── Dockerfile.*                  # Image definitions
│   └── kubernetes/
│       ├── README.md                     # K8S mode guide
│       └── scripts/                      # K8S scripts
│
├── 🏗️ infrastructure/                     # INFRASTRUCTURE AS CODE
│   ├── terraform/
│   │   ├── main.tf                       # GKE + Cloud SQL
│   │   ├── variables.tf                  # Variables
│   │   └── outputs.tf                    # Outputs
│   └── kubernetes/
│       ├── manifests/
│       │   ├── 01-namespace.yaml
│       │   ├── 02-secrets.yaml
│       │   ├── 03-backend-deployment.yaml
│       │   └── 04-frontend-service.yaml
│       └── monitoring/
│           ├── prometheus.yaml
│           └── grafana.yaml
│
├── 🧪 tests/                              # TEST SUITES
│   ├── unit/
│   └── integration/
│
├── 🤖 ci-cd/                              # CI/CD AUTOMATION
│   └── workflows/
│       ├── ci-test.yml                   # Test on push
│       ├── build-push.yml                # Build images
│       └── deploy.yml                    # Deploy to GCP
│
├── 🔧 scripts/                            # UTILITY SCRIPTS
│   ├── docker/
│   ├── kubernetes/
│   ├── devops/
│   ├── monitoring/
│   └── testing/
│
└── 📄 Configuration Files
    ├── .gitignore                        # Ignore secrets
    ├── .dockerignore
    ├── README_EN.md                      # This file
    └── LICENSE
```

---

## 📊 Learning Outcomes

After completing this course, you will understand:

- ✅ How to write effective tests for your application
- ✅ How to manage secrets securely
- ✅ How to containerize applications with Docker
- ✅ How to orchestrate containers with Kubernetes
- ✅ How to provision infrastructure with Terraform
- ✅ How to automate deployments with GitHub Actions
- ✅ How to monitor production applications
- ✅ How to deploy to Google Cloud Platform

You will also have:

- ✅ A working voting application in three deployment modes
- ✅ A complete CI/CD pipeline
- ✅ Production monitoring setup
- ✅ Security best practices implemented
- ✅ Comprehensive test coverage
- ✅ Infrastructure as Code examples

---

## 🔍 Current Status

| Component | Status | Details |
|-----------|--------|---------|
| **Application** | ✅ Ready | Voting app with API and database |
| **Testing** | ✅ Ready | Unit, integration, E2E tests |
| **LOCAL Mode** | ✅ Working | On-premise deployment |
| **DOCKER Mode** | ✅ Working | Containerized deployment |
| **KUBERNETES Mode** | ✅ Ready | Deployable to GCP (IP assigned after startup) |
| **CI/CD Pipeline** | ✅ Ready | GitHub Actions workflows |
| **Monitoring** | ✅ Ready | Prometheus + Grafana |
| **Documentation** | ✅ Complete | All guides in English |

### 📍 Getting the Kubernetes Service IP

⚠️ **Note:** The Kubernetes LoadBalancer IP is **dynamically assigned** when the cluster starts. It changes each time you start a new cluster.

**To find the current IP after deployment:**

```bash
# Get the external IP of the frontend service
kubectl get svc frontend-service -n voting-app

# Output will look like:
# NAME              TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)
# frontend-service  LoadBalancer   10.0.0.100      34.42.155.47    80:30123/TCP

# Then access the application at:
# http://<EXTERNAL-IP>
```

**For production use:**
- Store the IP in a DNS record
- Use a static IP reservation in GCP
- See [docs/guides/KUBERNETES_SETUP.md](docs/guides/KUBERNETES_SETUP.md) for details

---

## 🆘 Troubleshooting

**Having issues?** Check these guides:

- [LOCAL Mode Issues](docs/troubleshooting/LOCAL_ISSUES.md)
- [DOCKER Issues](docs/troubleshooting/DOCKER_ISSUES.md)
- [KUBERNETES Issues](docs/troubleshooting/KUBERNETES_ISSUES.md)
- [Database Issues](docs/troubleshooting/DATABASE_ISSUES.md)
- [API Issues](docs/troubleshooting/API_ISSUES.md)

### Quick Fixes

```bash
# Tests failing?
cd src/backend && pytest -v

# Docker not working?
docker-compose down && docker system prune -a

# Kubernetes issues?
kubectl get pods -n voting-app
kubectl logs -n voting-app -l app=backend
```

---

## 📞 Support

**Questions or issues?**

1. Check the [Troubleshooting Guide](docs/troubleshooting/TROUBLESHOOTING.md)
2. Read the [FAQ](docs/FAQ.md)
3. Create a GitHub issue with details

---

## 📄 License

This project is licensed under the **MIT License** - see [LICENSE](LICENSE) for details.

---

## 🎓 Recommended Reading

### External Resources

- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Google Cloud Platform Docs](https://cloud.google.com/docs)

### Recommended Books

- "The DevOPS Handbook" by Gene Kim
- "Site Reliability Engineering" by Google
- "Docker Deep Dive" by Nigel Poulton
- "Kubernetes in Action" by Marko Luksa

---

## ✅ Learning Checklist

Track your progress:

- [ ] Read DevOPS Concepts
- [ ] Understand Testing Fundamentals
- [ ] Learn Security Best Practices
- [ ] Complete LOCAL mode deployment
- [ ] Complete DOCKER mode deployment
- [ ] Complete KUBERNETES mode deployment
- [ ] Setup CI/CD pipeline
- [ ] Setup monitoring
- [ ] All tests passing ✅
- [ ] Application deployed to production ✅

---

## 🤝 Contributing

We welcome contributions! Please:

1. Read [CONTRIBUTING.md](CONTRIBUTING.md)
2. Write tests for new features
3. Follow security guidelines
4. Submit a pull request

---

## 🏆 Key Takeaways

This course teaches **DevOPS culture**, not just tools:

1. **Test First** - Tests prevent production failures
2. **Security First** - Never commit secrets
3. **Infrastructure as Code** - Automate everything
4. **Continuous Integration** - Automate tests on every push
5. **Continuous Deployment** - Deploy with confidence
6. **Monitor Everything** - Know what's happening in production
7. **Document Everything** - Help future team members
8. **Automate Repetitive Tasks** - Save time and reduce errors

---

**Ready to start? Begin with [1. DevOPS Concepts](docs/guides/CONCEPTS.md)! 🚀**

---

Generated with ❤️ for developers learning DevOPS.  
Last Updated: 2025-11-11
