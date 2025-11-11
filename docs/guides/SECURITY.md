# 🔒 Security Best Practices - Never Deploy Secrets

> **In DevOPS, security comes FIRST - before any deployment**

## 🎯 Learning Objectives

By the end of this guide, you will understand:

- ✅ Why secrets management is critical
- ✅ What data is "sensitive" and must be protected
- ✅ How to use environment variables safely
- ✅ How to prevent accidental commits to GitHub
- ✅ Security checklist before any deployment
- ✅ Detecting and fixing security issues

**Estimated time: 10 minutes**

---

## ⚠️ The Golden Rule of DevOPS

```
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║  🚨 NEVER COMMIT SECRETS TO GITHUB! 🚨                    ║
║                                                            ║
║  Once pushed, secrets are PUBLIC FOREVER!                 ║
║  Attackers can:                                           ║
║  • Access your production database                        ║
║  • Delete data                                            ║
║  • Steal customer information                             ║
║  • Impersonate your application                           ║
║  • Rack up cloud bills                                    ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

---

## 📋 What Is "Sensitive Data"?

### 🚫 NEVER Commit These

| Type | Examples | Risk |
|------|----------|------|
| **Passwords** | DB password, admin password | Account takeover |
| **API Keys** | AWS keys, GCP keys, GitHub tokens | Service abuse |
| **Database URLs** | `mysql://user:pass@host:3306/db` | Database compromise |
| **SSH Keys** | `~/.ssh/id_rsa`, certificates | Server access |
| **Tokens** | JWT tokens, OAuth tokens | Session hijacking |
| **Private Keys** | TLS/SSL certificates | HTTPS compromise |
| **Cloud Credentials** | GCP credentials, AWS IAM | Infrastructure access |
| **Internal URLs** | Internal database hosts, VPN | Network mapping |

### ✅ Safe To Commit

| Type | Examples | Reason |
|------|----------|--------|
| **Code** | Python files, HTML, CSS, JS | No sensitive data |
| **Templates** | `.env.example` | No real values |
| **Configuration** | docker-compose structure | General setup |
| **Documentation** | README, guides | Educational |
| **Tests** | pytest files | Mock data only |

---

## 🔑 Environment Variables: The Safe Way

### Problem: Hardcoded Credentials

```python
# ❌ BAD - NEVER DO THIS!

database_password = "MySuper$ecretPassword123"
api_key = "sk-1234567890abcdef"
aws_access_key = "AKIAIOSFODNN7EXAMPLE"

# All visible in code → visible on GitHub → hackers can see it!
```

### Solution: Use Environment Variables

```python
# ✅ GOOD - Use environment variables

import os

database_password = os.getenv("DB_PASSWORD")
api_key = os.getenv("API_KEY")
aws_access_key = os.getenv("AWS_ACCESS_KEY_ID")

# Values come from .env file (not committed to GitHub)
```

### How Environment Variables Work

```
.env file (LOCAL)
├─ DB_PASSWORD=secret123      ← NOT committed
├─ API_KEY=key456             ← NOT committed
└─ AWS_ACCESS_KEY=aws789      ← NOT committed
     │
     ↓ (loaded when app starts)
     │
  App Environment
     │
     ↓ os.getenv("DB_PASSWORD") reads "secret123"
     │
  Secure! ✅
```

---

## 📁 File-Level Security

### Step 1: Create .env Files (Never Commit!)

#### For LOCAL Mode

```bash
# Create local environment file
cat > src/backend/.env.local << 'EOF'
# Database
DB_HOST=localhost
DB_PORT=3306
DB_USER=voting_user
DB_PASSWORD=LocalSecurePassword123!
DB_NAME=voting_app

# Deployment mode
DEPLOYMENT_MODE=local
DEBUG=true
EOF

# DO NOT commit this file!
```

#### For DOCKER Mode

```bash
# Create docker environment file
cat > deployment/docker/.env.docker << 'EOF'
# Database
DB_HOST=mysql-service
DB_PORT=3306
DB_USER=voting_user
DB_PASSWORD=DockerSecurePassword456!
DB_NAME=voting_app_docker

# Deployment mode
DEPLOYMENT_MODE=docker
DEBUG=false
EOF

# DO NOT commit this file!
```

#### For KUBERNETES Mode

Secrets are managed by Kubernetes (never in files):

```bash
# Kubernetes stores secrets separately
kubectl create secret generic voting-secrets \
  --from-literal=DB_PASSWORD=KubernetesSecurePassword789! \
  --from-literal=DB_USER=voting_user \
  -n voting-app
```

### Step 2: Create .env.example Templates

