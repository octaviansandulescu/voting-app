# 🐛 Troubleshooting Guide

Common errors and their solutions for the Voting App.

---

## 🔴 Docker Compose Errors

### Error: "Port 3306 already in use"

**Symptom:**
```
Error starting userland proxy: listen tcp4 0.0.0.0:3306: bind: address already in use
```

**Cause:** MySQL/MariaDB already running on your machine

**Solution:**
```bash
# Option 1: Stop local MySQL
sudo systemctl stop mysql
sudo systemctl stop mariadb

# Option 2: Change port in docker-compose.yml
# Edit: "3307:3306" instead of "3306:3306"

# Then restart
docker-compose down
docker-compose up -d
```

---

### Error: "Port 8000 already in use"

**Symptom:**
```
Error starting userland proxy: listen tcp4 0.0.0.0:8000: bind: address already in use
```

**Cause:** Another application using port 8000

**Solution:**
```bash
# Find what's using port 8000
lsof -i :8000

# Kill the process
kill -9 <PID>

# Or change port in docker-compose.yml
ports:
  - "8001:8000"  # Change 8000 to 8001
```

---

### Error: "Cannot connect to database"

**Symptom:**
```
Backend logs show: ERROR: Can't connect to MySQL server
```

**Cause:** Database not ready yet

**Solution:**
```bash
# Wait for database to be healthy
docker-compose ps

# Check db health
docker-compose logs db | grep "ready for connections"

# Restart backend after db is ready
docker-compose restart backend
```

---

### Error: "Image not found"

**Symptom:**
```
ERROR: pull access denied for voting-app-backend
```

**Cause:** Images need to be built first

**Solution:**
```bash
# Build images
docker-compose build

# Then start
docker-compose up -d
```

---

## 🔴 Kubernetes Errors

### Error: "NodePool in ERROR state"

**Symptom:**
```
ERROR: NodePool voting-app-cluster-node-pool was created in ERROR state
```

**Cause:** Cluster not fully initialized before NodePool creation

**Solution:**
```bash
# This is already fixed in current version with time_sleep resource
# If you still encounter this:

cd 3-KUBERNETES/terraform
terraform destroy -auto-approve
sleep 30
terraform apply -auto-approve
```

---

### Error: "namespace not found"

**Symptom:**
```
Error from server (NotFound): namespaces "voting-app" not found
```

**Cause:** Application not deployed yet

**Solution:**
```bash
# Deploy application
./scripts/deployment/start-deployment.sh

# Or manually create namespace
kubectl create namespace voting-app
```

---

### Error: "CrashLoopBackOff"

**Symptom:**
```
NAME                       READY   STATUS             RESTARTS
backend-xxx-xxx            0/1     CrashLoopBackOff   5
```

**Cause:** Pod can't start - check logs for specific error

**Solution:**
```bash
# Check pod logs
kubectl logs -n voting-app deployment/backend

# Common causes:
# 1. Can't connect to database → Check secrets
kubectl get secret db-credentials -n voting-app -o yaml

# 2. Wrong database IP → Regenerate secrets
cd scripts/deployment
./generate-secrets.sh
kubectl apply -f 01-secrets-generated.yaml -n voting-app

# 3. Memory limit too low → Increase in deployment yaml
# Edit: 3-KUBERNETES/k8s/02-backend-deployment.yaml
resources:
  limits:
    memory: "1024Mi"  # Increase from 512Mi
```

---

### Error: "ImagePullBackOff"

**Symptom:**
```
NAME                       READY   STATUS             RESTARTS
backend-xxx-xxx            0/1     ImagePullBackOff   0
```

**Cause:** Can't pull Docker image from registry

**Solution:**
```bash
# Check if images exist in GCR
gcloud container images list --project=YOUR_PROJECT_ID

# If missing, build and push:
cd src/backend
docker build -t gcr.io/YOUR_PROJECT_ID/voting-app-backend:latest .
docker push gcr.io/YOUR_PROJECT_ID/voting-app-backend:latest

# Or use local registry alternative
```

---

### Error: "502 Bad Gateway" on Frontend

**Symptom:**
- Frontend loads but shows 502 error
- Can't vote or see results

**Cause:** Frontend can't reach backend service

**Solution:**
```bash
# Check backend service exists
kubectl get svc backend-service -n voting-app

# Check backend pods are running
kubectl get pods -n voting-app -l app=backend

# Check backend logs
kubectl logs -n voting-app deployment/backend

# Verify network policy allows traffic
kubectl get networkpolicies -n voting-app
```

---

### Error: "LoadBalancer IP pending"

**Symptom:**
```
frontend-service   LoadBalancer   10.8.8.60   <pending>   80:31998/TCP
```

**Cause:** GCP still provisioning external IP (normal, takes 2-5 minutes)

**Solution:**
```bash
# Wait a few minutes, then check again
kubectl get svc frontend-service -n voting-app

# If stuck for >10 min, check:
# 1. GCP quota limits
gcloud compute project-info describe --project=YOUR_PROJECT_ID

# 2. Service account permissions
gcloud projects get-iam-policy YOUR_PROJECT_ID

# 3. Delete and recreate service
kubectl delete svc frontend-service -n voting-app
kubectl apply -f 3-KUBERNETES/k8s/03-frontend-deployment.yaml -n voting-app
```

---

## 🔴 Terraform Errors

### Error: "Inconsistent dependency lock file"

**Symptom:**
```
Error: Inconsistent dependency lock file
provider registry.terraform.io/hashicorp/time: required but no version selected
```

**Cause:** Terraform lock file out of sync

**Solution:**
```bash
cd 3-KUBERNETES/terraform
terraform init -upgrade
terraform apply
```

