# Phase 2.2: Docker Setup Guide

**Estimated Time**: 15 minutes | **Difficulty**: Intermediate | **Prerequisites**: LOCAL_SETUP.md, TESTING_FUNDAMENTALS.md

## Overview

In this guide, you'll deploy the voting app using Docker and Docker Compose. This containerizes the application and database, making it portable and reproducible across all environments.

**What you'll learn**:
- ✅ How Docker containerization works
- ✅ How to build Docker images
- ✅ How to use Docker Compose for multi-container orchestration
- ✅ How to test containerized applications
- ✅ How environment detection works in Docker

## Prerequisites

Before starting, ensure you have:

```bash
# Required
docker --version            # Should be 20.10+
docker-compose --version    # Should be 2.0+
docker ps                   # Should run without sudo

# If Docker requires sudo, add your user:
# sudo usermod -aG docker $USER
# newgrp docker
```

**System Requirements**:
- RAM: 4 GB minimum (for DB + backend + frontend)
- Disk: 2 GB free (for Docker images)
- Docker daemon running

## Step 1: Understand Docker Compose Architecture

The `docker-compose.yml` file orchestrates three services:

```yaml
Services:
├── database (MySQL)
│   └── Port 3306 (internal only)
├── backend (FastAPI)
│   └── Port 8000 (exposed)
└── frontend (Nginx)
    └── Port 80 (exposed)

Network: voting-app-network
Volume: voting-app-db (persistent MySQL data)
```

### 1.1 Review docker-compose.yml

```bash
cat docker-compose.yml
```

**Key sections**:
- `version`: Docker Compose version
- `services`: Container definitions
- `networks`: Communication between containers
- `volumes`: Data persistence

## Step 2: Build Docker Images

### 2.1 Build Backend Image

```bash
# Build from Dockerfile
docker build -t voting-app-backend:local -f src/backend/Dockerfile src/backend/

# Verify image was created
docker images | grep voting-app-backend
```

**What happens**:
1. Reads `src/backend/Dockerfile`
2. Creates Python environment
3. Installs dependencies from `requirements.txt`
4. Copies application code
5. Tags as `voting-app-backend:local`

### 2.2 Build Frontend Image

```bash
# Build frontend
docker build -t voting-app-frontend:local -f src/frontend/Dockerfile src/frontend/

# Verify
docker images | grep voting-app-frontend
```

### 2.3 Verify Images

```bash
# List all voting-app images
docker images | grep voting-app

# Expected:
# voting-app-backend   local        <image-id>   5 minutes ago   500MB
# voting-app-frontend  local        <image-id>   2 minutes ago   100MB
```

## Step 3: Configure Environment Variables

### 3.1 Create .env.docker File

```bash
cat > .env.docker << 'EOF'
# Docker Environment Configuration
DEPLOYMENT_MODE=docker
DATABASE_HOST=database
DATABASE_PORT=3306
DATABASE_USER=voting_user
DATABASE_PASSWORD=voting_password_docker
DATABASE_NAME=voting_app_docker

# MySQL Configuration
MYSQL_ROOT_PASSWORD=root_password_docker
MYSQL_DATABASE=voting_app_docker
MYSQL_USER=voting_user
MYSQL_PASSWORD=voting_password_docker

# Application Settings
DEBUG=False
LOG_LEVEL=info
EOF
```

### 3.2 Verify Environment File

```bash
# Check it's configured correctly
cat .env.docker

# Ensure it's in .gitignore
grep ".env.docker" .gitignore
```

## Step 4: Review Dockerfile Configurations

### 4.1 Backend Dockerfile

Expected `src/backend/Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Set environment detection
ENV DEPLOYMENT_MODE=docker

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health')"

# Run application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 4.2 Frontend Dockerfile

Expected `src/frontend/Dockerfile`:

```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY . .
# No build step needed for plain HTML/JS

FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=builder /app /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## Step 5: Start Services with Docker Compose

### 5.1 Start All Services

```bash
# Start in detached mode (background)
docker-compose up -d

# Or start with logs visible
docker-compose up

# Ctrl+C to stop (doesn't remove containers with -d)
```

**Output should show**:
```
Creating voting-app-database ... done
Creating voting-app-backend  ... done
Creating voting-app-frontend ... done
```

### 5.2 Check Service Status

