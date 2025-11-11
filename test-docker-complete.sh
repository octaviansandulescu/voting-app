#!/bin/bash

###############################################################################
#  DOCKER TEST SCRIPT - TESTING VOTING APP WITH DOCKER
#  
#  Acest script va testa aplicatia in modul DOCKER
#  cu verificari pas cu pas
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
STEP=0

# Helper functions
print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_step() {
    ((STEP++))
    echo -e "${YELLOW}[STEP $STEP] $1${NC}"
}

print_check() {
    echo -n "  ✓ $1 ... "
}

print_pass() {
    echo -e "${GREEN}PASS${NC}"
    ((TESTS_PASSED++))
}

print_fail() {
    echo -e "${RED}FAIL${NC}: $1"
    ((TESTS_FAILED++))
}

test_file_exists() {
    local file=$1
    local description=$2
    print_check "$description"
    if [ -f "$file" ] || [ -d "$file" ]; then
        print_pass
    else
        print_fail "File/Directory not found: $file"
    fi
}

test_command() {
    local description=$1
    local command=$2
    print_check "$description"
    if eval "$command" > /dev/null 2>&1; then
        print_pass
    else
        print_fail "Command failed: $command"
    fi
}

# START
clear
print_header "🐳 DOCKER TEST SUITE - VOTING APP"

print_header "[FASE 1] VERIFICARE STRUCTURA FISIERELOR"

print_step "Verifica fisierele necesare"
test_file_exists "docker-compose.yml" "docker-compose.yml exists"
test_file_exists "src/backend" "src/backend directory"
test_file_exists "src/backend/main.py" "src/backend/main.py"
test_file_exists "src/backend/requirements.txt" "src/backend/requirements.txt"
test_file_exists "src/backend/Dockerfile" "src/backend/Dockerfile"
test_file_exists "src/frontend" "src/frontend directory"
test_file_exists "src/frontend/index.html" "src/frontend/index.html"
test_file_exists "src/frontend/Dockerfile" "src/frontend/Dockerfile"
test_file_exists "src/frontend/script.js" "src/frontend/script.js"
test_file_exists ".gitignore" ".gitignore exists"

echo ""

print_header "[FASE 2] VERIFICARE DOCKER INSTALLATION"

print_step "Verifica Docker tools"
test_command "Docker installed" "command -v docker"
test_command "Docker daemon running" "docker ps > /dev/null 2>&1"
test_command "docker-compose installed" "command -v docker-compose"

echo ""

print_header "[FASE 3] VERIFICARE DOCKER-COMPOSE SYNTAX"

print_step "Verifica docker-compose.yml"
test_command "docker-compose.yml is valid YAML" "docker-compose config > /dev/null"
test_command "docker-compose has services" "grep -q 'services:' docker-compose.yml"
test_command "docker-compose has 'frontend' service" "docker-compose config | grep -q 'frontend'"
test_command "docker-compose has 'backend' service" "docker-compose config | grep -q 'backend'"
test_command "docker-compose has 'db' service" "docker-compose config | grep -q 'db'"

echo ""

print_header "[FASE 4] VERIFICARE CODUL"

print_step "Verifica codul backend"
test_command "main.py has FastAPI" "grep -q 'FastAPI' src/backend/main.py"
test_command "main.py has /vote endpoint" "grep -q '@app.post' src/backend/main.py"
test_command "main.py has /results endpoint" "grep -q '@app.get' src/backend/main.py"
test_command "main.py has /health endpoint" "grep -q 'health' src/backend/main.py"

print_step "Verifica codul frontend"
test_command "index.html has voting UI" "grep -q 'Dogs\|Cats\|button' src/frontend/index.html"
test_command "script.js has fetch" "grep -q 'fetch' src/frontend/script.js"
test_command "style.css exists" "test -f src/frontend/style.css && wc -l src/frontend/style.css | awk '{print \$1}' | grep -q ."

echo ""

print_header "[FASE 5] BUILD DOCKER IMAGES"

print_step "Build Docker images"
echo "  Aceasta poate dura cateva minute..."
if docker-compose build > /tmp/docker_build.log 2>&1; then
    echo -e "  ${GREEN}✓${NC} Build successful"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}✗${NC} Build failed"
    echo "  Logs:"
    tail -20 /tmp/docker_build.log
    ((TESTS_FAILED++))
fi

echo ""

print_header "[FASE 6] START CONTAINERS"

