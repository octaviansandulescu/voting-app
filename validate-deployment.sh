#!/bin/bash

# ============================================================================
# GCP Deployment Validation Script
# ============================================================================
# This script validates that the entire voting app deployment is working
# Run: ./validate-deployment.sh
# ============================================================================

set -e

FRONTEND_IP="34.42.155.47"
API_URL="http://$FRONTEND_IP"

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║          GCP Deployment Validation Test Suite                          ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASS=0
FAIL=0

# Function to print test result
test_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC}: $1"
        ((PASS++))
    else
        echo -e "${RED}❌ FAIL${NC}: $1"
        ((FAIL++))
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Testing Connectivity"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test frontend connectivity
ping -c 1 -W 2 $FRONTEND_IP > /dev/null 2>&1
test_result "Frontend IP is reachable"

# Test HTTP connectivity
curl -s -o /dev/null -w "%{http_code}" $API_URL | grep -q "200"
test_result "Frontend HTTP port is responding"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Testing API Endpoints"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test health endpoint
HEALTH_RESPONSE=$(curl -s $API_URL/api/health)
echo -n "Health endpoint response: "
echo "$HEALTH_RESPONSE" | grep -q "ok" && echo "${GREEN}✅ OK${NC}" && ((PASS++)) || (echo "${RED}❌ FAIL${NC}" && ((FAIL++)))

# Test results endpoint
RESULTS_RESPONSE=$(curl -s $API_URL/api/results)
echo -n "Results endpoint response: "
echo "$RESULTS_RESPONSE" | grep -q "dogs" && echo "${GREEN}✅ OK${NC}" && ((PASS++)) || (echo "${RED}❌ FAIL${NC}" && ((FAIL++)))

# Test health returns valid JSON
echo -n "Health endpoint returns valid JSON: "
echo "$HEALTH_RESPONSE" | python3 -m json.tool > /dev/null 2>&1 && echo "${GREEN}✅ OK${NC}" && ((PASS++)) || (echo "${RED}❌ FAIL${NC}" && ((FAIL++)))

# Test results returns valid JSON
echo -n "Results endpoint returns valid JSON: "
echo "$RESULTS_RESPONSE" | python3 -m json.tool > /dev/null 2>&1 && echo "${GREEN}✅ OK${NC}" && ((PASS++)) || (echo "${RED}❌ FAIL${NC}" && ((FAIL++)))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Testing Vote Submission"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get current results
INITIAL_DOGS=$(echo "$RESULTS_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('dogs', 0))" 2>/dev/null || echo "0")

# Submit a vote for dogs
VOTE_RESPONSE=$(curl -s -X POST $API_URL/api/vote \
  -H "Content-Type: application/json" \
  -d '{"vote":"dogs"}')

echo "Vote submission response:"
echo "$VOTE_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$VOTE_RESPONSE"

# Check if vote was recorded
echo -n "Vote recorded in database: "
sleep 1
NEW_RESULTS=$(curl -s $API_URL/api/results)
NEW_DOGS=$(echo "$NEW_RESULTS" | python3 -c "import sys, json; print(json.load(sys.stdin).get('dogs', 0))" 2>/dev/null || echo "0")

if [ $((NEW_DOGS)) -gt $((INITIAL_DOGS)) ]; then
    echo "${GREEN}✅ YES${NC}"
    ((PASS++))
else
    echo "${RED}❌ NO${NC}"
    ((FAIL++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Testing Frontend HTML"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

FRONTEND_HTML=$(curl -s $API_URL/)

echo -n "Frontend page loads: "
echo "$FRONTEND_HTML" | grep -q "<!DOCTYPE html" && echo "${GREEN}✅ OK${NC}" && ((PASS++)) || (echo "${RED}❌ FAIL${NC}" && ((FAIL++)))

echo -n "Frontend contains voting UI: "
echo "$FRONTEND_HTML" | grep -q "Vote Dogs" && echo "${GREEN}✅ OK${NC}" && ((PASS++)) || (echo "${RED}❌ FAIL${NC}" && ((FAIL++)))

echo -n "Frontend has results display: "
echo "$FRONTEND_HTML" | grep -q "Live Results" && echo "${GREEN}✅ OK${NC}" && ((PASS++)) || (echo "${RED}❌ FAIL${NC}" && ((FAIL++)))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Testing Kubernetes Resources"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -n "Frontend pods running: "
FRONTEND_PODS=$(kubectl get pods -n voting-app -l app=frontend --no-headers 2>/dev/null | wc -l)
if [ "$FRONTEND_PODS" -ge 1 ]; then
    echo "${GREEN}✅ $FRONTEND_PODS running${NC}"
    ((PASS++))
else
    echo "${RED}❌ None running${NC}"
    ((FAIL++))
fi

echo -n "Backend pods running: "
BACKEND_PODS=$(kubectl get pods -n voting-app -l app=backend --no-headers 2>/dev/null | wc -l)
if [ "$BACKEND_PODS" -ge 1 ]; then
    echo "${GREEN}✅ $BACKEND_PODS running${NC}"
    ((PASS++))
else
    echo "${RED}❌ None running${NC}"
    ((FAIL++))
fi

echo -n "Frontend service has external IP: "
EXTERNAL_IP=$(kubectl get svc frontend-service -n voting-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
if [ ! -z "$EXTERNAL_IP" ]; then
    echo "${GREEN}✅ $EXTERNAL_IP${NC}"
    ((PASS++))
else
    echo "${RED}❌ No external IP assigned${NC}"
    ((FAIL++))
fi

echo -n "Backend service has ClusterIP: "
CLUSTER_IP=$(kubectl get svc backend-service -n voting-app -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "")
if [ ! -z "$CLUSTER_IP" ]; then
    echo "${GREEN}✅ $CLUSTER_IP${NC}"
    ((PASS++))
else
    echo "${RED}❌ No ClusterIP assigned${NC}"
    ((FAIL++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Test Results Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TOTAL=$((PASS + FAIL))
echo "Total Tests: $TOTAL"
echo -e "Passed: ${GREEN}$PASS${NC}"
echo -e "Failed: ${RED}$FAIL${NC}"

if [ $FAIL -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ ALL TESTS PASSED - DEPLOYMENT IS FULLY OPERATIONAL!   ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Your voting app is live and ready to use!"
    echo "Access it at: http://$FRONTEND_IP"
    echo ""
    exit 0
else
    echo ""
    echo -e "${RED}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ❌ SOME TESTS FAILED - PLEASE CHECK THE ERRORS ABOVE    ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 1
fi
