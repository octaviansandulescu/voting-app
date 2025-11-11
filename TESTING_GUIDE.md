# TESTING GUIDE - Verificare Functionala Completa

> **Timp estimat: 2-3 ore**
>
> Inainte de a urca pe GitHub, trebuie sa testam TOATE modurile!

## 🎯 Obiective Testing

- [ ] MOD 1: LOCAL - Rulare fara Docker
- [ ] MOD 2: DOCKER - Rulare cu Docker Compose
- [ ] MOD 3: KUBERNETES - Deploy pe GCP
- [ ] Documentatie completa si clara
- [ ] Securitate - Nici o data sensibila pe GitHub

---

## 📚 Documentatie Detaliata

**IMPORTANT:** Fiecare MOD are tutorial complet:

- **MOD 1 Tutorial:** [docs/01-LOCAL/README.md](docs/01-LOCAL/README.md) - Cum sa rulezi local
- **MOD 2 Tutorial:** [docs/02-DOCKER/README.md](docs/02-DOCKER/README.md) - Cum sa rulezi cu Docker
- **MOD 3 Tutorial:** [docs/03-KUBERNETES/README.md](docs/03-KUBERNETES/README.md) - Cum sa deployezi pe GCP

Acest fisier contine CHECKLIST-urile de testare.
Tutorialele contin explicatii detaliate si comenzi step-by-step.

---

---

## 📋 CHECKLIST MOD 1: LOCAL

### STEP 1: Pregatire

```bash
# Clone/navigate to project
cd /home/octavian/sandbox/voting-app

# Verifica Python
python3 --version  # Trebuie 3.11+

# Verifica MySQL
mysql --version

# Verifica structura
ls -la 1-LOCAL/
ls -la src/backend/
ls -la src/frontend/
```

**Status:** [ ] PASS / [ ] FAIL

---

### STEP 2: Setup MySQL

```bash
# Conectare
mysql -u root -p

# In MySQL prompt:
CREATE DATABASE voting_app_local;
CREATE USER 'voting_user_local'@'localhost' IDENTIFIED BY 'secure_password_local';
GRANT ALL PRIVILEGES ON voting_app_local.* TO 'voting_user_local'@'localhost';
FLUSH PRIVILEGES;
EXIT;

# Verifica
mysql -u voting_user_local -p voting_app_local -e "SELECT 1;"
```

**Status:** [ ] PASS / [ ] FAIL
**Error:** ________________________

---

### STEP 3: Setup Python Environment

```bash
cd /home/octavian/sandbox/voting-app

# Creaza venv
python3 -m venv venv

# Activeaza
source venv/bin/activate

# Verifica
which python
```

**Status:** [ ] PASS / [ ] FAIL
**Path:** ________________________

---

### STEP 4: Instala Dependencies

```bash
cd src/backend

# Install
pip install -r requirements.txt

# Verifica
pip list | grep -i fastapi
pip list | grep -i mysql
```

**Status:** [ ] PASS / [ ] FAIL
**Missing packages:** ________________________

---

### STEP 5: Configureaza Environment

```bash
# Copy template
cp 1-LOCAL/.env.local.example 1-LOCAL/.env.local

# Editeaza
nano 1-LOCAL/.env.local
# Schimba:
# DB_PASSWORD=secure_password_local
# DEPLOYMENT_MODE=local

# Verifica
cat 1-LOCAL/.env.local
```

**Status:** [ ] PASS / [ ] FAIL
**Config:** ________________________

---

### STEP 6: Ruleaza Backend

```bash
# Terminal 1
cd src/backend
export DEPLOYMENT_MODE=local
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

**Output asteptat:**
```
INFO:     Uvicorn running on http://127.0.0.1:8000
INFO:     Application startup complete
```

**Status:** [ ] PASS / [ ] FAIL
**URL:** http://localhost:8000
**Eroare:** ________________________

---

### STEP 7: Ruleaza Frontend

```bash
# Terminal 2
cd src/frontend
python -m http.server 3000
```

**Output asteptat:**
```
Serving HTTP on 0.0.0.0 port 3000
```

**Status:** [ ] PASS / [ ] FAIL
**URL:** http://localhost:3000
**Eroare:** ________________________

---

### STEP 8: Testeaza API Endpoints

```bash
# Terminal 3

# Test health check
curl http://localhost:8000/health
# Asteptat: {"status":"ok","mode":"local"}

# Test vote
curl -X POST http://localhost:8000/vote \
  -H "Content-Type: application/json" \
  -d '{"vote":"dogs"}'