print_step "Start containers with docker-compose"
if docker-compose up -d > /tmp/docker_up.log 2>&1; then
    echo -e "  ${GREEN}✓${NC} Containers started"
    ((TESTS_PASSED++))
    
    # Wait for services to be ready
    echo "  Waiting 10 seconds for services to initialize..."
    sleep 10
else
    echo -e "  ${RED}✗${NC} Failed to start containers"
    echo "  Logs:"
    tail -20 /tmp/docker_up.log
    ((TESTS_FAILED++))
    exit 1
fi

echo ""

print_header "[FASE 7] VERIFICA CONTAINER STATUS"

print_step "Verifica container status"
echo "  Running: docker-compose ps"
docker-compose ps
echo ""

test_command "All containers are running" "[ \$(docker-compose ps --services --filter 'status=running' | wc -l) -eq 3 ]"

echo ""

print_header "[FASE 8] VERIFICA DATABASE CONNECTION"

print_step "Verifica MySQL"
if docker-compose exec -T db mysql -u root -ppassword -e "SELECT 1" > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} MySQL connected"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}✗${NC} MySQL connection failed"
    ((TESTS_FAILED++))
fi

echo ""

print_header "[FASE 9] TEST BACKEND API"

print_step "Test /health endpoint"
if curl -s http://localhost:8000/health | grep -q "ok"; then
    echo -e "  ${GREEN}✓${NC} /health endpoint working"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}✗${NC} /health endpoint failed"
    echo "  Response: $(curl -s http://localhost:8000/health)"
    ((TESTS_FAILED++))
fi

print_step "Test /results endpoint (initial)"
INITIAL_RESULTS=$(curl -s http://localhost:8000/results)
echo "  Response: $INITIAL_RESULTS"
if echo "$INITIAL_RESULTS" | grep -q "dogs\|cats"; then
    echo -e "  ${GREEN}✓${NC} /results endpoint working"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}✗${NC} /results endpoint failed"
    ((TESTS_FAILED++))
fi

print_step "Test POST /vote endpoint"
VOTE_RESPONSE=$(curl -s -X POST http://localhost:8000/vote \
  -H "Content-Type: application/json" \
  -d '{"vote":"dogs"}')
echo "  Response: $VOTE_RESPONSE"
if echo "$VOTE_RESPONSE" | grep -q "success\|recorded"; then
    echo -e "  ${GREEN}✓${NC} Vote recorded"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}✗${NC} Vote submission failed"
    ((TESTS_FAILED++))
fi

print_step "Test /results endpoint (after vote)"
AFTER_VOTE=$(curl -s http://localhost:8000/results)
echo "  Response: $AFTER_VOTE"
if echo "$AFTER_VOTE" | grep -q '"dogs":1'; then
    echo -e "  ${GREEN}✓${NC} Vote counted correctly"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}✗${NC} Vote not reflected in results"
    ((TESTS_FAILED++))
fi

echo ""

print_header "[FASE 10] TEST FRONTEND"

print_step "Test frontend accessibility"
if curl -s http://localhost | grep -q "Dogs\|Cats\|vote"; then
    echo -e "  ${GREEN}✓${NC} Frontend HTML loaded"
    ((TESTS_PASSED++))
else
    echo -e "  ${RED}✗${NC} Frontend not accessible"
    ((TESTS_FAILED++))
fi

echo ""

print_header "[FASE 11] LOGS INSPECTION"

print_step "Check backend logs"
echo "  Backend logs (last 10 lines):"
docker-compose logs backend | tail -10

print_step "Check frontend logs"
echo "  Frontend logs (last 5 lines):"
docker-compose logs frontend | tail -5

echo ""

print_header "[FASE 12] CLEANUP"

print_step "Stop containers"
docker-compose stop
echo -e "  ${GREEN}✓${NC} Containers stopped"

print_step "Stop and remove containers & volumes"
docker-compose down -v
echo -e "  ${GREEN}✓${NC} Cleaned up"

echo ""

# SUMMARY
print_header "📊 TEST SUMMARY"

echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review the test results above"
    echo "  2. If all passed, DOCKER mode is working!"
    echo "  3. Ready for KUBERNETES testing"
    exit 0
else
    echo -e "${RED}❌ SOME TESTS FAILED${NC}"
    echo ""
    echo "Debug steps:"
    echo "  1. Check logs: docker-compose logs"
    echo "  2. Re-run docker-compose up (without -d) to see errors"
    echo "  3. Check if ports 80, 8000, 3306 are available"
    exit 1
fi