```bash
# List running containers
docker-compose ps

# Expected:
# NAME                 STATUS              PORTS
# voting-app-database  Up 2 minutes        3306/tcp
# voting-app-backend   Up 2 minutes        0.0.0.0:8000->8000/tcp
# voting-app-frontend  Up 2 minutes        0.0.0.0:80->80/tcp
```

### 5.3 View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f database
docker-compose logs -f frontend

# Last 50 lines
docker-compose logs --tail=50
```

## Step 6: Test Backend API

### 6.1 Health Check

```bash
# Health endpoint
curl -X GET http://localhost:8000/health

# Expected:
# {"status": "healthy", "mode": "docker"}
```

### 6.2 Vote Submission

```bash
# Submit votes
curl -X POST http://localhost:8000/vote \
  -H "Content-Type: application/json" \
  -d '{"vote": "dogs"}'

# Expected:
# {"message": "Vote recorded", "total_votes": 1}
```

### 6.3 Get Results

```bash
# Get results
curl -X GET http://localhost:8000/results

# Expected:
# {"dogs": 1, "cats": 0}
```

## Step 7: Test Frontend

### 7.1 Access Frontend

```bash
# Open browser
open http://localhost
```

Or use curl:
```bash
curl -I http://localhost

# Should return 200 OK with nginx headers
```

### 7.2 Verify Frontend Functionality

1. Open http://localhost in browser
2. Click "Vote for Dogs"
3. See vote count increase
4. Refresh page - vote persists ✅
5. Check results update in real-time

## Step 8: Run Tests in Docker

### 8.1 Run Tests in Backend Container

```bash
# Execute pytest inside running container
docker-compose exec backend pytest tests/ -v

# With coverage
docker-compose exec backend pytest tests/ --cov=. -v
```

### 8.2 Run Specific Test

```bash
# Run single test file
docker-compose exec backend pytest tests/test_api.py -v

# Run with verbose output
docker-compose exec backend pytest tests/test_api.py::test_health_endpoint -v
```

### 8.3 Interactive Testing

```bash
# Open bash shell in backend container
docker-compose exec backend bash

# Inside container, run tests
pytest tests/ -v
pip list
python -c "import mysql.connector; print('MySQL OK')"

# Exit
exit
```

## Step 9: Database Operations

### 9.1 Access MySQL in Container

```bash
# Connect to MySQL
docker-compose exec database mysql -u voting_user -p

# Enter password: voting_password_docker
# Then query:
SELECT * FROM votes;
```

### 9.2 View Database Logs

```bash
docker-compose logs database

# Check for connection errors, startup issues
```

### 9.3 Database Initialization

If the database doesn't have tables:

```bash
# Execute SQL from file
docker-compose exec database mysql -u voting_user -p voting_app_docker < src/backend/schema.sql

# Or create tables manually
docker-compose exec database mysql -u voting_user -p voting_app_docker << 'EOF'
CREATE TABLE IF NOT EXISTS votes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vote VARCHAR(10) NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT
);
EOF
```

## Step 10: Development Workflow with Docker

### 10.1 Code Changes with Hot Reload

```bash
# Backend code changes auto-reload (if PYTHONUNBUFFERED set)
# Edit src/backend/main.py
# Changes take effect when you refresh browser
```

### 10.2 Test-Driven Development in Docker

```bash
# Terminal 1: Start services
docker-compose up

# Terminal 2: Watch tests
docker-compose exec backend pytest tests/ -v --tb=short

# Terminal 3: Make code changes
# Edit src/backend/main.py

# Terminal 2: Tests rerun automatically (or manually)
docker-compose exec backend pytest tests/ -v
```

### 10.3 Build Images After Changes

If you change `requirements.txt`:

```bash
# Rebuild images
docker-compose build

# Then restart
docker-compose up -d
```

## Step 11: Environment Detection

### Verify Environment Mode

The application detects it's running in Docker mode:

```bash
# Check mode returned by API
curl http://localhost:8000/health | grep mode

# Should show: "mode": "docker"
```

### 11.1 How Detection Works

In `src/backend/config.py`:

```python
# Detects DEPLOYMENT_MODE environment variable
mode = os.getenv('DEPLOYMENT_MODE', 'local')

if mode == 'docker':
    # Use Docker network DNS for database
    db_host = 'database'  # Container name resolves via Docker DNS
```

## Step 12: Troubleshooting

### Issue: "Connection refused" for backend

```bash
# Check if backend container is running
docker-compose ps backend

# View backend logs
docker-compose logs backend

# Check if port 8000 is accessible
curl http://localhost:8000/health

