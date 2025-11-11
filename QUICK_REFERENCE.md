#!/bin/bash

# ============================================================================
# VOTING APP - QUICK REFERENCE CARD
# ============================================================================

cat << 'EOF'

╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║                    VOTING APP - QUICK REFERENCE CARD                      ║
║                                                                            ║
║              Environment Auto-Detection ✓ Complete!                       ║
║              Infrastructure as Code ✓ Complete!                           ║
║              Local docker-compose ✓ Ready!                                ║
║              GCP Kubernetes ✓ Ready to deploy!                            ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝


📋 QUICK COMMANDS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

LOCAL TESTING (docker-compose)
────────────────────────────────
  # Start containers
  docker-compose up -d
  
  # Test backend
  curl http://localhost:8000/results | jq
  
  # Test frontend via nginx
  curl http://localhost/api/results | jq
  
  # View logs
  docker-compose logs -f backend
  
  # Stop containers
  docker-compose down


GCP DEPLOYMENT (Kubernetes)
────────────────────────────
  # One-command automated deployment
  chmod +x deploy-to-gcp.sh
  ./deploy-to-gcp.sh
  
  OR manual steps:
  
  # Build images
  docker-compose build
  
  # Push to registry
  docker tag voting-app-frontend:latest \
    us-central1-docker.pkg.dev/diesel-skyline-474415-j6/voting-app-docker/frontend:latest
  docker tag voting-app-backend:latest \
    us-central1-docker.pkg.dev/diesel-skyline-474415-j6/voting-app-docker/backend:latest
  gcloud auth configure-docker us-central1-docker.pkg.dev
  docker push us-central1-docker.pkg.dev/diesel-skyline-474415-j6/voting-app-docker/frontend:latest
  docker push us-central1-docker.pkg.dev/diesel-skyline-474415-j6/voting-app-docker/backend:latest
  
  # Deploy to GCP
  gcloud container clusters get-credentials voting-app-cluster \
    --zone us-central1 --project diesel-skyline-474415-j6
  kubectl apply -f k8s/
  
  # Get access URL
  kubectl get svc frontend -n voting-app


MONITORING
──────────
  # Check pod status
  kubectl get pods -n voting-app
  
  # View logs
  kubectl logs -n voting-app -f deployment/frontend
  kubectl logs -n voting-app -f deployment/backend
  
  # Watch services
  kubectl get svc -n voting-app -w
  
  # Describe resources
  kubectl describe pod <pod-name> -n voting-app


DEBUGGING
─────────
  # SSH into container
  kubectl exec -it <pod-name> -n voting-app -- /bin/sh
  
  # Check API connectivity
  kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
    curl http://backend:8000/results
  
  # Check database connection
  kubectl exec -it <backend-pod> -n voting-app -- python \
    -c "from database import SessionLocal; SessionLocal()"
  
  # View cluster events
  kubectl get events -n voting-app


🔧 FILE LOCATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Frontend
  ├─ src/frontend/index.html       Main page
  ├─ src/frontend/script.js        ✅ AUTO-DETECTING API endpoint
  ├─ src/frontend/style.css        Styling
  ├─ src/frontend/nginx.conf       Nginx reverse proxy config

Backend
  ├─ src/backend/main.py           FastAPI application
  ├─ src/backend/database.py        Database models
  └─ src/backend/Dockerfile        Container image

Infrastructure
  ├─ terraform/main.tf             GCP infrastructure
  ├─ terraform/variables.tf        Variables
  ├─ terraform/terraform.tfvars    GCP credentials & settings
  ├─ k8s/01-namespace-secret.yaml  Namespace & secrets
  ├─ k8s/02-backend-deployment.yaml Backend pods
  ├─ k8s/03-frontend-deployment.yaml Frontend pods
  └─ k8s/04-ingress.yaml           LoadBalancer config