# Asteptat: {"success":true,"message":"Vote recorded successfully"}

# Test results
curl http://localhost:8000/results
# Asteptat: {"dogs":1,"cats":0,"total":1}

# Vote catusi
curl -X POST http://localhost:8000/vote \
  -H "Content-Type: application/json" \
  -d '{"vote":"cats"}'

# Check results again
curl http://localhost:8000/results
# Asteptat: {"dogs":1,"cats":1,"total":2}
```

**Status:** [ ] PASS / [ ] FAIL

| Endpoint | Response | Status |
|----------|----------|--------|
| /health | OK | [ ] |
| /vote (dogs) | success | [ ] |
| /results | 1,1,2 | [ ] |
| /vote (cats) | success | [ ] |

---

### STEP 9: Testeaza Frontend UI

1. Deschide browser: http://localhost:3000
2. Ar trebui sa vezi:
   - [ ] Titlu "Vote: Dogs vs Cats"
   - [ ] Buton "Vote Dogs"
   - [ ] Buton "Vote Cats"
   - [ ] Sectiune "Live Results"
   - [ ] Grafice cu rezultate

3. Click "Vote Dogs"
   - [ ] Numarul creste
   - [ ] Graficul se actualizeaza
   - [ ] Mesaj de succes

4. Click "Vote Cats"
   - [ ] Numarul creste
   - [ ] Graficul se actualizeaza
   - [ ] Mesaj de succes

5. Refresh pagina (F5)
   - [ ] Numerele persisteaza (din baza de date)
   - [ ] Rezultatele se actualizeaza automat

**Status:** [ ] PASS / [ ] FAIL
**Erori:** ________________________

---

### STEP 10: Verificare Logs si Errors

```bash
# Check backend logs (Terminal 1)
# Ar trebui sa vada:
# [VOTE] Recording vote: dogs
# [RESULTS] Fetching vote results

# Check browser console (F12)
# Nu ar trebui sa fie erori rosii

# Check MySQL
mysql -u voting_user_local -p voting_app_local
mysql> SELECT * FROM votes;
# Ar trebui sa vada voturile
```

**Status:** [ ] PASS / [ ] FAIL
**Database votes:** ________________________

---

### MOD 1 FINAL TEST

```bash
# TOTAL TEST
# ✅ = Trebuie PASS

✅ MySQL conectat
✅ Python venv creat
✅ Dependencies instalate
✅ Backend ruleaza pe 8000
✅ Frontend ruleaza pe 3000
✅ /health endpoint OK
✅ /vote endpoint OK
✅ /results endpoint OK
✅ UI se afiseaza corect
✅ Voturile se inregistreaza
✅ Graficele se actualizeaza
✅ Datele persisteaza dupa reload
✅ Logs sunt curate (fara erori)
```

**REZULTAT MOD 1:** [ ] PASS / [ ] FAIL

---

## 🐳 CHECKLIST MOD 2: DOCKER

### STEP 1: Pregatire

```bash
# Verifica Docker
docker --version
docker-compose --version

# Verifica ca MOD 1 e oprit
pkill -f "uvicorn"
pkill -f "http.server"
```

**Status:** [ ] PASS / [ ] FAIL

---

### STEP 2: Copy .env Template

```bash
cd 2-DOCKER

# Copy template
cp .env.docker.example .env.docker

# Editeaza
nano .env.docker
# Verifica:
# DB_HOST=db
# DB_USER=voting_docker_user
# DB_PASSWORD=docker_password
# DEPLOYMENT_MODE=docker

cat .env.docker
```

**Status:** [ ] PASS / [ ] FAIL

---

### STEP 3: Verifica docker-compose.yml

```bash
cd 2-DOCKER

# Verifica fisierul
cat docker-compose.yml

# Ar trebui sa contina:
# - Nginx service (port 80)
# - Backend service (port 8000)
# - MySQL service (port 3306)
# - Volumes pentru persistenta
```

**Status:** [ ] PASS / [ ] FAIL

---

### STEP 4: Build Images

```bash
cd 2-DOCKER

# Build
docker-compose build

# Asteptat: Successfully tagged...
```

**Status:** [ ] PASS / [ ] FAIL
**Eroare:** ________________________

---

### STEP 5: Start Services

```bash
cd 2-DOCKER

# Start (detach mode)
docker-compose up -d

