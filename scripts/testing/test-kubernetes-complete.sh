#!/bin/bash

###############################################################################
#  KUBERNETES TEST - COMPLETE GUIDE
#  
#  Steps to deploy and test on GCP
###############################################################################

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   ☸️  KUBERNETES DEPLOYMENT - GCP + TERRAFORM + GKE           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# STEP 1: Verify Prerequisites
# ============================================================================

echo "[STEP 1] Verifying prerequisites..."
echo ""

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo "  ❌ Terraform not found"
    exit 1
fi
echo "  ✓ Terraform: $(terraform version -json | grep -o '"version":"[^"]*' | cut -d'"' -f4)"

# Check gcloud
if ! command -v gcloud &> /dev/null; then
    echo "  ❌ gcloud CLI not found"
    exit 1
fi
echo "  ✓ gcloud CLI: $(gcloud --version | head -1)"

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo "  ❌ kubectl not found"
    exit 1
fi
echo "  ✓ kubectl: $(kubectl version --client --short 2>/dev/null)"

# Check GCP auth
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "@"; then
    echo "  ❌ Not authenticated to GCP. Run: gcloud auth login"
    exit 1
fi
GCP_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
echo "  ✓ GCP Account: $GCP_ACCOUNT"

# Check GCP project
GCP_PROJECT=$(gcloud config get-value project)
echo "  ✓ GCP Project: $GCP_PROJECT"

echo ""

# ============================================================================
# STEP 2: Initialize Terraform
# ============================================================================

echo "[STEP 2] Terraform initialization..."
echo ""

cd 3-KUBERNETES/terraform || exit 1

if terraform init -upgrade > /tmp/tf_init.log 2>&1; then
    echo "  ✓ Terraform initialized successfully"
else
    echo "  ❌ Terraform initialization failed"
    tail -20 /tmp/tf_init.log
    exit 1
fi

echo ""

# ============================================================================
# STEP 3: Terraform Plan
# ============================================================================

echo "[STEP 3] Terraform plan (validating)..."
echo ""

if rm -f tfplan && terraform plan -out=tfplan > /tmp/tf_plan.log 2>&1; then
    echo "  ✓ Terraform plan successful"
    echo ""
    echo "  Resources to be created:"
    grep -E "resource|module" /tmp/tf_plan.log | head -10
else
    echo "  ❌ Terraform plan failed"
    tail -30 /tmp/tf_plan.log
    exit 1
fi

echo ""

# ============================================================================
# STEP 4: Terraform Apply
# ============================================================================

echo "[STEP 4] Terraform apply (creating GCP resources)..."
echo ""
echo "⏳ This may take 10-20 minutes. Please wait..."
echo ""

if terraform apply tfplan > /tmp/tf_apply.log 2>&1; then
    echo "  ✓ Terraform apply successful"
    echo ""
    echo "  Extracting outputs..."
    
    CLUSTER_NAME=$(terraform output -raw kubernetes_cluster_name 2>/dev/null)
    CLUSTER_HOST=$(terraform output -raw kubernetes_cluster_host 2>/dev/null)
    SQL_CONN=$(terraform output -raw sql_instance_connection_name 2>/dev/null)
    SQL_USER=$(terraform output -raw sql_database_user 2>/dev/null)
    SQL_PASS=$(terraform output -raw sql_database_password 2>/dev/null)
    SQL_IP=$(terraform output -raw sql_instance_ip 2>/dev/null)
    
    echo "  ✓ Cluster: $CLUSTER_NAME"
    echo "  ✓ Cloud SQL: $SQL_CONN"
    echo "  ✓ Database User: $SQL_USER"
    echo "  ✓ Database IP: $SQL_IP"
else
    echo "  ❌ Terraform apply failed"
    tail -30 /tmp/tf_apply.log
    exit 1
fi

echo ""

# ============================================================================
# STEP 5: Get Kubernetes Credentials
# ============================================================================

echo "[STEP 5] Getting Kubernetes credentials..."
echo ""

if gcloud container clusters get-credentials $CLUSTER_NAME --region $GCP_PROJECT 2>/tmp/gke_creds.log; then
    echo "  ✓ Credentials configured"
    
    # Verify kubectl connection
    if kubectl cluster-info > /dev/null 2>&1; then
        echo "  ✓ kubectl connected to GKE cluster"
    else
        echo "  ❌ kubectl connection failed"
        cat /tmp/gke_creds.log
        exit 1
    fi
else
    echo "  ❌ Failed to get credentials"
    cat /tmp/gke_creds.log
    exit 1
fi

echo ""

# ============================================================================
# STEP 6: Create Kubernetes Namespace
# ============================================================================

echo "[STEP 6] Creating Kubernetes namespace..."
echo ""

cd ../../k8s || exit 1

if kubectl apply -f 00-namespace.yaml > /tmp/k8s_ns.log 2>&1; then
    echo "  ✓ Namespace created"
else
    echo "  ❌ Failed to create namespace"
    cat /tmp/k8s_ns.log
    exit 1
fi

# Verify namespace
if kubectl get namespace voting-app > /dev/null 2>&1; then
    echo "  ✓ Namespace verified"
else
    echo "  ❌ Namespace not found"
    exit 1
fi

echo ""

# ============================================================================
# STEP 7: Create Secrets and ConfigMaps
# ============================================================================

echo "[STEP 7] Creating Kubernetes secrets..."
echo ""

# Update secrets with actual Cloud SQL credentials
cat << EOF > /tmp/secrets-patch.yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: voting-app
type: Opaque
stringData:
  DB_HOST: "$SQL_IP"
  DB_PORT: "3306"
  DB_USER: "$SQL_USER"
  DB_PASSWORD: "$SQL_PASS"
  DB_NAME: "voting_app_k8s"
EOF

if kubectl apply -f /tmp/secrets-patch.yaml > /tmp/k8s_secrets.log 2>&1; then
    echo "  ✓ Secrets created"
else
    echo "  ❌ Failed to create secrets"
    cat /tmp/k8s_secrets.log
    exit 1
fi

if kubectl apply -f 01-secrets.yaml --selector=kind=ConfigMap > /tmp/k8s_config.log 2>&1; then
    echo "  ✓ ConfigMaps created"
fi

echo ""

# ============================================================================
# STEP 8: Deploy Backend
# ============================================================================

echo "[STEP 8] Deploying backend..."
echo ""

if kubectl apply -f 02-backend-deployment.yaml > /tmp/k8s_backend.log 2>&1; then
    echo "  ✓ Backend deployment created"
    
    # Wait for backend pods
    echo "  Waiting for backend pods to be ready..."
    if kubectl wait --for=condition=ready pod -l app=backend -n voting-app --timeout=300s > /dev/null 2>&1; then
        echo "  ✓ Backend pods ready"
        
        # Show pod status
        kubectl get pods -n voting-app -l app=backend
    else
        echo "  ⚠ Backend pods not ready yet"
        echo "  Check logs: kubectl logs -n voting-app -l app=backend"
    fi
else
    echo "  ❌ Failed to deploy backend"
    cat /tmp/k8s_backend.log
    exit 1
fi

echo ""

# ============================================================================
# STEP 9: Deploy Frontend
# ============================================================================

echo "[STEP 9] Deploying frontend..."
echo ""

if kubectl apply -f 03-frontend-deployment.yaml > /tmp/k8s_frontend.log 2>&1; then
    echo "  ✓ Frontend deployment created"
    
    # Wait for frontend pods
    echo "  Waiting for frontend pods to be ready..."
    if kubectl wait --for=condition=ready pod -l app=frontend -n voting-app --timeout=300s > /dev/null 2>&1; then
        echo "  ✓ Frontend pods ready"
        
        # Show pod status
        kubectl get pods -n voting-app -l app=frontend
    else
        echo "  ⚠ Frontend pods not ready yet"
        echo "  Check logs: kubectl logs -n voting-app -l app=frontend"
    fi
else
    echo "  ❌ Failed to deploy frontend"
    cat /tmp/k8s_frontend.log
    exit 1
fi

echo ""

# ============================================================================
# STEP 10: Get LoadBalancer IP
# ============================================================================

echo "[STEP 10] Getting LoadBalancer IP..."
echo ""

echo "  Waiting for LoadBalancer IP assignment (may take 2-3 minutes)..."

FRONTEND_IP=""
ATTEMPTS=0
MAX_ATTEMPTS=30

while [ -z "$FRONTEND_IP" ] && [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    FRONTEND_IP=$(kubectl get svc frontend-service -n voting-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    
    if [ -z "$FRONTEND_IP" ]; then
        ATTEMPTS=$((ATTEMPTS + 1))
        echo "  ⏳ Attempt $ATTEMPTS/$MAX_ATTEMPTS - Waiting..."
        sleep 5
    fi
done

if [ -z "$FRONTEND_IP" ]; then
    echo "  ⚠ LoadBalancer IP not assigned yet"
    echo "  Check status: kubectl get svc -n voting-app"
else
    echo "  ✓ LoadBalancer IP: $FRONTEND_IP"
    echo ""
    echo "  🎉 Application is accessible at:"
    echo "     http://$FRONTEND_IP"
fi

echo ""

# ============================================================================
# STEP 11: Verify Deployments
# ============================================================================

echo "[STEP 11] Deployment verification..."
echo ""

echo "  Kubernetes Cluster Status:"
kubectl cluster-info | grep -E "master|server"

echo ""
echo "  Namespaces:"
kubectl get namespaces

echo ""
echo "  Pods in voting-app:"
kubectl get pods -n voting-app

echo ""
echo "  Services in voting-app:"
kubectl get svc -n voting-app

echo ""
echo "  Deployments:"
kubectl get deployments -n voting-app

echo ""

# ============================================================================
# FINAL SUMMARY
# ============================================================================

echo "════════════════════════════════════════════════════════════════"
echo "✅ KUBERNETES DEPLOYMENT COMPLETE"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Resources Created:"
echo "  • GKE Cluster: $CLUSTER_NAME"
echo "  • Cloud SQL Instance: voting-app-db"
echo "  • Backend Pods: 2 replicas"
echo "  • Frontend Pods: 2 replicas"
echo "  • LoadBalancer: $FRONTEND_IP"
echo ""
echo "Next Steps:"
echo "  1. Open browser: http://$FRONTEND_IP"
echo "  2. Test voting functionality"
echo "  3. Monitor logs: kubectl logs -f -n voting-app -l app=backend"
echo "  4. Scale pods: kubectl scale deployment backend -n voting-app --replicas=3"
echo ""
echo "Cleanup (when done):"
echo "  cd 3-KUBERNETES/terraform"
echo "  terraform destroy"
echo ""
