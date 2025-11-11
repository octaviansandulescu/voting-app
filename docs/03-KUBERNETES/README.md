# MOD 3: KUBERNETES + GCP - Tutorial Complet

> **Timp estimat: 45 minute**
>
> In acest mod invatii cum sa deployezi pe cloud folosind Kubernetes si GCP.

## Ce Invatii

- ✅ Kubernetes concepts (Pods, Deployments, Services)
- ✅ GCP + GKE (Google Kubernetes Engine)
- ✅ Terraform Infrastructure as Code
- ✅ Cloud SQL managed database
- ✅ LoadBalancer + Ingress
- ✅ kubectl commands
- ✅ Pod scaling si health checks

---

## Prerequisites

```bash
# Verifica gcloud
gcloud --version
# Output: Google Cloud SDK x.x.x

# Verifica kubectl
kubectl version --client
# Output: Client Version: vx.xx.x

# Verifica Terraform
terraform --version
# Output: Terraform v1.x.x

# Verifica ca MOD 2 e oprit
docker-compose -f 2-DOCKER/docker-compose.yml down -v
```

---

## GCP Setup Initial

```bash
# Set project
export GCP_PROJECT="diesel-skyline-474415-j6"
export GCP_REGION="us-central1"
export GCP_ZONE="us-central1-a"

# Verifica gcloud autentificare
gcloud auth list

# Daca nu e autentificat:
gcloud auth login

# Set default project
gcloud config set project $GCP_PROJECT

# Verifica
gcloud config get-value project
# Ar trebui sa arate: diesel-skyline-474415-j6
```

---

## Structura KUBERNETES

```
3-KUBERNETES/
├── README.md                    # Acest fisier
├── terraform/
│   ├── main.tf                 # GKE + Cloud SQL
│   ├── variables.tf            # Variables
│   ├── outputs.tf              # Outputs
│   └── terraform.tfvars        # Values (IGNORED in .gitignore)
└── k8s/
    ├── 00-namespace.yaml       # Namespace "voting-app"
    ├── 01-secrets.yaml         # DB credentials
    ├── 02-backend-deployment.yaml
    ├── 03-frontend-deployment.yaml
    ├── 04-backend-service.yaml
    ├── 05-frontend-service.yaml
    └── 06-healthcheck.yaml     # Readiness/Liveness probes
```

---

## STEP 1: Intelege Terraform

**Ce face Terraform:**

```hcl
# 1. Creaza GKE cluster
resource "google_container_cluster" "voting_cluster" {
  name       = "voting-cluster"
  location   = var.gcp_region
  
  # 3 nodes minimum
  initial_node_count = 3
}

# 2. Creaza Cloud SQL (MySQL)
resource "google_sql_database_instance" "voting_db" {
  name             = "voting-db-instance"
  database_version = "MYSQL_8_0"
  region           = var.gcp_region
}

# 3. Creaza networking
resource "google_compute_network" "voting_network" {
  name = "voting-network"
}
```

**Key concepts:**
- Resources - Ce vrei sa creezi
- Variables - Input values
- Outputs - Return values

---

## STEP 2: Setup Terraform Directory

```bash
cd 3-KUBERNETES/terraform

# Init - Download providers si modules
terraform init

# Asteptat:
# Initializing the backend...
# Initializing provider plugins...
# ...
# Terraform has been successfully configured!
```

---

## STEP 3: Planifica Deployment (terraform plan)

```bash
# Plan - Arata ce va schimba
terraform plan -out=tfplan

# Asteptat - ar trebui sa vada:
# Plan: 8 to add, 0 to change, 0 to destroy
#
# Schimbari:
# + google_container_cluster.voting_cluster
# + google_sql_database_instance.voting_db
# + google_compute_network.voting_network
# ... (alte resurse)

# Aceasta INCEPE sa creeze pe GCP - PODE LUA 10-15 MINUTE
```

---

## STEP 4: Aplica Terraform (terraform apply)

```bash
# Apply - CREAZA infrastructura
terraform apply tfplan

# Asteptat - LENT (10-15 min):
# google_compute_network.voting_network: Creating...
# google_compute_network.voting_network: Creation complete
# google_compute_subnetwork.voting_subnet: Creating...
# ...
# Apply complete! Resources: 8 added

# Finalul ar trebui:
# Outputs:
# gke_cluster_name = "voting-cluster"
# gke_cluster_region = "us-central1"
# cloud_sql_instance = "voting-db-instance"
```