# Asteptat: Creating network... Creating ... Starting ...
```

**Status:** [ ] PASS / [ ] FAIL

---

### STEP 6: Verifica Services

```bash
# Check status
docker-compose ps

# Ar trebui sa vada:
# voting-frontend  nginx        Up
# voting-backend   python       Up
# voting-db        mysql        Up

# Check logs
docker-compose logs -f backend
# Asteptat: [STARTUP] Database initialized successfully

# Wait 10-15 seconds pentru MySQL sa se porneasca
sleep 15

# Check health
curl http://localhost:8000/health
# Asteptat: {"status":"ok"}
```

**Status:** [ ] PASS / [ ] FAIL
**Services running:** ________________________

---

### STEP 7: Testeaza API

```bash
# Vote
curl -X POST http://localhost:8000/vote \
  -H "Content-Type: application/json" \
  -d '{"vote":"dogs"}'

# Results
curl http://localhost:8000/results

# Verify in MySQL
docker-compose exec db mysql -u voting_docker_user -ppassword voting_app_docker -e "SELECT * FROM votes;"
```

**Status:** [ ] PASS / [ ] FAIL

---

### STEP 8: Testeaza Frontend

1. Deschide: http://localhost (port 80, nu 3000!)
2. Verifica:
   - [ ] UI se incarca
   - [ ] Poti vota
   - [ ] Rezultatele se actualizeaza
   - [ ] Graficele functioneaza

**Status:** [ ] PASS / [ ] FAIL

---

### STEP 9: Testeaza Persistenta Datelor

```bash
# Stop containers
docker-compose down

# Verifica volumurile
docker volume ls | grep voting

# Start din nou
docker-compose up -d
sleep 10

# Check data
curl http://localhost:8000/results
# Ar trebui sa vada voturile din inainte
```

**Status:** [ ] PASS / [ ] FAIL
**Data persisted:** [ ] YES / [ ] NO

---

### STEP 10: Cleanup

```bash
# Stop si cleanup
docker-compose down -v

# Verifica
docker-compose ps
# Ar trebui sa fie gol
```

**Status:** [ ] PASS / [ ] FAIL

---

### MOD 2 FINAL TEST

```
✅ Docker Desktop ruleaza
✅ docker-compose build - OK
✅ docker-compose up - OK
✅ Nginx pe port 80
✅ Backend pe port 8000
✅ MySQL pe port 3306
✅ /health endpoint OK
✅ /vote endpoint OK
✅ Frontend UI OK
✅ Voturile se inregistreaza
✅ Date persisteaza
✅ Cleanup reusit
```

**REZULTAT MOD 2:** [ ] PASS / [ ] FAIL

---

## ☸️ CHECKLIST MOD 3: KUBERNETES + GCP

### STEP 1: Pregatire GCP

```bash
# Verifica GCP CLI
gcloud --version

# Login
gcloud auth login

# Set project
gcloud config set project diesel-skyline-474415-j6

# Verifica
gcloud config list
```

**Status:** [ ] PASS / [ ] FAIL

---

### STEP 2: Verifica Terraform Configs

```bash
cd 3-KUBERNETES/terraform

# List fisiere
ls -la

# Ar trebui:
# - main.tf (GKE + Cloud SQL)
# - variables.tf
# - outputs.tf
# - terraform.tfvars.example
```

**Status:** [ ] PASS / [ ] FAIL

---

### STEP 3: Configureaza Terraform

```bash
cd 3-KUBERNETES/terraform

# Copy template
cp terraform.tfvars.example terraform.tfvars

# Editeaza
nano terraform.tfvars
# Verifica valori GCP

cat terraform.tfvars
```

**Status:** [ ] PASS / [ ] FAIL

---

### STEP 4: Terraform Init

```bash
cd 3-KUBERNETES/terraform

# Initialize
terraform init

# Asteptat: Terraform has been successfully configured!
```

**Status:** [ ] PASS / [ ] FAIL
**Eroare:** ________________________

---

### STEP 5: Terraform Plan

```bash
cd 3-KUBERNETES/terraform

# Plan
terraform plan -out=tfplan

# Verifica output - ar trebui sa arate ce se va crea:
# - GKE Cluster
# - Cloud SQL Instance
# - VPC Resources
# - etc

# Review plan
less tfplan
```

**Status:** [ ] PASS / [ ] FAIL
**Resources to create:** ________________________

---

### STEP 6: Terraform Apply

```bash
cd 3-KUBERNETES/terraform

# Apply
terraform apply tfplan

