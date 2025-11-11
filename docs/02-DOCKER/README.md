# MOD 2: DOCKER - Tutorial Complet

> **Timp estimat: 30 minute**
>
> In acest mod invatii cum sa containerizezi aplicatia cu Docker.

## Ce Invatii

- ✅ Docker concepts
- ✅ Containerizare
- ✅ docker-compose
- ✅ Multi-container orchestration
- ✅ Networking in Docker
- ✅ Volumuri persistent

---

## Prerequisites

```bash
# Verifica Docker
docker --version
# Output: Docker version 24.x.x

# Verifica docker-compose
docker-compose --version
# Output: Docker Compose version 2.x.x

# Verifica ca MOD 1 e oprit
pkill -f uvicorn
pkill -f "http.server"
```

---

## Structura DOCKER

```
2-DOCKER/
├── README.md                # Acest fisier
├── .env.docker.example     # Template configuration
├── docker-compose.yml      # Orchestration
├── Dockerfile.backend      # Backend container
├── Dockerfile.frontend     # Frontend container
└── .dockerignore          # Exclude files
```

---

## STEP 1: Intelege docker-compose.yml

```yaml
# 3 servicii:
services:
  frontend:
    image: nginx:alpine
    ports:
      - "80:80"  # External:Internal
    volumes:
      - ./src/frontend:/usr/share/nginx/html

  backend:
    build:
      context: .
      dockerfile: Dockerfile.backend
    ports:
      - "8000:8000"
    environment:
      - DB_HOST=db
      - DB_USER=voting_docker_user
    depends_on:
      - db

  db:
    image: mysql:8.0
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - MYSQL_DATABASE=voting_app_docker
    volumes:
      - mysql_data:/var/lib/mysql

volumes:
  mysql_data:
```

**Key concepts:**
- `services` - Containerele care ruleaza
- `ports` - Mapping external:internal
- `environment` - Variabile de mediu
- `volumes` - Persistent storage
- `depends_on` - Ordinea de start

---

## STEP 2: Copy Configuratia

```bash
cd 2-DOCKER

# Copy template
cp .env.docker.example .env.docker

# Editeaza
nano .env.docker

# Verifica content
cat .env.docker
```

**Ar trebui sa contina:**
```
DB_HOST=db
DB_PORT=3306
DB_USER=voting_docker_user
DB_PASSWORD=docker_secure_password
DB_NAME=voting_app_docker
DEPLOYMENT_MODE=docker
```

---

## STEP 3: Build Docker Images

```bash
cd 2-DOCKER

# Build - Creaza imagini Docker
docker-compose build

# Output asteptat:
# Building backend
# Step 1/5 : FROM python:3.11-slim
# ...
# Successfully tagged 2-docker_backend:latest

# Building frontend
# Step 1/2 : FROM nginx:alpine
# ...
# Successfully tagged 2-docker_frontend:latest
```

**Timp:** 2-5 minute (prima data - mai lent)

**Daca eroare:**
```bash
# Verifica Docker daemon
docker ps

# Verifica fisierele
ls -la Dockerfile.*

# Verifica yaml
docker-compose config
```

---

## STEP 4: Start Services

```bash
cd 2-DOCKER

# Start - Creaza si porneste containerele
docker-compose up -d
# -d = detach (background)

# Asteptat:
# Creating network "2-docker_default" with the default driver
# Creating 2-docker_db_1
# Creating 2-docker_backend_1
# Creating 2-docker_frontend_1

# Wait 10 seconds pentru MySQL startup
sleep 10

# Verifica status
docker-compose ps

# Asteptat - toti sa fie UP:
# NAME              SERVICE    STATUS
# 2-docker_db       db         Up 10s
# 2-docker_backend  backend    Up 5s
# 2-docker_frontend frontend   Up 3s
```

---

## STEP 5: Verifica Logs

```bash
# Backend logs
docker-compose logs backend

# Ar trebui:
# [STARTUP] Deployment Mode: docker
# [STARTUP] Database initialized successfully

# Frontend logs
docker-compose logs frontend

# Ar trebui:
# ... nginx logs

# MySQL logs
docker-compose logs db

# Ar trebui:
# MySQL Server is ready for new connections
```

---

## STEP 6: Testeaza API - Health Check

```bash
# Health check
curl http://localhost:8000/health

# Asteptat:
# {"status":"ok","mode":"docker"}
```

---

## STEP 7: Testeaza API - Vote

```bash
# Vote pentru caini
curl -X POST http://localhost:8000/vote \
  -H "Content-Type: application/json" \
  -d '{"vote":"dogs"}'

# Asteptat:
# {"success":true,"message":"Vote recorded successfully"}

# Vote pentru pisici
curl -X POST http://localhost:8000/vote \
  -H "Content-Type: application/json" \
  -d '{"vote":"cats"}'

# Check results
curl http://localhost:8000/results

# Asteptat:
# {"dogs":1,"cats":1,"total":2}
```

---

## STEP 8: Testeaza API - Results

```bash
# Get results
curl http://localhost:8000/results

# Asteptat:
# {
#   "dogs": 1,
#   "cats": 1,
#   "total": 2
# }
```

---

## STEP 9: Testeaza Frontend UI

1. Deschide browser: **http://localhost**
   - Nota: Port 80, NU 3000!

2. Ar trebui sa vezi:
   - [ ] Titlu "Vote: Dogs vs Cats"
   - [ ] Buton "Vote Dogs" (roz)
   - [ ] Buton "Vote Cats" (albastru)
   - [ ] Sectiune "Live Results"
   - [ ] Grafice cu bare (progress bars)

