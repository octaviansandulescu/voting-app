# 🆘 TROUBLESHOOTING - Probleme & Solutii

> **Ghid pentru probleme frecvente**

## 🔍 Cum sa Gasesti Problema

1. **Citeste error message-ul cu atentie**
2. **Verifica logs** (`console.log` pentru frontend, terminal pentru backend)
3. **Cauta eroarea in aceasta pagina**
4. **Daca nu gasesti, citeste alt mod** (LOCAL/DOCKER/KUBERNETES)

---

## ⚠️ ERORI GENERALE

### ❌ "Port already in use"

```
error: listen EADDRINUSE: address already in use :::8000
```

**Solutie:**

```bash
# Gaseste ce ruleaza pe port
lsof -i :8000           # macOS/Linux
netstat -ano | findstr :8000  # Windows

# Kill procesul (PID = process ID)
kill -9 <PID>           # macOS/Linux
taskkill /PID <PID> /F  # Windows

# SAU, foloseste alt port
python -m uvicorn main:app --port 8001
```

### ❌ "Connection refused"

```
error: connect ECONNREFUSED 127.0.0.1:8000
```

**Solutie:**

```bash
# Verifica ca backend ruleaza
curl http://localhost:8000/results

# Daca nu merge, start backend:
cd src/backend
python -m uvicorn main:app --reload
```

### ❌ "Module not found"

```
ModuleNotFoundError: No module named 'fastapi'
```

**Solutie:**

```bash
# Verifica ca venv e activat
which python    # Ar trebui sa arate venv path
# SAU (Windows):
where python    # Ar trebui sa arate venv path

# Daca nu, activeaza
source venv/bin/activate    # macOS/Linux
# SAU
venv\Scripts\activate       # Windows

# Reinstala dependencies
pip install -r src/backend/requirements.txt
```

---

## 🏠 ERORI MOD 1 (LOCAL)

### ❌ "Can't connect to MySQL"

```
ERROR 2002 (HY000): Can't connect to MySQL server on 'localhost' (61)
```

**Solutie:**

```bash
# Verifica ca MySQL ruleaza
sudo systemctl status mysql    # macOS/Linux

# Daca nu ruleaza
sudo systemctl start mysql     # macOS/Linux
# SAU macOS cu Homebrew:
brew services start mysql

# Verifica port 3306
mysql --version

# Incearca conectare
mysql -u root -p
```

### ❌ "Access denied for user"

```
ERROR 1045 (28000): Access denied for user 'voting_user_local'@'localhost'
```

**Solutie:**

```bash
# Verifica ca user-ul e creat
mysql -u root -p voting_app_local -e "SELECT USER();"

# Daca nu merge, recreate user
mysql -u root -p <<EOF
DROP USER IF EXISTS 'voting_user_local'@'localhost';
CREATE USER 'voting_user_local'@'localhost' IDENTIFIED BY 'secure_password_local';
GRANT ALL PRIVILEGES ON voting_app_local.* TO 'voting_user_local'@'localhost';
FLUSH PRIVILEGES;
EOF
```

### ❌ "Database doesn't exist"

```
ERROR 1049 (42000): Unknown database 'voting_app_local'
```

**Solutie:**

```bash
# Verifica databases
mysql -u root -p -e "SHOW DATABASES;"

# Daca lipseste, create it
mysql -u root -p <<EOF
CREATE DATABASE voting_app_local;
EOF
```

### ❌ "No results from /results endpoint"

```
Frontend: Empty results (0, 0)
```

**Solutie:**

```bash
# Verifica ca tabelele exista
mysql -u voting_user_local -p voting_app_local
mysql> SHOW TABLES;

# Daca tabelele nu exista, backend trebuie sa le creeze
# Verifica backend logs - ar trebui sa execute migrations
```

---

## 🐳 ERORI MOD 2 (DOCKER)

### ❌ "Cannot connect to Docker daemon"

```
error during connect: This error may indicate that the docker daemon is not running.
```

**Solutie:**

```bash
# Start Docker Desktop (GUI app)
# SAU (Linux):
sudo systemctl start docker

# Verifica
docker ps
```

### ❌ "docker-compose command not found"

```
command not found: docker-compose
```

**Solutie:**

```bash
# Install Docker Compose (daca nu ai instalat)
docker compose version  # Merci, e built-in

# SAU install separat (old way):
pip install docker-compose
```

### ❌ "Cannot build image"

```
ERROR: failed to solve with frontend dockerfile.v0: failed to read dockerfile: open Dockerfile.backend: no such file or directory
```

**Solutie:**

```bash
# Verifica ca Dockerfile-urile exista
ls -la 2-DOCKER/Dockerfile.*

# Verifica ca esti in directory-ul corect
cd 2-DOCKER
pwd  # Ar trebui sa arate .../2-DOCKER

# Build manual
docker build -f Dockerfile.backend -t voting-backend .
```

### ❌ "Port conflict in docker-compose"

```
Error response from daemon: Ports are not available
```

**Solutie:**

```bash
# Stop containers
docker-compose down

# Verifica ports
lsof -i :80     # Frontend
lsof -i :8000   # Backend
lsof -i :3306   # MySQL

# Kill procesul care o ocupa
kill -9 <PID>

# Start din nou
docker-compose up
```

### ❌ "Database connection failed in container"

```
Backend logs: "Can't connect to MySQL server on 'db'"
```

**Solutie:**

```bash
# Verifica ca MySQL container ruleaza
docker ps | grep mysql

# Verifica logs MySQL
docker logs <mysql_container_id>

# Check network
docker network ls

# Verifica conectare din container
docker exec <backend_container> mysql -h db -u voting_user -p voting_app -e "SELECT 1"
```

---

## ☸️ ERORI MOD 3 (KUBERNETES)