**PAUZA 10 MINUTE - GCP creaza resurse!**

---

## STEP 5: Verifica Crearea

```bash
# Check GKE cluster
gcloud container clusters list

# Asteptat:
# NAME              LOCATION       MASTER_VERSION  NODES
# voting-cluster    us-central1-a  1.27.x         3

# Check Cloud SQL
gcloud sql instances list

# Asteptat:
# voting-db-instance  MYSQL_8_0  us-central1
```

---

## STEP 6: Get Credentials pentru kubectl

```bash
# Get kubeconfig
gcloud container clusters get-credentials voting-cluster \
  --region us-central1 \
  --project diesel-skyline-474415-j6

# Asteptat:
# Fetching cluster endpoint and auth...
# kubeconfig entry generated for voting-cluster.

# Verifica kubectl conectare
kubectl cluster-info

# Asteptat:
# Kubernetes master is running at https://...
# GLBCDefaultBackend is running at https://...
```

---

## STEP 7: Creaza Kubernetes Namespace

```bash
cd 3-KUBERNETES/k8s

# Aplica namespace
kubectl apply -f 00-namespace.yaml

# Asteptat:
# namespace/voting-app created

# Verifica
kubectl get namespaces

# Ar trebui sa vada: voting-app
```

---

## STEP 8: Creaza Secrets (DB Credentials)

```bash
# Aplica secrets
kubectl apply -f 01-secrets.yaml

# Asteptat:
# secret/db-credentials created

# Verifica
kubectl get secrets -n voting-app

# Ar trebui sa vada: db-credentials

# View secret (encoded)
kubectl describe secret db-credentials -n voting-app
```

---

## STEP 9: Deploya Backend

```bash
# Aplica backend deployment
kubectl apply -f 02-backend-deployment.yaml

# Asteptat:
# deployment.apps/backend created
# service/backend-service created

# Verifica deployment
kubectl get deployments -n voting-app

# Ar trebui:
# NAME      READY   UP-TO-DATE   AVAILABLE
# backend   2/2     2            2

# Wait pentru pod ready
kubectl wait --for=condition=ready pod \
  -l app=backend -n voting-app --timeout=300s

# Verifica pods
kubectl get pods -n voting-app

# Ar trebui sa vada: 2 backend pods
# backend-xxxxx   1/1   Running
# backend-yyyyy   1/1   Running
```

---

## STEP 10: Deploya Frontend

```bash
# Aplica frontend deployment
kubectl apply -f 03-frontend-deployment.yaml

# Asteptat:
# deployment.apps/frontend created
# service/frontend-service created

# Verifica deployment
kubectl get deployments -n voting-app

# Ar trebui:
# backend   2/2     2            2
# frontend  2/2     2            2

# Wait pentru pod ready
kubectl wait --for=condition=ready pod \
  -l app=frontend -n voting-app --timeout=300s

# Verifica pods
kubectl get pods -n voting-app

# Ar trebui: 4 pods total (2 backend, 2 frontend)
```

---

## STEP 11: Verifica Services

```bash
# Get services
kubectl get svc -n voting-app

# Asteptat:
# NAME              TYPE           CLUSTER-IP   EXTERNAL-IP   PORT
# backend-service   ClusterIP      10.x.x.x     <none>        8000/TCP
# frontend-service  LoadBalancer   10.x.x.x     <pending>     80:30xxx/TCP

# IMPORTANT: LoadBalancer externe IP poate lua 2-3 MINUTE
# Asteapta pana vede IP (nu <pending>)

kubectl get svc frontend-service -n voting-app -w
# -w = watch (asteapta schimbari)

# Cand apare IP externa - CTRL+C
# Ar trebui ceva: 35.192.xxx.xxx
```

---

## STEP 12: Testeaza Backend (Internal)

