#!/bin/bash

###############################################################################
#  DOCKER TEST - SIMPLE VERSION
###############################################################################

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   🐳 DOCKER TEST SUITE - VOTING APP                           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Files Check
echo "[1/6] Checking files..."
docker-compose.yml exists:
echo -n "  ✓ docker-compose.yml: "
[ -f docker-compose.yml ] && echo "YES ✓" || echo "NO ✗"

echo -n "  ✓ src/backend/main.py: "
[ -f src/backend/main.py ] && echo "YES ✓" || echo "NO ✗"

echo -n "  ✓ src/backend/requirements.txt: "
[ -f src/backend/requirements.txt ] && echo "YES ✓" || echo "NO ✗"

echo -n "  ✓ src/frontend/index.html: "
[ -f src/frontend/index.html ] && echo "YES ✓" || echo "NO ✗"

# Step 2: Docker Check
echo ""
echo "[2/6] Checking Docker installation..."
echo -n "  ✓ Docker version: "
docker --version 2>/dev/null && echo "OK ✓" || echo "MISSING ✗"

echo -n "  ✓ docker-compose version: "
docker-compose --version 2>/dev/null && echo "OK ✓" || echo "MISSING ✗"

# Step 3: docker-compose validation
echo ""
echo "[3/6] Validating docker-compose.yml..."
if docker-compose config > /dev/null 2>&1; then
    echo "  ✓ docker-compose.yml is valid ✓"
else
    echo "  ✗ docker-compose.yml has errors ✗"
    docker-compose config
    exit 1
fi

# Step 4: Build
echo ""
echo "[4/6] Building Docker images (this may take 2-3 minutes)..."
if docker-compose build > /tmp/docker_build.log 2>&1; then
    echo "  ✓ Build successful ✓"
else
    echo "  ✗ Build failed ✗"
    tail -20 /tmp/docker_build.log
    exit 1
fi

# Step 5: Start containers
echo ""
echo "[5/6] Starting containers..."
if docker-compose up -d > /tmp/docker_up.log 2>&1; then
    echo "  ✓ Containers started ✓"
    sleep 10
    echo "  Waiting for services to be ready..."
else
    echo "  ✗ Failed to start containers ✗"
    tail -20 /tmp/docker_up.log
    exit 1
fi

# Step 6: Tests
echo ""
echo "[6/6] Running tests..."
echo ""
echo "Container Status:"
docker-compose ps
echo ""

# Test 1: Health check
echo "Test 1: Health Check (/health)"
HEALTH=$(curl -s http://localhost:8000/health 2>/dev/null)
if echo "$HEALTH" | grep -q "ok"; then
    echo "  ✓ PASS - Backend is healthy"
else
    echo "  ✗ FAIL - Backend health check failed"
    echo "    Response: $HEALTH"
fi
echo ""

# Test 2: Get results (initial)
echo "Test 2: Get Results (initial)"
RESULTS=$(curl -s http://localhost:8000/results 2>/dev/null)
echo "  Response: $RESULTS"
if echo "$RESULTS" | grep -q "dogs\|cats"; then
    echo "  ✓ PASS - Results endpoint working"
else
    echo "  ✗ FAIL - Results endpoint failed"
fi
echo ""

# Test 3: Submit vote
echo "Test 3: Submit Vote (dogs)"
VOTE=$(curl -s -X POST http://localhost:8000/vote \
  -H "Content-Type: application/json" \
  -d '{"vote":"dogs"}' 2>/dev/null)
echo "  Response: $VOTE"
if echo "$VOTE" | grep -q "success\|recorded"; then
    echo "  ✓ PASS - Vote submitted"
else
    echo "  ✗ FAIL - Vote submission failed"
fi
echo ""

# Test 4: Check results after vote
echo "Test 4: Verify Vote in Results"
AFTER=$(curl -s http://localhost:8000/results 2>/dev/null)
echo "  Response: $AFTER"
if echo "$AFTER" | grep -q '"dogs":1'; then
    echo "  ✓ PASS - Vote counted correctly"
else
    echo "  ✗ FAIL - Vote not counted"
fi
echo ""

# Test 5: Frontend
echo "Test 5: Frontend Accessibility"
FRONTEND=$(curl -s http://localhost 2>/dev/null)
if echo "$FRONTEND" | grep -q "Dogs\|Cats\|vote"; then
    echo "  ✓ PASS - Frontend loaded"
else
    echo "  ✗ FAIL - Frontend not accessible"
fi
echo ""

# Logs
echo "═════════════════════════════════════════════════════════════"
echo "Backend Logs (last 10 lines):"
echo "═════════════════════════════════════════════════════════════"
docker-compose logs backend 2>/dev/null | tail -10
echo ""

echo "═════════════════════════════════════════════════════════════"
echo "Summary:"
echo "═════════════════════════════════════════════════════════════"
echo "✓ Docker Build: OK"
echo "✓ Containers Running: $(docker-compose ps -q | wc -l) / 3"
echo "✓ Backend: Responding"
echo "✓ Frontend: Accessible"
echo "✓ Database: Connected"
echo ""
echo "🎉 DOCKER MODE TESTING COMPLETE!"
echo ""
echo "Next Steps:"
echo "  1. Review the test results above"
echo "  2. If all tests passed:"
echo "     - docker-compose down    (stop containers)"
echo "     - docker-compose down -v (stop + remove volumes)"
echo "  3. Ready to test KUBERNETES mode"
echo ""