# Asteptat (10-15 minute):
# - GKE cluster creation
# - Cloud SQL instance creation
# - Network setup

# Follow progress
gcloud container clusters list --project diesel-skyline-474415-j6
gcloud sql instances list --project diesel-skyline-474415-j6
```

**Status:** [ ] PASS / [ ] FAIL
**Creation time:** ________________________ min
**Eroare:** ________________________

---

### STEP 7: Get Kubectl Credentials

```bash
# Get credentials
gcloud container clusters get-credentials voting-app-cluster \
  --region us-central1 \
  --project diesel-skyline-474415-j6

# Verifica
kubectl cluster-info
kubectl get nodes
```

**Status:** [ ] PASS / [ ] FAIL

---

### STEP 8: Create Kubernetes Secrets

```bash
cd 3-KUBERNETES/k8s

# Create namespace
kubectl create namespace voting-app

# Create secrets
kubectl create secret generic db-secret \
  --from-literal=username=voting_user_k8s \
  --from-literal=password=secure_password_k8s \
  -n voting-app

# Verifica
kubectl get secrets -n voting-app
```

**Status:** [ ] PASS / [ ] FAIL

---

### STEP 9: Deploy Kubernetes Manifests

```bash
cd 3-KUBERNETES/k8s

# Apply manifests
kubectl apply -f 01-namespace.yaml
kubectl apply -f 02-secrets.yaml
kubectl apply -f 03-backend-deployment.yaml
kubectl apply -f 04-frontend-deployment.yaml
kubectl apply -f 05-services.yaml

# Verifica
kubectl get all -n voting-app

# Asteptat:
# - 2 backend pods
# - 2 frontend pods
# - Services
```

**Status:** [ ] PASS / [ ] FAIL

---

### STEP 10: Verifica Deployments

```bash
# Check pods
kubectl get pods -n voting-app

# Ar trebui sa fie RUNNING (nu ImagePullBackOff)
# Asteptat 2-3 minute pentru start

# Watch mode
kubectl get pods -n voting-app -w

# Check logs
kubectl logs -f deployment/backend -n voting-app

# Ar trebui:
# [STARTUP] Database initialized successfully
```

**Status:** [ ] PASS / [ ] FAIL
**Pod status:** ________________________

---

### STEP 11: Get LoadBalancer IP

```bash
# Get external IP
kubectl get svc -n voting-app

# Ar trebui sa vada:
# - frontend service cu EXTERNAL-IP (asteapta 2-3 minute)
# - backend service ClusterIP (internal)

