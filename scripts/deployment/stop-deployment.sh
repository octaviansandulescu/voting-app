#!/bin/bash

# ============================================================================
# Kubernetes Deployment STOP Script
# ============================================================================
# Delete all voting app resources from GKE cluster
# Run: ./stop-deployment.sh
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
ZONE="us-central1-a"  # Use zone for gcloud container clusters
NAMESPACE="voting-app"

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║               Kubernetes Deployment - STOP                             ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""

# Confirm before deleting
echo -e "${YELLOW}⚠️  WARNING: This will DELETE all voting app resources!${NC}"
echo ""
echo "This will delete:"
echo "  - All pods (frontend, backend, cloud-sql-proxy)"
echo "  - All services and load balancers"
echo "  - All persistent data in the namespace"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${BLUE}❌ Cancelled${NC}"
    exit 0
fi
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
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID
echo -e "${GREEN}✅ Connected to cluster: $CLUSTER_NAME${NC}"
echo ""

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo -e "${YELLOW}⚠️  Namespace doesn't exist${NC}"
    exit 0
fi
echo ""

# Delete all resources in namespace
echo -e "${BLUE}🗑️  Deleting all resources...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Deleting deployments..."
kubectl delete deployment -n $NAMESPACE --all
echo -e "${GREEN}✅ Deployments deleted${NC}"

echo "Deleting services..."
kubectl delete svc -n $NAMESPACE --all
echo -e "${GREEN}✅ Services deleted${NC}"

echo "Deleting secrets..."
kubectl delete secrets -n $NAMESPACE --all
echo -e "${GREEN}✅ Secrets deleted${NC}"

echo "Deleting namespace..."
kubectl delete namespace $NAMESPACE --wait=true
echo -e "${GREEN}✅ Namespace deleted${NC}"
echo ""

# Wait for namespace to be fully deleted
echo "⏳ Waiting for namespace to be fully deleted..."
for i in {1..30}; do
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        echo -e "${GREEN}✅ Namespace fully removed${NC}"
        break
    fi
    sleep 1
done
echo ""

# Summary
echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║                     ✅ DEPLOYMENT STOPPED                             ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "All voting app resources have been deleted from the cluster."
echo ""
echo "To redeploy:"
echo "  ./scripts/deployment/start-deployment.sh"
echo ""