```bash
# Port-forward to backend
kubectl port-forward -n voting-app svc/backend-service 8000:8000 &

# Test health
curl http://localhost:8000/health

# Asteptat:
# {"status":"ok","mode":"kubernetes"}

# Test vote
curl -X POST http://localhost:8000/vote \
  -H "Content-Type: application/json" \
  -d '{"vote":"dogs"}'

# Asteptat:
# {"success":true,"message":"Vote recorded successfully"}

# Test results
curl http://localhost:8000/results

# Asteptat:
# {"dogs":1,"cats":0,"total":1}

# Stop port-forward
pkill -f "port-forward"
```

---

## STEP 13: Testeaza Frontend (External)

```bash
# Get frontend external IP
FRONTEND_IP=$(kubectl get svc frontend-service -n voting-app \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Frontend URL: http://$FRONTEND_IP"

# Deschide in browser: http://$FRONTEND_IP
# SAU foloseste curl:
curl http://$FRONTEND_IP

# Ar trebui sa vada HTML (voting app)
```

---

## STEP 14: Manual Testing (Browser)

1. Deschide: **http://(External IP)**

2. Ar trebui sa vezi:
   - [ ] Titlu "Vote: Dogs vs Cats"
   - [ ] Buton "Vote Dogs"
   - [ ] Buton "Vote Cats"
   - [ ] Sectiune "Live Results"

3. Click butoane:
   - [ ] Vote counts se actualizeaza
   - [ ] Graficele se schimba

4. Refresh pagina:
   - [ ] Data persista (din Cloud SQL)

---

## STEP 15: Verifica Logs

```bash
# Backend logs
kubectl logs -n voting-app -l app=backend --tail=50

# Ar trebui sa vada startup messages:
# [STARTUP] Deployment Mode: kubernetes
# [STARTUP] Database initialized successfully

# Frontend logs
kubectl logs -n voting-app -l app=frontend --tail=50

# Ar trebui: nginx logs

# Realtime logs
kubectl logs -n voting-app -l app=backend -f
# -f = follow (realtime)
# CTRL+C sa iesi
```

---

## STEP 16: Verifica Pod Details

```bash
# Describe pod
kubectl describe pod -n voting-app -l app=backend

# Ar trebui sa vada:
# - Status: Running
# - Ready: True
# - Restart Count: 0
# - Events: Normale (no errors)

# Check pod events
kubectl get events -n voting-app --sort-by='.lastTimestamp'

# Ar trebui sa vada crearea pod-urilor (no errors)
```

---

## STEP 17: Pod Scaling

```bash
# Scale backend la 3 replicas
kubectl scale deployment backend -n voting-app --replicas=3

# Verifica
kubectl get deployments -n voting-app

# Ar trebui:
# backend   3/3     3            3

# Verifica pods
kubectl get pods -n voting-app -l app=backend

# Ar trebui 3 backend pods

# Scale inapoi la 2
kubectl scale deployment backend -n voting-app --replicas=2
```

---

## STEP 18: Aplica Health Checks

```bash
# Aplica readiness/liveness probes
kubectl apply -f 06-healthcheck.yaml

# Verifica deployment
kubectl get deployment -n voting-app

# Verifica pod health
kubectl get pod -n voting-app -l app=backend -o wide

# Verifica events
kubectl get events -n voting-app

# Ar trebui sa vada probe checks (nu errors)
```

---

## STEP 19: Testing - Simuleaza Failure

```bash
# Kill un pod
POD_NAME=$(kubectl get pod -n voting-app -l app=backend -o jsonpath='{.items[0].metadata.name}')

kubectl delete pod $POD_NAME -n voting-app

# Verifica
kubectl get pods -n voting-app -l app=backend

# Ar trebui sa vada:
# - Vechi pod in Terminating
# - Nou pod in Running (recreated automat)

# Wait pentru noul pod ready
sleep 10

kubectl get pods -n voting-app -l app=backend

# Verifica health
curl http://localhost:8000/health
# (Port forward daca e necesar)
```

---

## STEP 20: Verificare Data Persistence

```bash
# Get current votes
FRONTEND_IP=$(kubectl get svc frontend-service -n voting-app \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Via backend port-forward:
kubectl port-forward -n voting-app svc/backend-service 8000:8000 &
curl http://localhost:8000/results
# Note numerele

# Delete backend pod
kubectl delete pod -l app=backend -n voting-app

# Wait new pod start
sleep 15

# Check data din noul pod
curl http://localhost:8000/results

# IMPORTANT: Ar trebui ACELEASI NUMERE!
# (Data pe Cloud SQL persista)

pkill -f "port-forward"
```

