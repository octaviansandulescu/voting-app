# 🎓 TUTORIAL: Deploy Your First Cloud Application (30 Minutes)

**Welcome!** This hands-on tutorial will guide you step-by-step through deploying the Voting App to Kubernetes on Google Cloud Platform.

**What you'll learn:**
- ✅ Setting up Google Cloud Platform
- ✅ Creating a Kubernetes cluster
- ✅ Deploying a multi-tier application
- ✅ Accessing your live application on the internet
- ✅ Troubleshooting common issues

**Time required:** 30 minutes
**Cost:** ~$2 (if you clean up after)
**Level:** Beginner-friendly

---

## 📋 Prerequisites Checklist

Before starting, make sure you have:

- [ ] Google Cloud account ([sign up here](https://cloud.google.com/free) - $300 free credits!)
- [ ] Credit card added to GCP (required even for free tier)
- [ ] Terminal/command line access (Linux, Mac, or WSL on Windows)
- [ ] Git installed: `git --version`
- [ ] Basic terminal knowledge (cd, ls, running commands)

**Time:** 10 minutes to set up prerequisites

---

## 🚀 STEP 1: Install Required Tools (5 min)

### 1.1 Install gcloud CLI

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
Download from: https://cloud.google.com/sdk/docs/install

**Verify:**
```bash
gcloud --version
# Should show: Google Cloud SDK 400.0.0+
```

---

### 1.2 Install kubectl

```bash
gcloud components install kubectl
```

**Verify:**
```bash
kubectl version --client
# Should show: Client Version 1.25+
```

---

### 1.3 Install Terraform

**MacOS:**
```bash
brew install terraform
```

**Linux:**
```bash
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

**Verify:**
```bash
terraform --version
# Should show: Terraform v1.5.0+
```

---

## ☁️ STEP 2: Setup Google Cloud Project (5 min)

### 2.1 Login to Google Cloud

```bash
gcloud auth login
```

This opens a browser window. Login with your Google account.

---

### 2.2 Create a new GCP project

```bash
# Replace YOUR-PROJECT-NAME with something unique
gcloud projects create voting-app-demo-12345 --name="Voting App Demo"

# Set as default project
gcloud config set project voting-app-demo-12345
```

**📝 Note:** Project ID must be globally unique. If taken, try adding numbers.

---

### 2.3 Enable billing

```bash
# List billing accounts
gcloud billing accounts list

# Link billing (replace BILLING_ACCOUNT_ID)
gcloud billing projects link voting-app-demo-12345 \
  --billing-account=BILLING_ACCOUNT_ID
```

**Alternative:** Enable billing via [Console](https://console.cloud.google.com/billing)

---

### 2.4 Enable required APIs

```bash
gcloud services enable container.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable compute.googleapis.com
```

**Wait:** APIs take 1-2 minutes to activate.

---

### 2.5 Create service account

```bash
# Create service account
gcloud iam service-accounts create voting-app-sa \
  --display-name="Voting App Service Account"

# Get service account email
SA_EMAIL=$(gcloud iam service-accounts list \
  --filter="displayName:Voting App Service Account" \
  --format="value(email)")

echo "Service Account: $SA_EMAIL"
```

---

### 2.6 Grant permissions

```bash
# Add required roles
gcloud projects add-iam-policy-binding voting-app-demo-12345 \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/container.admin"

gcloud projects add-iam-policy-binding voting-app-demo-12345 \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/cloudsql.admin"

gcloud projects add-iam-policy-binding voting-app-demo-12345 \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/compute.networkAdmin"
```

---

### 2.7 Create and download key

```bash
# Create credentials directory
mkdir -p ~/certs

# Generate key file
gcloud iam service-accounts keys create ~/certs/gke-default-sa-key.json \
  --iam-account=$SA_EMAIL

# Verify file exists
ls -lh ~/certs/gke-default-sa-key.json
```

**⚠️ IMPORTANT:** Never commit this file to Git! It's like a password.

---

## 📥 STEP 3: Clone and Setup Project (2 min)

### 3.1 Clone repository

```bash
cd ~
git clone https://github.com/octaviansandulescu/voting-app.git
cd voting-app
```

---

### 3.2 Set environment variables

```bash
export GCP_CREDENTIALS=~/certs/gke-default-sa-key.json
export GOOGLE_APPLICATION_CREDENTIALS="$GCP_CREDENTIALS"

# Verify
echo $GOOGLE_APPLICATION_CREDENTIALS
# Should show: /home/YOUR_USER/certs/gke-default-sa-key.json
```

**💡 Tip:** Add these to `~/.bashrc` or `~/.zshrc` to persist across sessions.

---

### 3.3 Update Terraform variables

```bash
cd 3-KUBERNETES/terraform

# Edit variables.tf
nano variables.tf
```

Update the `project_id`:
```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "voting-app-demo-12345"  # ← Change this to your project ID
}
```

**Save:** `Ctrl+O`, `Enter`, `Ctrl+X`

---

## 🎯 STEP 4: Deploy Everything! (15 min)

### 4.1 Initialize Terraform

```bash
cd ~/voting-app/3-KUBERNETES/terraform

terraform init
```

**Expected output:**
```
Terraform has been successfully initialized!
```

---

### 4.2 Deploy infrastructure

```bash
terraform apply -auto-approve
```

**What happens:**
- Creates VPC network and subnet
- Creates GKE cluster (3 nodes) ⏱️ ~10 min
- Creates Cloud SQL MySQL database ⏱️ ~5 min
- Configures firewall rules
- Sets up networking

**☕ Time for coffee!** This takes 10-15 minutes.

**Expected output (at the end):**
```
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

kubernetes_cluster_host = <sensitive>
sql_instance_ip = "34.45.164.175"
```

---

### 4.3 Deploy application

```bash
cd ~/voting-app

# Run deployment script
./scripts/deployment/start-deployment.sh
```

**What happens:**
- Configures kubectl to connect to your cluster
- Creates `voting-app` namespace
- Generates database secrets from Terraform
- Deploys backend (2 replicas)
- Deploys frontend (2 replicas)
- Creates LoadBalancer for external access
- Initializes database schema

**Expected output:**
```
✅ Backend ready
✅ Frontend ready
✅ Frontend available at: http://34.61.93.145
```

**⏱️ Time:** 3-5 minutes

---

## 🎉 STEP 5: Access Your Application! (1 min)

### 5.1 Get the external IP

```bash
kubectl get svc frontend-service -n voting-app
```

**Output:**
```
NAME               TYPE           EXTERNAL-IP      PORT(S)
frontend-service   LoadBalancer   34.61.93.145     80:31998/TCP
```

---

### 5.2 Open in browser

```
http://34.61.93.145
```

**Replace `34.61.93.145` with YOUR external IP!**

---

### 5.3 Test the application

1. ✅ **Vote for Dogs** - Click the Dogs button
2. ✅ **Vote for Cats** - Click the Cats button
3. ✅ **See results** - Watch counters update in real-time!

---

### 5.4 Test the API

```bash
# Get current results
curl http://34.61.93.145/api/results

# Submit a vote
curl -X POST http://34.61.93.145/api/vote \
  -H 'Content-Type: application/json' \
  -d '{"vote":"dogs"}'

# Check results again
curl http://34.61.93.145/api/results
```

---

## 🔍 STEP 6: Explore Your Deployment (5 min)

### 6.1 View running pods

```bash
kubectl get pods -n voting-app
```

**Output:**
```
NAME                        READY   STATUS    RESTARTS   AGE
backend-xxx-xxx             1/1     Running   0          5m
backend-yyy-yyy             1/1     Running   0          5m
frontend-zzz-zzz            1/1     Running   0          5m
frontend-www-www            1/1     Running   0          5m
```

**Explanation:**
- 2 backend pods (for load balancing)
- 2 frontend pods (for high availability)

---

### 6.2 View pod logs

```bash
# Backend logs
kubectl logs -n voting-app deployment/backend -f

# Frontend logs (Nginx access logs)
kubectl logs -n voting-app deployment/frontend -f
```

**Press `Ctrl+C` to stop following logs.**

---

### 6.3 View services

```bash
kubectl get svc -n voting-app
```

**Output:**
```
NAME               TYPE           CLUSTER-IP   EXTERNAL-IP      PORT(S)
backend-service    ClusterIP      10.8.4.5     <none>           8000/TCP
frontend-service   LoadBalancer   10.8.8.60    34.61.93.145     80:31998/TCP
```

**Explanation:**
- Backend: Internal only (ClusterIP)
- Frontend: Publicly accessible (LoadBalancer with external IP)

---

### 6.4 Check cluster nodes

```bash
kubectl get nodes
```

**Output:**
```
NAME                          STATUS   ROLES    AGE   VERSION
gke-voting-xxx-node-pool-xxx  Ready    <none>   15m   v1.33.5-gke.1201000
gke-voting-xxx-node-pool-yyy  Ready    <none>   15m   v1.33.5-gke.1201000
gke-voting-xxx-node-pool-zzz  Ready    <none>   15m   v1.33.5-gke.1201000
```

**Explanation:** 3 nodes running your application pods.

---

### 6.5 Check database connection

```bash
# Get database IP from secrets
kubectl get secret db-credentials -n voting-app -o jsonpath='{.data.DB_HOST}' | base64 -d
echo

# View all secrets (passwords are base64 encoded)
kubectl get secret db-credentials -n voting-app -o yaml
```

---

## 🧹 STEP 7: Clean Up (to avoid charges!) (5 min)

**IMPORTANT:** Don't skip this if you want to avoid charges!

### 7.1 Run cleanup script

```bash
cd ~/voting-app
./scripts/deployment/cleanup-resources.sh
```

**When prompted, type:** `DELETE`

**What it does:**
- Deletes GKE cluster
- Deletes Cloud SQL database
- Removes all infrastructure

**⏱️ Takes:** 5-10 minutes

---

### 7.2 Verify everything is deleted

```bash
# Check clusters
gcloud container clusters list

# Check SQL instances
gcloud sql instances list

# Should show: Listed 0 items
```

---

### 7.3 (Optional) Delete GCP project

If you're completely done:
```bash
gcloud projects delete voting-app-demo-12345
```

**⚠️ WARNING:** This deletes EVERYTHING in the project permanently!

---

## 🎓 What You Just Learned!

Congratulations! You just:

✅ Set up Google Cloud Platform from scratch
✅ Created a Kubernetes cluster with 3 nodes
✅ Deployed a multi-tier application (frontend, backend, database)
✅ Configured networking and load balancing
✅ Accessed your application over the internet
✅ Explored Kubernetes resources (pods, services, deployments)
✅ Cleaned up resources properly

**Skills gained:**
- Cloud platform setup (GCP)
- Infrastructure as Code (Terraform)
- Container orchestration (Kubernetes)
- kubectl CLI usage
- Networking basics (LoadBalancers, ClusterIP)
- Cloud cost management

---

## 🚀 Next Steps

Now that you've completed the basics, try these challenges:

### Beginner:
1. **Modify frontend:** Change colors/text in `src/frontend/index.html`
2. **Scale application:** Increase replicas to 5
3. **View metrics:** Install metrics-server and check resource usage

### Intermediate:
4. **Add monitoring:** Set up Prometheus and Grafana
5. **Add SSL/HTTPS:** Configure Ingress with TLS certificate
6. **Set up CI/CD:** Create GitHub Actions workflow for auto-deploy

### Advanced:
7. **Add authentication:** Implement user login
8. **Multi-region deployment:** Deploy to multiple GCP regions
9. **Migrate to microservices:** Split backend into separate services

---

## 🐛 Troubleshooting

### Problem: "Permission denied" errors
**Solution:** Make sure service account has all required roles (Step 2.6)

### Problem: "Cluster creation failed"
**Solution:** Check billing is enabled and APIs are activated (Step 2.3-2.4)

### Problem: "Can't access external IP"
**Solution:** 
- Wait 2-5 minutes for LoadBalancer to provision
- Use `http://` not `https://`
- Check firewall rules allow port 80

### Problem: "Pods in CrashLoopBackOff"
**Solution:** Check logs: `kubectl logs -n voting-app <POD_NAME>`

**More help:** See [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)

---

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Google Cloud Free Tier](https://cloud.google.com/free)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

## 💬 Questions or Issues?

- 📖 Check [FAQ.md](../FAQ.md)
- 🐛 See [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)
- 💬 Open GitHub Issue
- 📧 Contact maintainers

---

**Congratulations on completing the tutorial! 🎉**

You're now ready to explore more complex Kubernetes deployments and cloud architectures!

**Share your success:**
- Tweet about it with #VotingAppTutorial
- Star the repository on GitHub ⭐
- Help others in Issues/Discussions

**Happy learning! 🚀**
