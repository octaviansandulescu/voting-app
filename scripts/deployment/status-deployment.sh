#!/bin/bash

# ============================================================================
# Kubernetes Deployment STATUS Script
# ============================================================================
# Auto-detects cluster, namespace, and Cloud SQL resources
# Checks deployment status and health of all components
# Run: ./status-deployment.sh
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║            Kubernetes Deployment - STATUS CHECK                        ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""

# Source detection script to auto-discover resources
source "$SCRIPT_DIR/detect-resources.sh"

# ═══════════════════════════════════════════════════════════════════════════════
# VALIDATION: Check if resources exist
# ═══════════════════════════════════════════════════════════════════════════════

if [ -z "$CLUSTER_NAME" ]; then
    echo -e "${RED}❌ No Kubernetes cluster found!${NC}"
    echo ""
    echo "To create a cluster and deploy:"
    echo "  cd 3-KUBERNETES/terraform && terraform apply"
    echo "  ./scripts/deployment/start-deployment.sh"
    echo ""
    exit 0
fi

if [ -z "$NAMESPACE" ]; then
    echo -e "${RED}❌ No application namespace found!${NC}"
    echo ""
    echo "Available namespaces:"
    gcloud container clusters get-credentials "$CLUSTER_NAME" \
        --zone "$CLUSTER_ZONE" \
        --project "$PROJECT_ID" 2>/dev/null || true
    
    kubectl get namespaces 2>/dev/null || true
    echo ""
    exit 0
fi

# Get credentials
gcloud container clusters get-credentials "$CLUSTER_NAME" \
    --zone "$CLUSTER_ZONE" \
    --project "$PROJECT_ID" 2>/dev/null

# ═══════════════════════════════════════════════════════════════════════════════
# DISPLAY: Cluster Information
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}📊 Cluster Information${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Cluster:   $CLUSTER_NAME"
echo "Zone:      $CLUSTER_ZONE"
echo "Project:   $PROJECT_ID"
echo "Namespace: $NAMESPACE"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# DISPLAY: Namespace Status
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}📦 Namespace Status${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get namespace "$NAMESPACE" -o wide 2>/dev/null || echo "Namespace not found"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# DISPLAY: Pod Status
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}🐳 Pod Status${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
if [ "$PODS" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No pods running${NC}"
else
    RUNNING=$(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    echo -e "Total Pods:   $PODS"
    echo -e "Running:      ${GREEN}$RUNNING${NC}"
    if [ "$RUNNING" -lt "$PODS" ]; then
        NOT_READY=$((PODS - RUNNING))
        echo -e "Not Ready:    ${YELLOW}$NOT_READY${NC}"
    fi
fi
echo ""
kubectl get pods -n "$NAMESPACE" -o wide 2>/dev/null || true
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# DISPLAY: Deployment Status
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}🚀 Deployment Status${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get deployments -n "$NAMESPACE" -o wide 2>/dev/null || echo "No deployments found"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# DISPLAY: Service Status
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}🌐 Service Status${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get svc -n "$NAMESPACE" -o wide 2>/dev/null || echo "No services found"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# DISPLAY: Frontend Access
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}📡 Frontend Access${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
FRONTEND_IP=$(kubectl get svc frontend -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ ! -z "$FRONTEND_IP" ]; then
    echo -e "${GREEN}✅ Frontend URL: http://$FRONTEND_IP${NC}"
    
    # Test connectivity
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$FRONTEND_IP" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✅ Frontend responding (HTTP $HTTP_CODE)${NC}"
    else
        echo -e "${YELLOW}⚠️  Frontend HTTP $HTTP_CODE${NC}"
    fi
else
    echo -e "${YELLOW}⏳ LoadBalancer IP pending${NC}"
    echo -e "   (normal on first deployment, check again in 1-5 min)"
fi
echo ""

# Check recent events
echo -e "${BLUE}📋 Recent Events${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10
echo ""

# Health summary
echo -e "${BLUE}💚 Health Summary${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check each component
BACKEND_READY=$(kubectl get deployment backend -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)
FRONTEND_READY=$(kubectl get deployment frontend -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)

if [ "$BACKEND_READY" = "True" ]; then
    echo -e "Backend:  ${GREEN}✅ Ready${NC}"
else
    echo -e "Backend:  ${YELLOW}⚠️  Not Ready${NC}"
fi

if [ "$FRONTEND_READY" = "True" ]; then
    echo -e "Frontend: ${GREEN}✅ Ready${NC}"
else
    echo -e "Frontend: ${YELLOW}⚠️  Not Ready${NC}"
fi

# Note about Cloud SQL connection
echo -e ""
echo -e "${CYAN}🗄️  Database:${NC} Using direct Cloud SQL IP (35.202.121.162)"
echo -e "${CYAN}   📝 TODO:${NC} Setup Cloud SQL Proxy for production"
echo -e "${CYAN}   📖 Guide:${NC} docs/guides/CLOUD_SQL_PROXY_SETUP.md"
echo ""
echo "Quick commands:"
echo "  kubectl logs -n $NAMESPACE -l app=backend -f"
echo ""
echo "Test API:"
echo "  curl http://<IP>/api/results"
echo ""
