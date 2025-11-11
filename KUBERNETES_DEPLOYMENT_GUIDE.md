# ☸️ KUBERNETES DEPLOYMENT GUIDE - VOTING APP ON GCP

> **Timp estimat: 45-60 minute (15-20 min pentru GCP setup)**
>
> Aceasta este guida completa pentru deploy pe Kubernetes cu Terraform + GKE

---

## PRE-REQUIREMENTS

Verifica sa ai instalate:

```bash
# Check Terraform
terraform --version
# Expected: Terraform v1.0+

# Check gcloud CLI
gcloud --version
# Expected: Google Cloud SDK x.x.x

# Check kubectl
kubectl version --client
# Expected: Client Version: vx.xx.x

# Check GCP authentication
gcloud auth list
# Should show active account with @gmail.com
```

---

## STEP 1: SET GCP PROJECT

```bash
# Set your GCP project
export GCP_PROJECT="diesel-skyline-474415-j6"
export GCP_REGION="us-central1"

# Set as default
gcloud config set project $GCP_PROJECT

# Verify
gcloud config get-value project
# Output: diesel-skyline-474415-j6
```

---

## STEP 2: TERRAFORM INITIALIZATION

```bash
cd 3-KUBERNETES/terraform

# Initialize Terraform
terraform init

# Expected output:
# Initializing the backend...
# Initializing provider plugins...
# Terraform has been successfully configured!
```

---

## STEP 3: VALIDATE TERRAFORM

```bash
# Validate configuration
terraform validate

# Expected output:
# Success! The configuration is valid.

# Show what will be created
terraform plan

# This shows:
# - GCP VPC Network
# - GCP Subnets
# - GKE Cluster (3 nodes)
# - Cloud SQL MySQL Instance
# - Firewall rules
```

---

## STEP 4: APPLY TERRAFORM (CREATE INFRASTRUCTURE)

⚠️ **WARNING:** This creates real GCP resources that will cost money!

```bash
# Create plan file
terraform plan -out=tfplan

# Apply - This takes 10-15 MINUTES
terraform apply tfplan

# Wait for completion...
# Output:
# Apply complete! Resources: 8 added, 0 changed, 0 destroyed
# 
# Outputs:
# gke_cluster_name = "voting-app-cluster"
# gke_cluster_region = "us-central1"
```

**PAUZA 10 MINUTE - GCP creeaza resurse!**

---

## STEP 5: GET KUBERNETES CREDENTIALS

```bash
# Get cluster credentials
gcloud container clusters get-credentials voting-app-cluster \
  --region us-central1 \
  --project diesel-skyline-474415-j6

# Expected output:
# Fetching cluster endpoint and auth...
# kubeconfig entry generated for voting-app-cluster

# Verify kubectl connection
kubectl cluster-info

# Expected output:
# Kubernetes master is running at https://...
```

---

## STEP 6: DEPLOY APPLICATION

```bash
cd ../k8s

# Apply all Kubernetes manifests
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-secrets.yaml
kubectl apply -f 02-backend-deployment.yaml
kubectl apply -f 03-frontend-deployment.yaml

# Verify
kubectl get pods -n voting-app
kubectl get svc -n voting-app

# Expected:
# NAME                        READY   STATUS    RESTARTS   AGE
# backend-xxxxxxxxxx-xxxxx    1/1     Running   0          2m
# backend-xxxxxxxxxx-xxxxx    1/1     Running   0          2m
# frontend-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
# frontend-xxxxxxxxxx-xxxxx   1/1     Running   0          2m
```

---

## STEP 7: WAIT FOR LOADBALANCER

```bash
# Watch for LoadBalancer IP
kubectl get svc frontend -n voting-app -w

# Wait until you see an EXTERNAL-IP (not <pending>)
# This may take 2-3 minutes

# Expected:
# NAME       TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)
# frontend   LoadBalancer   10.x.x.x        35.192.xxx.xxx 80:30xxx/TCP
```

---

## STEP 8: TEST APPLICATION

```bash
# Get the IP
FRONTEND_IP=$(kubectl get svc frontend -n voting-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test frontend
curl http://$FRONTEND_IP

# Test backend health
curl http://$FRONTEND_IP/api/health

# Test voting
curl -X POST http://$FRONTEND_IP/api/vote \
  -H "Content-Type: application/json" \
  -d '{"vote":"dogs"}'

# Check results
curl http://$FRONTEND_IP/api/results
```

---

## STEP 9: OPEN IN BROWSER