### ❌ "kubectl: command not found"

```
bash: kubectl: command not found
```

**Solutie:**

```bash
# Install kubectl
gcloud components install kubectl

# Verifica
kubectl version --client

# Seteaza cluster credentials
gcloud container clusters get-credentials voting-app-cluster --region us-central1
```

### ❌ "No cluster found"

```
ERROR: (gcloud.container.clusters.get-credentials) Cluster [voting-app-cluster] not found in [us-central1]
```

**Solutie:**

```bash
# Verifica clusters
gcloud container clusters list

# Daca nu exista, run deploy script
cd 3-KUBERNETES
./scripts/deploy.sh
```

### ❌ "terraform init fails"

```
Error: Failed to download module
```

**Solutie:**

```bash
cd 3-KUBERNETES/terraform

# Verifica terraform
terraform version

# Reinitialize
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### ❌ "Pods stuck in ImagePullBackOff"

```
kubectl get pods
# Status: ImagePullBackOff
```

**Solutie:**

```bash
# Verifica error
kubectl describe pod <pod_name> -n voting-app

# Problema: Image nu exista in registry
# Solutie: Push images
gcloud auth configure-docker us-central1-docker.pkg.dev
docker build -t voting-backend .
docker tag voting-backend us-central1-docker.pkg.dev/your-project/voting-app-docker/backend
docker push us-central1-docker.pkg.dev/your-project/voting-app-docker/backend

# Redeploy
kubectl rollout restart deployment/backend -n voting-app
```

### ❌ "LoadBalancer IP pending"

```
kubectl get svc -n voting-app
# EXTERNAL-IP: <pending>
```

**Solutie:**

```bash
# Asteapta 2-3 minute
kubectl get svc -n voting-app -w  # Watch mode

# Verifica service
kubectl describe svc frontend -n voting-app

# Verifica cluster capacity
kubectl describe nodes
```

### ❌ "Backend can't connect to Cloud SQL"

```
Backend logs: "Can't connect to database"
```

**Solutie:**

```bash
# Verifica Cloud SQL Proxy ruleaza
kubectl get pods -n voting-app | grep proxy

# Verifica environment variables
kubectl exec -it <backend_pod> -n voting-app -- env | grep DB

# Verifica network
kubectl exec -it <backend_pod> -n voting-app -- nslookup cloudsql-proxy

# Verifica Cloud SQL:
gcloud sql instances list
```

---

## 🐛 DEBUG TIPS

### Backend Debugging

```bash
# Run cu verbose logging
python -m uvicorn main:app --reload --log-level debug

# Acceseaza FastAPI docs
curl http://localhost:8000/docs

# Test endpoint
curl -X POST http://localhost:8000/vote -H "Content-Type: application/json" -d '{"vote":"dogs"}'
```

### Frontend Debugging

```bash
# Browser DevTools (F12)
# Console tab - JavaScript errors
# Network tab - API calls
# Application tab - Local storage
```

### Database Debugging

```bash
# Connect
mysql -u voting_user_local -p voting_app_local

# Check tables
SHOW TABLES;
DESC votes;

# Query data
SELECT * FROM votes;
SELECT vote, COUNT(*) FROM votes GROUP BY vote;

# Check indexes
SHOW INDEXES FROM votes;
```

### Docker Debugging

```bash
# Logs
docker-compose logs backend
docker-compose logs -f  # Follow mode

# Exec into container
docker exec -it <container_name> /bin/sh

# Inspect image
docker inspect <image_name>
```

### Kubernetes Debugging

```bash
# Logs
kubectl logs -f deployment/backend -n voting-app
kubectl logs deployment/frontend -n voting-app

# Describe resources
kubectl describe pod <pod_name> -n voting-app
kubectl describe svc frontend -n voting-app

# Exec into pod
kubectl exec -it <pod_name> -n voting-app -- /bin/sh

# Events
kubectl get events -n voting-app
```

---

## 📋 Checklist - Inainte de Contact

Daca ai o problema, verifica:

- [ ] Citit mesajul de error complet
- [ ] Verificat logs (terminal, console, kubectl logs)
- [ ] Searched in TROUBLESHOOTING.md
- [ ] Verificat ca serviciile ruleaza (MySQL, Docker, GKE)
- [ ] Verificat ports (lsof -i :<port>)
- [ ] Verificat conectivitate (curl, mysql CLI)
- [ ] Verificat configurare (.env, terraform.tfvars)
- [ ] Verificat permissions (sudo, roles, API access)

---

## 🆘 Probleme Spice?

Daca problema nu e in lista asta:

1. **Check logs cu detail**
   ```bash
   docker-compose logs -f backend 2>&1 | tail -50
   kubectl logs deployment/backend -n voting-app --previous
   ```

2. **Search error online** - Copiaza mesajul exact
3. **Verifica Git issues** - Altii au avut aceeasi problema?
4. **Restart everything**
   ```bash
   # LOCAL
   pkill -f "python -m"
   pkill -f "http.server"
   
   # DOCKER
   docker-compose down -v && docker-compose up
   
   # KUBERNETES
   kubectl delete namespace voting-app
   ./scripts/deploy.sh
   ```

---

## 💡 Gen Bune Practici

1. **Citeste error messages** - Contin indicii valoroase
2. **Check logs first** - Problema e acolo
3. **Verifica conexiuni** - DB, API, network
4. **Test components separate** - Backend, frontend, database
5. **Incrementally build** - Start local, then docker, then k8s

---

**Ai gasit solutia? Grozav! 🎉**

Daca vrei sa inveti mai mult, merge la:
- **[CONCEPTS.md](CONCEPTS.md)** - Ce e DevOPS
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Cum e construit
- **[01-LOCAL](01-LOCAL/README.md)** - Setup local
