#!/bin/bash

# ============================================================================
# Kubernetes Deployment START Script
# ============================================================================
# Deploy voting app to GKE cluster
# Run: ./start-deployment.sh
# ============================================================================

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID=$(gcloud config get-value project)
CLUSTER_NAME="voting-cluster"
REGION="us-central1"
NAMESPACE="voting-app"
MANIFESTS_DIR="infrastructure/kubernetes"

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║               Kubernetes Deployment - START                            ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""

# Check prerequisites
echo -e "${BLUE}📋 Checking prerequisites...${NC}"
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ ERROR: gcloud CLI not found${NC}"
    exit 1
fi
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ ERROR: kubectl not found${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Prerequisites OK${NC}"
echo ""

# Get cluster credentials
echo -e "${BLUE}🔑 Getting cluster credentials...${NC}"
gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION --project $PROJECT_ID
echo -e "${GREEN}✅ Connected to cluster: $CLUSTER_NAME${NC}"
echo ""

# Create namespace if it doesn't exist
echo -e "${BLUE}📦 Creating namespace...${NC}"
if kubectl get namespace $NAMESPACE &> /dev/null; then
    echo -e "${YELLOW}⚠️  Namespace already exists${NC}"
else
    kubectl create namespace $NAMESPACE
    echo -e "${GREEN}✅ Namespace created${NC}"
fi
echo ""

# Apply manifests in order
echo -e "${BLUE}🚀 Deploying application...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Create secrets
echo -e "${BLUE}Step 1/5: Creating secrets...${NC}"
if kubectl get secret -n $NAMESPACE voting-secrets &> /dev/null; then
    echo -e "${YELLOW}⚠️  Secret already exists, skipping...${NC}"
else
    kubectl apply -f $MANIFESTS_DIR/01-secrets.yaml
    echo -e "${GREEN}✅ Secrets created${NC}"
fi
echo ""

# 2. Deploy Cloud SQL Proxy (optional - for now skip due to image availability)
echo -e "${BLUE}Step 2/5: Checking Cloud SQL Proxy...${NC}"
echo -e "${YELLOW}⚠️  Cloud SQL Proxy skipped (using direct Cloud SQL IP for MVP)${NC}"
echo -e "${YELLOW}   Tip: For production, setup Cloud SQL Proxy with Workload Identity${NC}"
echo -e "${YELLOW}   See: docs/guides/CLOUD_SQL_PROXY_SETUP.md${NC}"
echo ""

# 3. Deploy Backend
echo -e "${BLUE}Step 3/5: Deploying Backend...${NC}"
if kubectl apply -f $MANIFESTS_DIR/02-backend-deployment.yaml; then
    echo -e "${GREEN}✅ Backend deployment applied${NC}"
else
    echo -e "${RED}❌ Failed to deploy backend${NC}"
    exit 1
fi
echo ""

# 4. Deploy Frontend
echo -e "${BLUE}Step 4/5: Deploying Frontend...${NC}"
if kubectl apply -f $MANIFESTS_DIR/03-frontend-deployment.yaml; then
    echo -e "${GREEN}✅ Frontend deployment applied${NC}"
else
    echo -e "${RED}❌ Failed to deploy frontend${NC}"
    exit 1
fi
echo ""

# 5. Wait for deployments to be ready
echo -e "${BLUE}Step 5/5: Waiting for deployments to be ready...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Wait for Backend
echo "⏳ Backend deployment..."
kubectl rollout status deployment/backend -n $NAMESPACE --timeout=300s
echo -e "${GREEN}✅ Backend ready${NC}"
echo ""

# Wait for Frontend
echo "⏳ Frontend deployment..."
kubectl rollout status deployment/frontend -n $NAMESPACE --timeout=300s
echo -e "${GREEN}✅ Frontend ready${NC}"
echo ""

# Get LoadBalancer IP
echo -e "${BLUE}📡 Getting LoadBalancer IP...${NC}"
echo "⏳ Waiting for external IP assignment..."
for i in {1..30}; do
    EXTERNAL_IP=$(kubectl get svc frontend -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ ! -z "$EXTERNAL_IP" ]; then
        echo -e "${GREEN}✅ Frontend available at: http://$EXTERNAL_IP${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${YELLOW}⚠️  LoadBalancer IP not assigned yet. Check later with:${NC}"
        echo "    kubectl get svc frontend -n $NAMESPACE"
    fi
    echo -n "."
    sleep 2
done
echo ""
echo ""

# Summary
echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║                     ✅ DEPLOYMENT COMPLETE                            ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Check deployment status:"
echo "     ./scripts/deployment/status-deployment.sh"
echo ""
echo "  2. Validate application:"
echo "     ./scripts/deployment/validate-deployment.sh"
echo ""
echo "  3. View logs:"
echo "     kubectl logs -n $NAMESPACE -l app=backend -f"
echo ""