```bash
# Get IP
FRONTEND_IP=$(kubectl get svc frontend -n voting-app \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Open in browser: http://$FRONTEND_IP"
```

Expected to see:
- ✓ Title "Vote: Dogs vs Cats"
- ✓ Two vote buttons
- ✓ Real-time results
- ✓ Data persistence

---

## STEP 10: CHECK LOGS

```bash
# Backend logs
kubectl logs -n voting-app -l app=backend

# Follow logs in real-time
kubectl logs -n voting-app -l app=backend -f

# Frontend logs
kubectl logs -n voting-app -l app=frontend

# Database status
kubectl get pods -n voting-app
kubectl describe pod <pod-name> -n voting-app
```

---

## STEP 11: SCALE DEPLOYMENT

```bash
# Scale backend to 5 replicas
kubectl scale deployment backend -n voting-app --replicas=5

# Watch scaling
kubectl get pods -n voting-app -w

# Scale back down
kubectl scale deployment backend -n voting-app --replicas=2
```

---

## STEP 12: VERIFY DATA PERSISTENCE

```bash
# Delete a backend pod
kubectl delete pod -l app=backend -n voting-app

# New pod starts automatically
kubectl get pods -n voting-app

# Data should still be in database
curl http://$FRONTEND_IP/api/results

# Vote counts should be same (data persisted in Cloud SQL)
```

---

## TROUBLESHOOTING

### LoadBalancer IP stuck on <pending>

```bash
# Check events
kubectl describe svc frontend -n voting-app

# If quota exceeded:
gcloud compute project-info describe --project=diesel-skyline-474415-j6 | grep QUOTA
```

### Pod stuck in CrashLoopBackOff

```bash
# Check logs
kubectl logs <pod-name> -n voting-app

# Check pod events
kubectl describe pod <pod-name> -n voting-app

# Check if database is ready
kubectl get pods -n voting-app
# Database pod should be Running
```

### Backend can't connect to Cloud SQL

```bash
# Check Cloud SQL instance
gcloud sql instances list

# Check network connectivity
kubectl exec -it <backend-pod> -n voting-app -- /bin/bash
# Inside pod:
# ping cloud-sql-instance-ip

# Check Secrets
kubectl get secrets -n voting-app
kubectl describe secret db-credentials -n voting-app
```

---

## CLEANUP - DESTROY INFRASTRUCTURE

⚠️ **This will delete everything on GCP!**

```bash
cd 3-KUBERNETES/terraform

# Destroy all resources
terraform destroy -auto-approve

# Wait for deletion (5-10 minutes)
# Verify everything is deleted:
gcloud container clusters list
gcloud sql instances list
gcloud compute networks list
```

---

## COMMANDS REFERENCE

```bash
# Kubernetes commands
kubectl get pods -n voting-app              # List pods
kubectl get svc -n voting-app               # List services
kubectl logs <pod> -n voting-app            # View logs
kubectl describe pod <pod> -n voting-app    # Get details
kubectl exec -it <pod> -n voting-app -- /bin/bash  # SSH into pod
kubectl scale deployment <name> -n voting-app --replicas=3  # Scale
kubectl delete pod <pod> -n voting-app      # Delete pod

# Terraform commands
terraform init                              # Initialize
terraform validate                          # Validate config
terraform plan                              # Show changes
terraform apply tfplan                      # Apply plan
terraform destroy                           # Delete all

# GCP commands
gcloud container clusters list               # List GKE clusters
gcloud sql instances list                    # List Cloud SQL
gcloud compute networks list                 # List networks
gcloud container clusters get-credentials <name> --region <region>
```

---

## MONITORING & DEBUGGING

```bash
# Watch all activity
kubectl get events -n voting-app --sort-by='.lastTimestamp'

# Check resource usage
kubectl top nodes
kubectl top pods -n voting-app

# Check deployment status
kubectl rollout status deployment/backend -n voting-app
kubectl rollout status deployment/frontend -n voting-app

# View pod details
kubectl get pods -n voting-app -o wide
kubectl get pods -n voting-app -o yaml
```

---

## SUCCESS CRITERIA

- [ ] Terraform plan shows correct resources
- [ ] Terraform apply completes without errors
- [ ] GKE cluster is visible in Google Cloud Console
- [ ] kubectl can connect to cluster
- [ ] All pods are Running
- [ ] Services show EXTERNAL-IP (not <pending>)
- [ ] Frontend accessible via LoadBalancer IP
- [ ] Voting functionality works
- [ ] Data persists after pod deletion

---

**GATA! Kubernetes deploy este complete! 🎉**