---

### Error: "403 Permission denied"

**Symptom:**
```
Error: Error creating Network: googleapi: Error 403: Insufficient Permission
```

**Cause:** Service account lacks required permissions

**Solution:**
```bash
# Add required roles
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:YOUR_SA_EMAIL" \
  --role="roles/compute.networkAdmin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:YOUR_SA_EMAIL" \
  --role="roles/container.admin"
```

---

### Error: "Resource already exists"

**Symptom:**
```
Error: Error creating Cluster: googleapi: Error 409: Already exists
```

**Cause:** Resources exist from previous deployment

**Solution:**
```bash
# Import existing resources into state
terraform import google_container_cluster.voting_cluster \
  projects/YOUR_PROJECT_ID/locations/us-central1/clusters/voting-app-cluster

# Or destroy and recreate
terraform destroy -auto-approve
terraform apply -auto-approve
```

---

## 🔴 Database Errors

### Error: "Access denied for user"

**Symptom:**
```
ERROR: Access denied for user 'voting_user'@'IP' (using password: YES)
```

**Cause:** Wrong password in secrets

**Solution:**
```bash
# Kubernetes:
# Regenerate secrets from Terraform output
cd scripts/deployment
./generate-secrets.sh
kubectl apply -f 01-secrets-generated.yaml -n voting-app
kubectl rollout restart deployment/backend -n voting-app

# Docker Compose:
# Check .env file has correct DB_PASSWORD
cat .env | grep DB_PASSWORD
```

---

### Error: "Can't connect to MySQL server"

**Symptom:**
```
ERROR 2003 (HY000): Can't connect to MySQL server on 'X.X.X.X'
```

**Cause:** Firewall blocking connection or wrong IP

**Solution:**
```bash
# Check Cloud SQL IP
gcloud sql instances describe voting-app-cluster-db \
  --format="value(ipAddresses[0].ipAddress)"

# Check firewall rules
gcloud compute firewall-rules list | grep cloudsql

# Test connection manually
mysql -h CLOUD_SQL_IP -u voting_user -p
```

---

### Error: "Table doesn't exist"

**Symptom:**
```
ERROR: Table 'voting_app_k8s.votes' doesn't exist
```

**Cause:** Database not initialized

**Solution:**
```bash
# Kubernetes: Run db-init job
kubectl apply -f 3-KUBERNETES/k8s/01-db-init-job.yaml -n voting-app
kubectl wait --for=condition=complete job/db-init -n voting-app --timeout=120s

# Docker Compose: Restart with init.sql
docker-compose down -v
docker-compose up -d
```

---

## 🔴 Network Errors

### Error: "Connection timeout"

**Symptom:**
- Browser: "Connection timed out"
- Can't access external IP

**Cause:** Firewall blocking HTTP traffic

**Solution:**
```bash
# Check if firewall rule exists
gcloud compute firewall-rules list | grep allow-http

# Create firewall rule if missing
gcloud compute firewall-rules create allow-http \
  --allow tcp:80 \
  --source-ranges 0.0.0.0/0 \
  --target-tags http-server
```

---

### Error: "HTTPS not working"

**Symptom:**
- `https://IP` doesn't load
- Only `http://IP` works

**Cause:** No SSL certificate configured

**Solution:**
This is expected! Current setup only supports HTTP (port 80).

For HTTPS, you need:
1. Domain name
2. SSL certificate (Let's Encrypt)
3. Ingress with TLS configuration

See: `docs/guides/SSL_SETUP.md` (TODO)

---

## 🔴 Performance Issues

### Error: "Application very slow"

**Symptom:**
- Page loads take >10 seconds
- API responses delayed

**Cause:** Resource limits too low or database overloaded

**Solution:**
```bash
# Check resource usage
kubectl top pods -n voting-app
kubectl top nodes

# Increase memory/CPU limits
# Edit: 3-KUBERNETES/k8s/02-backend-deployment.yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "500m"
  limits:
    memory: "1024Mi"
    cpu: "1000m"

# Apply changes
kubectl apply -f 3-KUBERNETES/k8s/02-backend-deployment.yaml -n voting-app
```

---

## 📊 Debugging Commands

### Docker Compose
```bash
# View logs
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f db

# Check container status
docker-compose ps

# Restart specific service
docker-compose restart backend

# Execute command in container
docker-compose exec backend bash
docker-compose exec db mysql -u root -p
```

### Kubernetes
```bash
# View pod logs
kubectl logs -n voting-app deployment/backend -f
kubectl logs -n voting-app deployment/frontend -f

# Describe pod (see events)
kubectl describe pod -n voting-app <POD_NAME>

# Execute command in pod
kubectl exec -it -n voting-app <POD_NAME> -- bash

# Port forward for testing
kubectl port-forward -n voting-app deployment/backend 8000:8000
```

### Terraform
```bash
# Show current state
terraform show

# View outputs
terraform output

# Validate configuration
terraform validate

# Plan before apply
terraform plan

# Show detailed logs
export TF_LOG=DEBUG
terraform apply
```

---

## 🆘 Still Stuck?

1. **Check logs:** Always start with logs (`docker-compose logs` or `kubectl logs`)
2. **Search issues:** Check GitHub Issues for similar problems
3. **Ask for help:** Open a new Issue with:
   - Error message (full output)
   - Commands you ran
   - Your environment (OS, Docker version, etc.)
4. **Read documentation:** See [docs/](docs/) for detailed guides

---

**Most common solution:** Turn it off and on again! 😄
```bash
# Docker Compose
docker-compose down && docker-compose up -d

# Kubernetes
kubectl delete namespace voting-app
./scripts/deployment/start-deployment.sh
```