3. Click "Vote Dogs":
   - [ ] Numarul creste (ar trebui 2)
   - [ ] Bara de progres se actualizeaza
   - [ ] "Dogs: 2, Cats: 1, Total: 3"

4. Refresh pagina (F5):
   - [ ] Numerele raman (persista din DB)
   - [ ] Graficele se actualizeaza automat

5. Open DevTools (F12 → Console):
   - [ ] Nu ar trebui sa fie erori rosii
   - [ ] Ar trebui sa vada: "API endpoint detected"

---

## STEP 10: Verifica Docker Network

```bash
# Listeaza networks
docker network ls

# Ar trebui sa gaseasca:
# 2-docker_default   bridge

# Inspect network
docker network inspect 2-docker_default

# Ar trebui sa vada:
# - 3 containers conectate
# - Backend poate reach MySQL via hostname "db"
```

---

## STEP 11: Verifica Volumuri

```bash
# Listeaza volumuri
docker volume ls

# Ar trebui sa vada:
# 2-docker_mysql_data

# Inspect volum
docker volume inspect 2-docker_mysql_data

# Ar trebui sa vada mount point
```

---

## STEP 12: Testeaza Persistenta Datelor

```bash
# Check current votes
curl http://localhost:8000/results
# Asteptat: {"dogs":2,"cats":1,"total":3}

# Stop containers (dar nu delete)
docker-compose down

# Verifica volumuri - inca exista
docker volume ls

# Start din nou
docker-compose up -d
sleep 10

# Check data
curl http://localhost:8000/results

# IMPORTANT: Ar trebui sa vada ACELEASI numere!
# {"dogs":2,"cats":1,"total":3}

# Daca numerele sunt resetate = PROBLEM (volumul nu a salvat)
```

---

## STEP 13: Accesare Container Interior

```bash
# Exec in backend container
docker-compose exec backend /bin/sh

# In container:
# Poti rula comenzi

# Check environment
env | grep DB

# Ar trebui:
# DB_HOST=db
# DB_USER=voting_docker_user

# Check logs
ls -la /var/log/

# Exit container
exit
```

---

## STEP 14: Verify MySQL Inside Container

```bash
# Exec in MySQL container
docker-compose exec db mysql -u voting_docker_user -ppassword voting_app_docker

# In MySQL prompt:
mysql> SELECT COUNT(*) FROM votes;
# Ar trebui sa arate numarul total (3)

mysql> SELECT * FROM votes;
# Ar trebui sa vada voturile

mysql> EXIT;
```

---

## STEP 15: Cleanup - Stop All

```bash
# Stop servicii (dar pastreaza volumuri)
docker-compose stop

# Verifica
docker-compose ps

# Ar trebui sa fie gol (no containers running)

# Start din nou
docker-compose start

# Verifica
docker-compose ps
```

---

## STEP 16: Cleanup - Remove All (Optional)

```bash
# ATENTIE: Asta sterge containerele SI volumurile!

# Stop si sterge
docker-compose down -v

# Verifica
docker-compose ps
# Ar trebui sa fie gol

docker volume ls
# Ar trebui sa nu gaseasca 2-docker_mysql_data

docker image ls
# Ar trebui sa nu gaseasca 2-docker_*
```

---

## Troubleshooting MOD 2

### Problem: Port 80 already in use

```bash
# Gaseste ce ocupa portul
lsof -i :80

# Kill processo
kill -9 <PID>

# SAU, schimba portul in docker-compose.yml
# Schimba: ports: - "80:80"
# Cu:      ports: - "8080:80"

# Apoi test: http://localhost:8080
```

### Problem: Backend nu conecteaza la MySQL

```bash
# Check logs
docker-compose logs backend

# Ar trebui sa vada:
# ERROR: Connection failed - Can't connect to MySQL server

# Solutii:
# 1. MySQL inca se porneste - asteapta 10 sec
sleep 15
docker-compose logs backend

# 2. Verifica environment
docker-compose exec backend env | grep DB

# 3. Verifica hostname
docker-compose exec backend ping db

# Ar trebui sa raspunda (DB hostname OK)
```

### Problem: Frontend nu se incarca

```bash
# Check Nginx logs
docker-compose logs frontend

# Test port
curl http://localhost

# Daca connection refused:
docker-compose restart frontend
sleep 5
curl http://localhost
```

### Problem: Volumuri nu salveaza

```bash
# Check volum
docker volume inspect 2-docker_mysql_data

# Verifica Mountpoint
# Ar trebui ceva de genul:
# "/var/lib/docker/volumes/2-docker_mysql_data/_data"

# Daca problema persista:
# 1. Stop everything
docker-compose down -v

# 2. Start fresh
docker-compose up -d
```

---

## Best Practices Docker

```bash
✅ Mereu pune .dockerignore
✅ Mereu pune healthchecks
✅ Mereu pune volumes pentru DB
✅ Mereu pune depends_on
✅ Mereu test persistent data
✅ Mereu cleanup cu -v
✅ Mereu check logs
```

---

## Commands Summary

```bash
# Build
docker-compose build

# Start background
docker-compose up -d

# Start foreground (cu logs)
docker-compose up

# Stop
docker-compose stop

# Stop + Remove
docker-compose down

# Stop + Remove + Delete volumes
docker-compose down -v

# Logs
docker-compose logs -f backend

# Exec
docker-compose exec backend /bin/sh

# Status
docker-compose ps
```

---

## Next Step

Cand MOD 2 este functional:
1. ✅ Verifica TESTING_GUIDE.md - MOD 2 section
2. ✅ Marcheaza MOD 2 ca PASS
3. ✅ Mergi la MOD 3: KUBERNETES

---

**SUCCES! Docker este powerful! 🐳**