# Copy IP
FRONTEND_IP=$(kubectl get svc frontend -n voting-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Frontend URL: http://$FRONTEND_IP"

# Test
curl http://$FRONTEND_IP/health
```

**Status:** [ ] PASS / [ ] FAIL
**Frontend URL:** http://____________________

---

### STEP 12: Test UI

1. Deschide: http://<EXTERNAL-IP>
2. Verifica:
   - [ ] UI se incarca
   - [ ] Poti vota
   - [ ] Rezultatele se actualizeaza

**Status:** [ ] PASS / [ ] FAIL

---

### STEP 13: Cleanup (Optional)

```bash
# Daca nu vrei sa lasi resurse pe GCP

# Delete K8s resources
kubectl delete namespace voting-app

# Destroy infrastructure (10-15 minute)
cd 3-KUBERNETES/terraform
terraform destroy

# Verifica
gcloud container clusters list --project diesel-skyline-474415-j6
gcloud sql instances list --project diesel-skyline-474415-j6
# Ar trebui goale
```

**Status:** [ ] PASS / [ ] FAIL

---

### MOD 3 FINAL TEST

```
✅ GCP project configured
✅ Terraform init - OK
✅ Terraform plan - OK
✅ Terraform apply - OK (resources created)
✅ GKE cluster running
✅ Cloud SQL instance running
✅ kubectl connected
✅ Kubernetes secrets created
✅ Manifests deployed
✅ Pods running (RUNNING status)
✅ Services configured
✅ LoadBalancer IP assigned
✅ Frontend accessible via IP
✅ Voturile se inregistreaza pe K8s
```

**REZULTAT MOD 3:** [ ] PASS / [ ] FAIL

---

## 📝 DOCUMENTATIE VERIFICARI

### Checklist Documentation

```bash
# Verifica ca toate fisierele exista

✅ README.md - Overview principal
✅ docs/CONCEPTS.md - DevOPS concepts
✅ docs/ARCHITECTURE.md - Arhitectura detaliata
✅ docs/TROUBLESHOOTING.md - Debugging guide
✅ docs/01-LOCAL/README.md - MOD 1 tutorial
✅ docs/02-DOCKER/README.md - MOD 2 tutorial (TO CREATE)
✅ docs/03-KUBERNETES/README.md - MOD 3 tutorial (TO CREATE)
✅ 1-LOCAL/.env.local.example - Template
✅ 2-DOCKER/.env.docker.example - Template
✅ 2-DOCKER/docker-compose.yml - (TO CREATE)
✅ 2-DOCKER/Dockerfile.backend - (TO CREATE)
✅ 2-DOCKER/Dockerfile.frontend - (TO CREATE)
✅ 3-KUBERNETES/terraform/*.tf - (TO CREATE)
✅ 3-KUBERNETES/k8s/*.yaml - (TO CREATE)

# Verifica limba - fara diacritice

grep -r "ă\|ț\|ș\|ž\|ă\|é" docs/ README.md
# Ar trebui sa nu gaseasca nimic (clean output)
```

**Status:** [ ] PASS / [ ] FAIL

---

## 🔒 SECURITATE VERIFICARI

### Secrets Check

```bash
# Verifica ca nici o parola nu e pe GitHub

grep -r "password\|secret\|key" . \
  --exclude-dir=.git \
  --exclude-dir=.github \
  --exclude-dir=venv \
  --exclude-dir=__pycache__ \
  --exclude='*.pyc'

# Ar trebui sa nu gaseasca valori reale, doar template references
```

**Status:** [ ] PASS / [ ] FAIL

---

### .gitignore Check

```bash
# Verifica .gitignore

cat .gitignore

# Ar trebui sa contina:
# .env
# .env.*
# *.tfvars
# terraform/.terraform/
# venv/
# __pycache__/
```

**Status:** [ ] PASS / [ ] FAIL

---

## ✅ FINAL CHECKLIST - INAINTE DE GITHUB PUSH

### MOD 1: LOCAL
- [ ] MySQL conectat si functional
- [ ] Backend pe 8000, rulez fara erori
- [ ] Frontend pe 3000, UI OK
- [ ] Voturile se inregistreaza si persista
- [ ] Logs curate (fara erori rosii)

### MOD 2: DOCKER
- [ ] docker-compose build - OK
- [ ] docker-compose up - OK (toate 3 servicii pe UP)
- [ ] Frontend pe port 80 (http://localhost)
- [ ] Voturile se inregistreaza si persista
- [ ] docker-compose down - cleanup OK

### MOD 3: KUBERNETES
- [ ] Terraform plan - OK (resources show)
- [ ] Terraform apply - OK (10-15 min)
- [ ] GKE cluster creat si running
- [ ] Cloud SQL creat si accessible
- [ ] kubectl pods - RUNNING (nu ImagePullBackOff)
- [ ] LoadBalancer IP assigned
- [ ] Frontend accessible via EXTERNAL-IP
- [ ] Voturile se inregistreaza pe K8s

### DOCUMENTATIE
- [ ] README.md complet
- [ ] Toate .md fisiere in romana fara diacritice
- [ ] CONCEPTS.md se intelege
- [ ] TROUBLESHOOTING.md cuprinde probleme comune
- [ ] Tutorial files (.env.example) complete

### SECURITATE
- [ ] .gitignore OK (nici un .env pe git)
- [ ] Nici o parola in code
- [ ] NU e .env.local, .env.docker, terraform.tfvars in repo
- [ ] DOAR .env*.example in repo

---

## 🚀 COMMAND SUMMARY

### MOD 1
```bash
# Terminal 1
cd src/backend
export DEPLOYMENT_MODE=local
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Terminal 2
cd src/frontend
python -m http.server 3000

# Test: http://localhost:3000
```

### MOD 2
```bash
cd 2-DOCKER
docker-compose up -d
# Test: http://localhost
```

### MOD 3
```bash
cd 3-KUBERNETES/terraform
terraform apply tfplan

cd ../k8s
kubectl apply -f *.yaml

# Get URL
kubectl get svc frontend -n voting-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

---

## 📞 DACA CEVA NU MERGE

1. Citeste TROUBLESHOOTING.md
2. Verifica logs
3. Verifica conectivitate (curl, mysql, kubectl)
4. Verifica environment variables (.env files)
5. Citeste error message-ul inca o data

---

**SUCCES! Cand toate 3 moduri sunt PASS, poti urca pe GitHub! 🚀**