**These ARE committed to GitHub!**

```bash
# src/backend/.env.example
# This is a template - no real values here!

# Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_USER=voting_user
DB_PASSWORD=YOUR_SECURE_PASSWORD_HERE
DB_NAME=voting_app

# Deployment
DEPLOYMENT_MODE=local
DEBUG=true

# Instructions:
# 1. Copy this file: cp .env.example .env.local
# 2. Edit with real values: nano .env.local
# 3. DON'T commit .env.local to GitHub!
```

### Step 3: Configure .gitignore

**This file prevents accidental commits:**

```bash
# .gitignore (commit this file!)

# Environment variables (NEVER commit)
.env
.env.local
.env.docker
.env.*.local

# Configuration files (NEVER commit)
terraform.tfvars
terraform.tfvars.json

# State files (NEVER commit)
terraform.tfstate
terraform.tfstate.backup
*.tfstate*

# SSH Keys & Certificates (NEVER commit)
*.pem
*.key
*.crt
*.cer
id_rsa
id_rsa.pub

# Kubernetes secrets (NEVER commit)
secrets.yaml
*.secrets.yaml

# CI/CD secrets (NEVER commit)
.github/secrets
.gitlab/ci/secrets

# Cloud credentials (NEVER commit)
credentials.json
service-account-key.json
~/.aws/credentials
~/.gcloud/

# Local development
.venv/
.env.local
.DS_Store
*.swp
.pytest_cache/
__pycache__/
*.pyc
```

---

## 🔍 Detecting Security Issues

### Check if Secrets Are Committed

```bash
# Search for passwords in code
grep -r "password.*=" src/ --include="*.py" | grep -v "os.getenv\|config"

# Search for hardcoded API keys
grep -r "api_key.*=" src/ --include="*.py" | grep -v "os.getenv"

# Check if .env files are accidentally committed
git ls-files | grep "\.env"

# Expected output: (empty = good!)
```

### Automated Security Scanning

Run security audit script:

```bash
# Run full security audit
./scripts/devops/security-audit.sh

# Output should show:
# ✓ No passwords in code
# ✓ No API keys in code
# ✓ No AWS credentials
# ✓ .env files properly ignored
# ✅ SECURITY AUDIT PASSED!
```

---

## 🚨 If You Accidentally Commit a Secret

### Immediate Actions (WITHIN MINUTES!)

```bash
# 1. Remove from git history (permanently)
git filter-branch --tree-filter 'rm -f .env' HEAD

# 2. Force push to GitHub
git push origin main --force

# 3. ROTATE ALL CREDENTIALS IMMEDIATELY!
# Change database password
# Change API keys
# Revoke GitHub tokens
# Update cloud credentials
```

### Why This Is Important

> **Real Story**: In 2023, a developer committed AWS credentials to GitHub.  
> Attackers found it within 15 minutes and:
> - Spun up expensive EC2 instances
> - Created $40,000 in charges before detection
> - The company had to pay because credentials were public

---

## ✅ Security Checklist

### Before LOCAL Deployment

```bash
□ No .env file in git (check: git status | grep .env)
□ .gitignore configured properly
□ No hardcoded passwords in code
□ No API keys visible in source
□ Database password is strong (12+ chars, mixed case, numbers, symbols)
□ Run: ./scripts/devops/security-audit.sh ✅
```

### Before DOCKER Deployment

```bash
□ .env.docker not committed to git
□ Docker image doesn't embed secrets
□ Check: docker inspect image-name | grep PASSWORD
□ Secrets injected at runtime (--env flag)
□ .dockerignore includes .env files
```

### Before KUBERNETES Deployment

```bash
□ terraform.tfvars not committed
□ GCP credentials not in image
□ Secrets created in Kubernetes (not in manifests)
□ Check: kubectl get secrets -n voting-app
□ RBAC configured (who can access secrets)
□ Audit logs enabled
```

### Before GitHub Push

```bash
□ No .env files in git
□ No terraform.tfvars files in git
□ No private keys in repository
□ No API keys visible in any file
□ .gitignore covers all sensitive files
□ Run security audit:
  ./scripts/devops/security-audit.sh ✅
```

---

## 🔐 Safe Secrets Management by Deployment Mode

### LOCAL Mode

```
Developer's Computer
│
├─ src/backend/.env.local (NOT in git)
│   ├─ DB_PASSWORD=MyLocalPassword
│   └─ API_KEY=MyLocalKey
│
├─ src/backend/.env.example (IN git)
│   ├─ DB_PASSWORD=YOUR_PASSWORD_HERE
│   └─ API_KEY=YOUR_KEY_HERE
│
└─ Application reads .env.local at startup
```

