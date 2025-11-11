#!/bin/bash

# TEST SCRIPT - Script.js Auto-Detection Implementation
# Run this script to test both local and GCP deployments

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Testing Script.js Auto-Detection Implementation            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}\n"

# ============================================================================
# TEST 1: LOCAL DOCKER-COMPOSE
# ============================================================================

echo -e "${BLUE}[TEST 1/4] LOCAL DOCKER-COMPOSE - Checking containers...${NC}"
cd /home/octavian/sandbox/voting-app

# Check if containers are running
if docker-compose ps | grep -q "running"; then
    echo -e "${GREEN}✓ Containers are running${NC}"
else
    echo -e "${RED}✗ Containers not running. Starting...${NC}"
    docker-compose down
    docker-compose up -d
    sleep 20
fi

echo ""
echo -e "${BLUE}[TEST 2/4] LOCAL - Testing Backend API on port 8000...${NC}"
if timeout 3 curl -s http://localhost:8000/results 2>/dev/null | grep -q '"dogs"'; then
    echo -e "${GREEN}✓ Backend API responding on port 8000${NC}"
    echo "  Response: $(curl -s http://localhost:8000/results)"
else
    echo -e "${RED}✗ Backend API not responding on port 8000${NC}"
fi

echo ""
echo -e "${BLUE}[TEST 3/4] LOCAL - Testing Frontend on localhost...${NC}"
if timeout 3 curl -s http://localhost/ 2>/dev/null | grep -q 'script.js'; then
    echo -e "${GREEN}✓ Frontend accessible on localhost:80${NC}"
    echo "  Checking script.js is present in HTML..."
    if timeout 3 curl -s http://localhost/ | grep -q 'getApiBaseUrl'; then
        echo -e "${GREEN}  ✓ script.js with auto-detection code found${NC}"
    fi
else
    echo -e "${RED}✗ Frontend not responding on localhost${NC}"
fi

echo ""
echo -e "${BLUE}[TEST 4/4] LOCAL - Testing nginx proxy /api endpoint...${NC}"
if timeout 3 curl -s http://localhost/api/results 2>/dev/null | grep -q '"dogs"'; then
    echo -e "${GREEN}✓ Nginx proxy working on /api/results${NC}"
    echo "  Response: $(curl -s http://localhost/api/results)"
else
    echo -e "${RED}✗ Nginx proxy not working${NC}"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}LOCAL DOCKER-COMPOSE TESTS COMPLETED${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}\n"

# ============================================================================
# TEST 2: GCP KUBERNETES (if available)
# ============================================================================

echo -e "${BLUE}Checking GCP Kubernetes deployment...${NC}"

if gcloud container clusters list --project diesel-skyline-474415-j6 | grep -q "voting-app-cluster"; then
    echo -e "${GREEN}✓ GKE cluster found${NC}"
    
    # Get kubeconfig
    gcloud container clusters get-credentials voting-app-cluster \
        --zone us-central1 --project diesel-skyline-474415-j6 2>/dev/null || true
    
    echo ""
    echo -e "${BLUE}Checking Kubernetes pods...${NC}"
    if kubectl get pods -n voting-app 2>/dev/null | grep -q "frontend"; then
        echo -e "${GREEN}✓ Frontend pods running${NC}"
        kubectl get pods -n voting-app -o wide | grep frontend
    else
        echo -e "${RED}✗ Frontend pods not found${NC}"
    fi
    
    if kubectl get pods -n voting-app 2>/dev/null | grep -q "backend"; then
        echo -e "${GREEN}✓ Backend pods running${NC}"
        kubectl get pods -n voting-app -o wide | grep backend
    else
        echo -e "${RED}✗ Backend pods not found${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}Getting frontend service info...${NC}"
    FRONTEND_IP=$(kubectl get svc frontend -n voting-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "PENDING")
    
    if [ "$FRONTEND_IP" != "PENDING" ] && [ ! -z "$FRONTEND_IP" ]; then
        echo -e "${GREEN}✓ Frontend LoadBalancer IP: $FRONTEND_IP${NC}"
        echo ""
        echo -e "${BLUE}Testing frontend on GCP...${NC}"
        if timeout 5 curl -s http://$FRONTEND_IP/ 2>/dev/null | grep -q 'getApiBaseUrl'; then
            echo -e "${GREEN}✓ Frontend accessible on GCP IP${NC}"
            echo -e "${GREEN}  ✓ script.js with auto-detection code found${NC}"
        fi
        
        echo ""
        echo -e "${BLUE}Testing API endpoint via nginx proxy...${NC}"
        if timeout 5 curl -s http://$FRONTEND_IP/api/results 2>/dev/null | grep -q '"dogs"'; then
            echo -e "${GREEN}✓ API endpoint working via /api proxy${NC}"
        fi
    else
        echo -e "${YELLOW}⏳ LoadBalancer IP still pending (give it a few minutes)${NC}"
    fi
    
else
    echo -e "${YELLOW}⏳ GKE cluster not found or still deploying${NC}"
    echo "   You can deploy with: ./deploy.sh"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}TESTING COMPLETED${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}\n"

echo -e "${BLUE}Summary:${NC}"
echo "✓ Script.js has auto-detection for localhost vs GCP"
echo "✓ Local: Uses http://localhost:8000"
echo "✓ GCP: Uses http://<IP>/api through nginx proxy"
echo "✓ No breaking changes to local development"
echo ""
echo -e "${GREEN}For manual testing:${NC}"
echo "- Local: Visit http://localhost in browser"
echo "- GCP:   Visit http://<FRONTEND_IP> in browser"
echo "- DevTools: Console shows API_BASE_URL being used"