# If not, restart
docker-compose restart backend
```

### Issue: Database connection fails

```bash
# Check database container
docker-compose logs database

# Verify database is ready
docker-compose exec database mysql -u voting_user -p voting_app_docker -e "SELECT 1"

# Wait for database to be ready, then restart backend
docker-compose restart backend
```

### Issue: Frontend shows blank page

```bash
# Check frontend logs
docker-compose logs frontend

# Check frontend container
docker-compose ps frontend

# Test Nginx is responding
curl -I http://localhost

# Restart
docker-compose restart frontend
```

### Issue: "Port 80 already in use"

```bash
# Find what's using port 80
sudo lsof -i :80

# Either stop that service or use different port:
# In docker-compose.yml: change "80:80" to "8080:80"
# Then access http://localhost:8080

# Or restart Docker
docker-compose restart
```

### Issue: Build fails - layer caching

```bash
# Rebuild without using cache
docker-compose build --no-cache

# Then restart
docker-compose up -d
```

## Step 13: Clean Up

### 13.1 Stop Services

```bash
# Stop all services (keeps containers)
docker-compose stop

# Or stop specific service
docker-compose stop backend
```

### 13.2 Remove Containers

```bash
# Remove all containers (keeps images)
docker-compose down

# Keep data in volumes
docker-compose down -v  # Also removes volumes!
```

### 13.3 Remove Images

```bash
# Remove images (keeps data)
docker rmi voting-app-backend:local voting-app-frontend:local

# Or remove all
docker image prune
```

### 13.4 Complete Cleanup

```bash
# Remove everything (containers, images, volumes, networks)
docker-compose down -v --rmi all
```

## Step 14: Health Checks

### 14.1 Container Health Status

```bash
# Check if container is healthy
docker-compose ps

# Status column shows:
# Up (no health check)
# Up (healthy)
# Up (unhealthy)
```

### 14.2 Manual Health Check

```bash
# Backend health
curl http://localhost:8000/health

# Frontend health
curl -I http://localhost

# Database health
docker-compose exec database mysql -u voting_user -p -e "SELECT 1"
```

## Step 15: Scaling and Performance

### 15.1 Run Multiple Backend Instances

Edit `docker-compose.yml`:

```yaml
services:
  backend:
    build: ./src/backend
    deploy:
      replicas: 3  # Run 3 instances
    ports:
      - "8000-8002:8000"  # Maps ports 8000, 8001, 8002
```

Then start:
```bash
docker-compose up -d
```

### 15.2 Monitor Resource Usage

```bash
# CPU, memory, network stats
docker stats

# Or just backend
docker stats voting-app-backend
```

## Security Checklist - Docker Deployment

Before moving to Kubernetes, verify:

- ✅ `.env.docker` is in `.gitignore`
- ✅ Database password is strong
- ✅ No secrets hardcoded in Dockerfiles
- ✅ Using `FROM` images with specific versions (not `latest`)
- ✅ Images run as non-root user (if possible)
- ✅ No sensitive data in Docker logs
- ✅ All tests pass in container environment

Check for secrets:
```bash
# Search all Dockerfiles
grep -r "password\|secret\|api_key\|token" src/ | grep -v ".env"

# Should return nothing
```

## Testing Checklist - Docker Deployment

- ✅ All unit tests pass (`docker-compose exec backend pytest tests/ -v`)
- ✅ API endpoints respond correctly (`curl http://localhost:8000/...`)
- ✅ Database stores votes correctly
- ✅ Frontend displays and submits votes
- ✅ Environment detection shows "docker"
- ✅ No errors in Docker logs
- ✅ Containers restart on failure

## Next Steps

Congratulations! Docker deployment works! 🐳

**What you've learned**:
- How to containerize applications
- How to orchestrate multiple containers
- How to test containerized services
- How persistent volumes work

**Ready for next phase?**
- Issues? Review docker-compose.yml and Dockerfiles
- Ready for production? → Move to `docs/guides/KUBERNETES_SETUP.md`

## Resources

- **Docker Documentation**: https://docs.docker.com/
- **Docker Compose**: https://docs.docker.com/compose/
- **Best Practices**: https://docs.docker.com/develop/dev-best-practices/
- **Security**: https://docs.docker.com/engine/security/

---

**Questions?** Check TESTING_FUNDAMENTALS.md or SECURITY.md

**Ready for Kubernetes?** Continue to `docs/guides/KUBERNETES_SETUP.md` →