---

## STEP 21: Cleanup - Delete Application

```bash
# Sterge namespace (sterge totul din inside)
kubectl delete namespace voting-app

# Verifica
kubectl get namespaces

# Ar trebui: voting-app sa nu mai existe

# IMPORTANT: GKE cluster si Cloud SQL inca exista!
# (Trebuie sterse cu terraform destroy)
```

---

## STEP 22: Cleanup - Destroy Infrastructure

```bash
cd 3-KUBERNETES/terraform

# Destroy - STERGE INFRASTRUCTURA (GKE, Cloud SQL)
terraform destroy -auto-approve

# Asteptat:
# Destroy complete! Resources: 8 destroyed.

# Verifica
gcloud container clusters list
# Ar trebui gol (nu voting-cluster)

gcloud sql instances list
# Ar trebui gol (nu voting-db-instance)
```

---

## Troubleshooting MOD 3

### Problem: Terraform init failed

```bash
# Verifica Google auth
gcloud auth list

# Set project
gcloud config set project diesel-skyline-474415-j6

# Retry init
terraform init
```

### Problem: terraform plan hangs

```bash
# Verifica network
ping 8.8.8.8

# Verifica credentials
gcloud auth application-default login

# Retry plan
terraform plan
```

### Problem: Pod CrashLoopBackOff

```bash
# Check logs
kubectl logs <pod-name> -n voting-app

# Ar trebui sa vada error

# Solutii comune:
# 1. Database nu conecteaza
#    - Verify Cloud SQL instance running
#    - Verify credentials in secrets

# 2. Port conflict
#    - Check if port 8000 disponibil

# 3. Image pull failed
#    - Check image path
#    - Check registry credentials
```

### Problem: Pods RunningButNotReady

```bash
# Describe pod
kubectl describe pod <pod-name> -n voting-app

# Check readiness probe
kubectl get pod <pod-name> -n voting-app -o yaml

# Solutii:
# 1. Health check timeout prea mic
#    - Mareste initialDelaySeconds

# 2. Backend application nu porneste
#    - Check logs
```

### Problem: Frontend LoadBalancer pending

```bash
# Check service
kubectl describe svc frontend-service -n voting-app

# Events ar trebui sa arate daca e problem

# Daca ca vede IP-ul dupa 5 min - poate fi quota issue
# Verifica GCP quotas:
gcloud compute project-info describe --project=PROJECT_ID
```

### Problem: Cloud SQL connection failed

```bash
# Check instance
gcloud sql instances describe voting-db-instance

# Check connectivity:
gcloud sql connect voting-db-instance --user=root

# Verifica firewall rules
gcloud sql instances describe voting-db-instance | grep ipAddresses

# Add GKE IP sa Cloud SQL whitelist
gcloud sql instances patch voting-db-instance \
  --allowed-networks=0.0.0.0/0 \
  --backup-start-time=03:00
```

---

## Best Practices Kubernetes

```bash
✅ Mereu pune namespace
✅ Mereu pune resources requests/limits
✅ Mereu pune readiness/liveness probes
✅ Mereu pune health checks
✅ Mereu pune svc pe top de deployment
✅ Mereu cleanup cu kubectl delete
✅ Mereu check logs cand pod nu e ready
✅ Mereu teste scaling si failover
```

---

## Commands Summary

```bash
# Terraform
terraform init
terraform plan
terraform apply tfplan
terraform destroy

# Kubectl
kubectl get pods -n voting-app
kubectl get svc -n voting-app
kubectl logs -n voting-app -l app=backend
kubectl describe pod <pod-name> -n voting-app
kubectl scale deployment backend -n voting-app --replicas=3
kubectl port-forward svc/backend-service 8000:8000 -n voting-app
kubectl delete namespace voting-app
```

---

## Next Step

Cand MOD 3 este functional:
1. ✅ Verifica TESTING_GUIDE.md - MOD 3 section
2. ✅ Marcheaza MOD 3 ca PASS
3. ✅ Verifica Romanian documentation
4. ✅ Mergi la GitHub push!

---

**BRAVO! Kubernetes este scalabil! 🚀**