### DOCKER Mode

```
Docker Host
│
├─ deployment/docker/.env.docker (NOT in git)
│   ├─ DB_PASSWORD=MyDockerPassword
│   └─ API_KEY=MyDockerKey
│
├─ docker-compose.yml (IN git)
│   └─ env_file: .env.docker  ← references, doesn't contain!
│
└─ Container reads env file at runtime
```

### KUBERNETES Mode

```
Google Cloud Platform
│
├─ Kubernetes Secret Store
│   ├─ voting-secrets
│   │  ├─ DB_PASSWORD=encoded_value
│   │  └─ API_KEY=encoded_value
│   │
├─ K8s Manifest (IN git, but references secret)
│   ├─ valueFrom:
│   │  └─ secretKeyRef: voting-secrets/DB_PASSWORD
│   │
└─ Pod reads secret from Kubernetes at runtime
```

---

## 🛡️ Production Security

### GitHub Actions Secrets

```yaml
# .github/workflows/deploy.yml

name: Deploy to Production

env:
  GCP_PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
  GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Authenticate to GCP
        uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      
      # Secrets are never logged in output!
```

### Add Secrets to GitHub

```bash
# Via GitHub Web UI:
1. Go to Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: GCP_SA_KEY
4. Value: (paste content of service account JSON)
5. Click "Add secret"

# Via GitHub CLI:
gh secret set GCP_SA_KEY < service-account-key.json
```

---

## 📚 Security Best Practices Summary

| Practice | Why | How |
|----------|-----|-----|
| **Use .env files** | Keep secrets out of code | Load from `.env` via `os.getenv()` |
| **Commit templates** | Help team members | Keep `.env.example` in git |
| **Strong passwords** | Resist brute force | 12+ chars, mixed case, numbers, symbols |
| **Rotate credentials** | Reduce exposure time | Change passwords monthly |
| **Limit access** | Principle of least privilege | Only give access needed |
| **Audit logs** | Detect breaches | Log who accesses what |
| **Use secrets manager** | Enterprise standard | GCP Secret Manager, HashiCorp Vault |

---

## 🔗 Next Steps

Now that you understand security:

1. ✅ **Do [LOCAL Deployment](LOCAL_SETUP.md)** - Deploy with security in place
2. ✅ **Do [DOCKER Deployment](DOCKER_SETUP.md)** - Container security
3. ✅ **Do [KUBERNETES Deployment](KUBERNETES_SETUP.md)** - Enterprise security
4. ✅ **Do [Testing & CI/CD](TESTING_CICD.md)** - Security scanning in pipeline

---

## ⚠️ Security Rules

```
1. 🚫 NEVER hardcode passwords
2. 🚫 NEVER commit .env files  
3. 🚫 NEVER push API keys to GitHub
4. 🚫 NEVER share credentials in Slack/Email
5. 🚫 NEVER leave credentials in code comments

6. ✅ DO use environment variables
7. ✅ DO use .gitignore
8. ✅ DO rotate credentials regularly
9. ✅ DO use GitHub secrets for CI/CD
10. ✅ DO audit who has access
```

---

## 📚 References

### Security Standards

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [12-Factor App - Config](https://12factor.net/config)
- [CWE-798: Hardcoded Credentials](https://cwe.mitre.org/data/definitions/798.html)

### Tools

- [git-secrets](https://github.com/awslabs/git-secrets) - Prevent secrets from being committed
- [truffleHog](https://github.com/trufflesecurity/truffleHog) - Scan for secrets in git history
- [detect-secrets](https://github.com/Yelp/detect-secrets) - Prevent secret sprawl

### Reading

- "Secrets Management Best Practices" - HashiCorp
- "The Art of Software Security Testing" - CJ Saffron
- "Security Engineering" - Ross Anderson

---

## ✨ Key Takeaways

1. **Security is everyone's responsibility** - Not just "security team"
2. **Prevention is better than response** - Stop breaches before they happen
3. **Use environment variables** - Never hardcode secrets
4. **Use .gitignore** - Prevent accidental commits
5. **Use GitHub Secrets** - For CI/CD pipelines
6. **Use Kubernetes Secrets** - For production deployments
7. **Rotate credentials** - Regularly change passwords
8. **Audit everything** - Know who accessed what

---

## 🎉 You're Secure!

You now understand how to keep secrets safe in DevOPS.

**Next:** Go to [LOCAL Deployment](LOCAL_SETUP.md) and deploy with confidence! 🚀

---

**Generated with ❤️ for secure DevOPS deployments.**
