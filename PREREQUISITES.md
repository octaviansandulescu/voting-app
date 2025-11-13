# 📋 Prerequisites for Voting App

Complete checklist of tools and accounts needed for each deployment mode.

---

## 🎯 Choose Your Learning Path

Different deployment modes require different tools:

| Deployment Mode | Complexity | Tools Needed | Time to Setup |
|----------------|------------|--------------|---------------|
| **Local (No Docker)** | Easy | Python, MySQL | 10 min |
| **Docker Compose** | Easy | Docker | 15 min |
| **Kubernetes (GCP)** | Advanced | Docker, kubectl, Terraform, GCP | 30 min |

---

## 🏠 For LOCAL Deployment (No Docker)

### Required Tools

#### 1. Python 3.9+
```bash
# Check if installed
python3 --version
# Should show: Python 3.9.0 or higher
```

**Install:**
- **MacOS:** `brew install python3`
- **Linux:** `sudo apt install python3 python3-pip`
- **Windows:** Download from [python.org](https://www.python.org/downloads/)

---

#### 2. MySQL 8.0+
```bash
# Check if installed
mysql --version
# Should show: mysql Ver 8.0 or higher
```

**Install:**
- **MacOS:** `brew install mysql`
- **Linux:** `sudo apt install mysql-server`
- **Windows:** Download from [mysql.com](https://dev.mysql.com/downloads/installer/)

**Start service:**
```bash
# MacOS
brew services start mysql

# Linux
sudo systemctl start mysql

# Windows
# Use Services app
```

---

#### 3. Git
```bash
# Check if installed
git --version
# Should show: git version 2.30.0 or higher
```

**Install:**
- **MacOS:** `brew install git`
- **Linux:** `sudo apt install git`
- **Windows:** Download from [git-scm.com](https://git-scm.com/downloads)

---

### Optional Tools

#### Text Editor / IDE
- **VS Code** (recommended): [code.visualstudio.com](https://code.visualstudio.com/)
- **PyCharm Community**: [jetbrains.com/pycharm](https://www.jetbrains.com/pycharm/)
- **Vim** / **Nano** (command line)

---

## 🐳 For DOCKER Deployment

### Required Tools

#### 1. Docker Desktop 20.10+
```bash
# Check if installed
docker --version
# Should show: Docker version 20.10.0 or higher

docker-compose --version
# Should show: Docker Compose version 2.0.0 or higher
```

**Install Docker Desktop** (includes Docker Compose):

- **MacOS:** Download from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/)
- **Windows:** Download from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/)
- **Linux:** Use Docker Engine instead:
  ```bash
  # Ubuntu/Debian
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  sudo usermod -aG docker $USER
  # Log out and back in
  ```

**Start Docker:**
- **MacOS/Windows:** Launch Docker Desktop app
- **Linux:** `sudo systemctl start docker`

**Verify:**
```bash
# Run hello-world container
docker run hello-world
# Should see: "Hello from Docker!"
```

---

#### 2. Git
Same as Local deployment (see above).

---

### Optional Tools

#### Docker Extensions (for Docker Desktop)
- **Logs Explorer** - View container logs easily
- **Resource Usage** - Monitor CPU/memory
- **Disk Usage** - Clean up unused images

---

## ☸️ For KUBERNETES Deployment (GCP)

### Required Tools

#### 1. Google Cloud Account
**Create account:** [cloud.google.com/free](https://cloud.google.com/free)

**Free tier includes:**
- $300 credit for 90 days
- Always-free tier (some services)

**⚠️ Billing Required:**
- Credit card needed (won't be charged without permission)
- GKE cluster costs ~$90-100/month if left running
- **Delete resources after testing to avoid charges!**

---

#### 2. gcloud CLI 400.0+
```bash
# Check if installed
gcloud --version
# Should show: Google Cloud SDK 400.0.0 or higher
```

**Install:**

**MacOS:**
```bash
brew install --cask google-cloud-sdk
```

**Linux:**
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

**Windows:**
Download installer from [cloud.google.com/sdk/docs/install](https://cloud.google.com/sdk/docs/install)

**Initialize:**
```bash
gcloud init
# Follow prompts to login and configure
```

**Verify:**
```bash
gcloud auth list
# Should show your Google account

gcloud config list
# Should show your project
```

---

#### 3. kubectl 1.25+
```bash
# Check if installed
kubectl version --client
# Should show: Client Version v1.25.0 or higher
```

**Install via gcloud:**
```bash
gcloud components install kubectl
```

**Or standalone:**
- **MacOS:** `brew install kubectl`
- **Linux:** 
  ```bash
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  ```
- **Windows:** `choco install kubernetes-cli`

**Verify:**
```bash
kubectl version --client
```

---

#### 4. Terraform 1.5+
```bash
# Check if installed
terraform --version
# Should show: Terraform v1.5.0 or higher
```

**Install:**

**MacOS:**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

**Linux:**
```bash
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

**Windows:**
```bash
choco install terraform
```

**Verify:**
```bash
terraform --version
```

---

#### 5. Docker (for building images)
Same as Docker deployment (see above).

---

#### 6. Git
Same as Local deployment (see above).

---

### GCP Setup Steps

#### 1. Enable Billing
1. Go to [console.cloud.google.com/billing](https://console.cloud.google.com/billing)
2. Link credit card (free $300 credit)
3. Verify billing enabled

---

#### 2. Create Project
```bash
# Create new project
gcloud projects create voting-app-demo-12345 --name="Voting App Demo"

# Set as default
gcloud config set project voting-app-demo-12345

# Link billing
gcloud billing projects link voting-app-demo-12345 \
  --billing-account=BILLING_ACCOUNT_ID
```

---

#### 3. Enable APIs
```bash
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable servicenetworking.googleapis.com
```

**Wait 1-2 minutes for APIs to activate.**

---

#### 4. Create Service Account
```bash
# Create service account
gcloud iam service-accounts create voting-app-sa \
  --display-name="Voting App Service Account"

# Get email
SA_EMAIL=$(gcloud iam service-accounts list \
  --filter="displayName:Voting App Service Account" \
  --format="value(email)")

# Grant permissions
gcloud projects add-iam-policy-binding voting-app-demo-12345 \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/container.admin"

gcloud projects add-iam-policy-binding voting-app-demo-12345 \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/cloudsql.admin"

gcloud projects add-iam-policy-binding voting-app-demo-12345 \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/compute.networkAdmin"

# Create key
mkdir -p ~/certs
gcloud iam service-accounts keys create ~/certs/gke-default-sa-key.json \
  --iam-account=$SA_EMAIL
```

**⚠️ CRITICAL:** Never commit `gke-default-sa-key.json` to Git!

---

## 🧰 Optional but Recommended Tools

### 1. Terminal Multiplexer
**tmux** or **screen** - Manage multiple terminal sessions

```bash
# MacOS/Linux
brew install tmux
# or
sudo apt install tmux
```

---

### 2. JSON Processor
**jq** - Parse JSON in command line

```bash
# MacOS
brew install jq

# Linux
sudo apt install jq

# Test
kubectl get pods -n voting-app -o json | jq '.items[].metadata.name'
```

---

### 3. HTTP Client
**curl** - Already installed on most systems

```bash
# Test
curl --version
```

**Alternative:** **httpie** for prettier output
```bash
brew install httpie
# or
pip install httpie
```

---

### 4. Watch Command
**watch** - Continuously monitor command output

```bash
# MacOS
brew install watch

# Linux (usually pre-installed)
watch kubectl get pods -n voting-app
```

---

### 5. Cloud Costs Monitoring
**Google Cloud Console app** (Mobile)
- Monitor costs in real-time
- Get billing alerts
- Shutdown resources remotely

---

## ✅ Verification Checklist

Run this complete verification:

```bash
#!/bin/bash
echo "=== Verifying Prerequisites ==="

# Git
echo -n "Git: "
git --version || echo "❌ NOT INSTALLED"

# Python (for Local)
echo -n "Python: "
python3 --version || echo "❌ NOT INSTALLED"

# MySQL (for Local)
echo -n "MySQL: "
mysql --version || echo "❌ NOT INSTALLED"

# Docker
echo -n "Docker: "
docker --version || echo "❌ NOT INSTALLED"

# Docker Compose
echo -n "Docker Compose: "
docker-compose --version || echo "❌ NOT INSTALLED"

# gcloud (for Kubernetes)
echo -n "gcloud: "
gcloud --version 2>/dev/null | head -1 || echo "❌ NOT INSTALLED"

# kubectl (for Kubernetes)
echo -n "kubectl: "
kubectl version --client --short 2>/dev/null || echo "❌ NOT INSTALLED"

# Terraform (for Kubernetes)
echo -n "Terraform: "
terraform --version | head -1 || echo "❌ NOT INSTALLED"

echo ""
echo "=== Docker Status ==="
docker info >/dev/null 2>&1 && echo "✅ Docker is running" || echo "❌ Docker is not running"

echo ""
echo "=== GCP Authentication ==="
gcloud auth list 2>/dev/null | grep ACTIVE || echo "❌ Not authenticated to GCP"

echo ""
echo "=== All checks complete ==="
```

Save as `check-prerequisites.sh`, make executable, and run:
```bash
chmod +x check-prerequisites.sh
./check-prerequisites.sh
```

---

## 🎓 Learning Resources

### Before Starting

**New to command line?**
- [Linux Command Line Basics](https://ubuntu.com/tutorials/command-line-for-beginners)
- [Command Line Crash Course](https://developer.mozilla.org/en-US/docs/Learn/Tools_and_testing/Understanding_client-side_tools/Command_line)

**New to Git?**
- [Git Handbook](https://guides.github.com/introduction/git-handbook/)
- [Learn Git Branching](https://learngitbranching.js.org/)

**New to Docker?**
- [Docker Getting Started](https://docs.docker.com/get-started/)
- [Docker for Beginners](https://docker-curriculum.com/)

**New to Kubernetes?**
- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)

---

## 💰 Cost Considerations

### Free Tier (GCP)
- $300 credit for 90 days (new users)
- Some services always free (with limits)

### Paid Resources
| Resource | Cost (est.) |
|----------|-------------|
| GKE Cluster (3 nodes, e2-medium, preemptible) | ~$50/month |
| Cloud SQL (db-f1-micro) | ~$15/month |
| Load Balancer | ~$20/month |
| Network egress | ~$5-10/month |
| **Total** | **~$90-100/month** |

**To minimize costs:**
1. ✅ Use preemptible nodes (enabled by default)
2. ✅ Delete resources when not in use: `./scripts/deployment/cleanup-resources.sh`
3. ✅ Set billing alerts in GCP Console
4. ✅ Use smallest instance types for learning
5. ✅ Monitor usage regularly

---

## 🆘 Troubleshooting Prerequisites

### Docker won't start
**MacOS/Windows:** 
- Ensure Docker Desktop is running (check system tray)
- Try restarting Docker Desktop

**Linux:**
```bash
sudo systemctl start docker
sudo systemctl enable docker  # Start on boot
```

---

### gcloud auth fails
```bash
# Clear existing auth
gcloud auth revoke --all

# Re-authenticate
gcloud auth login

# Application default credentials
gcloud auth application-default login
```

---

### kubectl can't connect
```bash
# Get cluster credentials
gcloud container clusters get-credentials CLUSTER_NAME \
  --location=LOCATION \
  --project=PROJECT_ID

# Verify connection
kubectl cluster-info
```

---

### Terraform provider issues
```bash
# Re-initialize
cd 3-KUBERNETES/terraform
rm -rf .terraform
terraform init -upgrade
```

---

## ✅ Ready to Start!

Once all prerequisites are met:

1. **Local:** Follow [docs/guides/LOCAL_SETUP.md](docs/guides/LOCAL_SETUP.md)
2. **Docker:** Follow [QUICKSTART.md](../QUICKSTART.md)
3. **Kubernetes:** Follow [docs/TUTORIAL.md](TUTORIAL.md)

**Questions?** Check [FAQ.md](../FAQ.md) or [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)

---

**Good luck! 🚀**