Scripts
  ├─ deploy-to-gcp.sh              🚀 Automated deployment
  ├─ test-auto-detection.sh        Testing script
  └─ docker-compose.yml            Local development

Documentation
  ├─ DEPLOYMENT_READY.md           📖 Complete guide
  ├─ NEXT_STEPS.md                 📖 Step-by-step instructions
  ├─ TESTING_AUTO_DETECTION.md     📖 Test procedures
  └─ README.md                      📖 Project overview


📊 ENVIRONMENT DETAILS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

GCP Configuration
  Project ID:        diesel-skyline-474415-j6
  Region:            us-central1
  GKE Cluster:       voting-app-cluster
  Machine Type:      e2-medium
  Nodes:             1
  Cloud SQL:         voting-app-mysql
  SQL Private IP:    Yes (no public access)
  Artifact Registry: us-central1-docker.pkg.dev/diesel-skyline-474415-j6/voting-app-docker
  VPC:               voting-app-vpc (10.0.0.0/24)

Application Ports
  Local:
    Frontend:  localhost:80      (nginx)
    Backend:   localhost:8000    (FastAPI)
    Database:  localhost:3306    (MySQL)
  
  GCP:
    Frontend:  LoadBalancer (public IP)
    Backend:   ClusterIP service (internal)
    Database:  Cloud SQL private IP (VPC only)

Auto-Detection Logic
  Local (localhost):        http://localhost:8000
  GCP (any other hostname): http://<LoadBalancer-IP>/api


✅ DEPLOYMENT CHECKLIST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Infrastructure ✓
  ☑ Terraform configured for GCP
  ☑ GKE cluster created
  ☑ Cloud SQL instance created
  ☑ Private VPC connection established
  ☑ Artifact Registry created

Code ✓
  ☑ Frontend HTML complete
  ☑ script.js with auto-detection ✅
  ☑ Backend FastAPI ready
  ☑ Database models configured
  ☑ nginx.conf with /api proxy

Deployment Files ✓
  ☑ Kubernetes manifests ready
  ☑ Dockerfile for backend
  ☑ docker-compose for local dev
  ☑ Deployment scripts ready

Ready to Deploy ✓
  ☑ GCP project authenticated
  ☑ kubectl configured
  ☑ docker configured
  ☑ Images ready to build and push


🎯 NEXT STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. DEPLOY TO GCP
   ./deploy-to-gcp.sh
   
2. WAIT FOR LOADBALANCER IP
   kubectl get svc frontend -n voting-app -w
   
3. OPEN IN BROWSER
   http://<EXTERNAL-IP>
   
4. VERIFY AUTO-DETECTION
   Open DevTools (F12) → Console
   Should show: API_BASE_URL = http://<IP>/api
   
5. TEST FUNCTIONALITY
   Vote for dogs/cats
   Verify results update every 2 seconds
   Refresh page - votes should persist


📖 DOCUMENTATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Quick Start:     DEPLOYMENT_READY.md
Step-by-Step:    NEXT_STEPS.md
Testing:         TESTING_AUTO_DETECTION.md
Project Info:    README.md
GCP Setup:       GCP_QUICKSTART.md


🎓 KEY FEATURES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Environment Auto-Detection
  Same code works on:
  - Local docker-compose (direct backend)
  - GCP Kubernetes (via nginx proxy)

✓ Infrastructure as Code
  Complete Terraform setup:
  - GKE cluster
  - Cloud SQL (private IP only)
  - VPC networking
  - Service accounts & IAM

✓ Production Ready
  - Kubernetes scaling (easily add replicas)
  - Cloud SQL managed database
  - Load balancer for high availability
  - Private networking for database

✓ No Breaking Changes
  Local docker-compose still works exactly as before
  Same script.js in both environments


═══════════════════════════════════════════════════════════════════════════════

Ready to deploy? Run: ./deploy-to-gcp.sh

Questions? Check the documentation files.

═══════════════════════════════════════════════════════════════════════════════

EOF
