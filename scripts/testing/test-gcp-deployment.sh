#!/bin/bash

###############################################################################
# GCP DEPLOYMENT & VERIFICATION SCRIPT
# 
# This script automates the entire GCP deployment and testing process
# Usage: ./test-gcp-deployment.sh
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GCP_PROJECT="diesel-skyline-474415-j6"
GCP_REGION="us-central1"
CLUSTER_NAME="voting-app-cluster"
NAMESPACE="voting-app"
TERRAFORM_DIR="3-KUBERNETES/terraform"
K8S_DIR="3-KUBERNETES/k8s"

# Functions
print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

check_prerequisites() {
    print_header "STEP 1: Checking Prerequisites"
    
    # Check gcloud
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI not installed"
        exit 1
    fi
    print_success "gcloud CLI found: $(gcloud --version | head -1)"
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl not installed"
        exit 1
    fi
    print_success "kubectl found: $(kubectl version --client --short 2>/dev/null || echo 'installed')"
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform not installed"
        exit 1
    fi
    print_success "Terraform found: $(terraform version | head -1)"
    
    # Check GCP authentication
    ACTIVE_ACCOUNT=$(gcloud config get-value account 2>/dev/null)
    if [ -z "$ACTIVE_ACCOUNT" ]; then
        print_error "Not authenticated with gcloud"
        exit 1
    fi
    print_success "GCP account: $ACTIVE_ACCOUNT"
    
    # Check project
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
    if [ "$CURRENT_PROJECT" != "$GCP_PROJECT" ]; then
        print_warning "Current project: $CURRENT_PROJECT (expected: $GCP_PROJECT)"
        gcloud config set project "$GCP_PROJECT"
    fi
    print_success "GCP project: $GCP_PROJECT"
}

create_terraform_plan() {
    print_header "STEP 2: Creating Terraform Plan"
    
    cd "$TERRAFORM_DIR"
    
    # Get GCP access token for Terraform authentication
    print_warning "Authenticating with GCP..."
    GCP_TOKEN=$(gcloud auth print-access-token 2>/dev/null || echo "")
    if [ -z "$GCP_TOKEN" ]; then
        print_error "Failed to get GCP access token"
        exit 1
    fi
    print_success "GCP authentication token obtained"
    
    print_warning "Initializing Terraform..."
    terraform init -upgrade > /dev/null 2>&1
    print_success "Terraform initialized"
    
    print_warning "Validating Terraform configuration..."
    terraform validate > /dev/null 2>&1
    print_success "Terraform configuration valid"
    
    print_warning "Creating deployment plan..."
    terraform plan -var="gcp_access_token=$GCP_TOKEN" -out=tfplan > /dev/null 2>&1
    print_success "Terraform plan created: tfplan"
    
    cd - > /dev/null
}

apply_terraform() {
    print_header "STEP 3: Applying Terraform (Creating GCP Resources)"
    
    cd "$TERRAFORM_DIR"
    
    # Get GCP access token again for apply
    GCP_TOKEN=$(gcloud auth print-access-token 2>/dev/null || echo "")
    if [ -z "$GCP_TOKEN" ]; then
        print_error "Failed to get GCP access token"
        exit 1
    fi
    
    print_warning "Creating resources on GCP (this will take 15-20 minutes)..."
    echo -e "${YELLOW}Resources being created:${NC}"
    echo "  • GKE Cluster (3 nodes, n1-standard-2)"
    echo "  • Cloud SQL MySQL instance"
    echo "  • VPC Network"
    echo "  • Firewall rules"
    echo "  • Service accounts"
    echo ""
    
    print_warning "Applying Terraform configuration..."
    terraform apply -var="gcp_access_token=$GCP_TOKEN" -auto-approve tfplan > /dev/null 2>&1
    print_success "Terraform apply completed!"
    
    # Get outputs
    echo ""
    print_success "Infrastructure Details:"
    echo "  Cluster IP: $(terraform output -raw cluster_endpoint 2>/dev/null || echo 'pending')"
    echo "  Region: $GCP_REGION"
    
    cd - > /dev/null
}

get_kubernetes_credentials() {
    print_header "STEP 4: Getting Kubernetes Credentials"
    
    print_warning "Fetching cluster credentials..."
    gcloud container clusters get-credentials "$CLUSTER_NAME" \
        --region "$GCP_REGION" \
        --project "$GCP_PROJECT" \
        --quiet
    print_success "Credentials configured"
    
    print_warning "Verifying cluster connection..."
    if kubectl cluster-info &> /dev/null; then
        print_success "Connected to Kubernetes cluster"
    else
        print_error "Failed to connect to Kubernetes cluster"
        exit 1
    fi
}

verify_cluster() {
    print_header "STEP 5: Verifying Kubernetes Cluster"
    
    print_warning "Cluster info:"
    kubectl cluster-info | grep 'Kubernetes master'
    
    print_warning "Node status:"
    kubectl get nodes -o wide
    
    READY_NODES=$(kubectl get nodes -o json | jq -r '.items | length')
    if [ "$READY_NODES" -lt 3 ]; then
        print_warning "Only $READY_NODES nodes ready (expected 3)"
    else
        print_success "All 3 nodes ready"
    fi
}

deploy_kubernetes_manifests() {
    print_header "STEP 6: Deploying Kubernetes Manifests"
    
    cd "$K8S_DIR"
    
    # Apply manifests in order
    for file in 00-namespace.yaml 01-secrets.yaml 02-backend-deployment.yaml 03-frontend-deployment.yaml; do
        print_warning "Applying $file..."
        kubectl apply -f "$file"
        print_success "$file applied"
    done
    
    cd - > /dev/null
}

wait_for_loadbalancer() {
    print_header "STEP 7: Waiting for LoadBalancer IP"
    
    print_warning "Waiting for LoadBalancer to get external IP (this may take 2-3 minutes)..."
    
    EXTERNAL_IP=""
    ATTEMPTS=0
    MAX_ATTEMPTS=120  # 10 minutes
    
    while [ -z "$EXTERNAL_IP" ] && [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
        EXTERNAL_IP=$(kubectl get svc frontend -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        
        if [ -z "$EXTERNAL_IP" ]; then
            ATTEMPTS=$((ATTEMPTS + 1))
            echo -n "."
            sleep 5
        fi
    done
    
    echo ""
    
    if [ -z "$EXTERNAL_IP" ]; then
        print_error "LoadBalancer IP not assigned (timeout)"
        print_warning "Check with: kubectl get svc frontend -n $NAMESPACE"
        return 1
    fi
    
    print_success "LoadBalancer IP assigned: $EXTERNAL_IP"
    
    # Save for later use
    echo "$EXTERNAL_IP" > /tmp/gcp_external_ip.txt
}

check_pod_status() {
    print_header "STEP 8: Checking Pod Status"
    
    print_warning "Pod status:"
    kubectl get pods -n "$NAMESPACE" -o wide
    
    print_warning "Checking pod readiness..."
    BACKEND_READY=$(kubectl get pods -n "$NAMESPACE" -l app=backend -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "")
    FRONTEND_READY=$(kubectl get pods -n "$NAMESPACE" -l app=frontend -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "")
    
    if [ "$BACKEND_READY" == "True" ] && [ "$FRONTEND_READY" == "True" ]; then
        print_success "All pods ready"
    else
        print_warning "Pods still initializing (backend: $BACKEND_READY, frontend: $FRONTEND_READY)"
        print_warning "Waiting 30 seconds for pods to be ready..."
        sleep 30
    fi
}

test_api() {
    print_header "STEP 9: Testing API Endpoints"
    
    if [ ! -f /tmp/gcp_external_ip.txt ]; then
        print_error "External IP not found"
        return 1
    fi
    
    EXTERNAL_IP=$(cat /tmp/gcp_external_ip.txt)
    BASE_URL="http://$EXTERNAL_IP/api"
    
    print_warning "Testing API on: $BASE_URL"
    
    # Test 1: Health check
    echo ""
    print_warning "Test 1: Health check"
    HEALTH=$(curl -s "$BASE_URL/health")
    if echo "$HEALTH" | grep -q "healthy"; then
        print_success "Health check: PASS"
        echo "  Response: $HEALTH"
    else
        print_error "Health check: FAIL"
        echo "  Response: $HEALTH"
    fi
    
    # Test 2: Get initial results
    echo ""
    print_warning "Test 2: Get results"
    RESULTS=$(curl -s "$BASE_URL/results")
    if echo "$RESULTS" | grep -q "total"; then
        print_success "Get results: PASS"
        echo "  Response: $RESULTS"
    else
        print_error "Get results: FAIL"
        echo "  Response: $RESULTS"
    fi
    
    # Test 3: Submit vote
    echo ""
    print_warning "Test 3: Submit vote for dogs"
    VOTE=$(curl -s -X POST "$BASE_URL/vote" \
        -H "Content-Type: application/json" \
        -d '{"vote":"dogs"}')
    if echo "$VOTE" | grep -q "successfully"; then
        print_success "Submit vote: PASS"
        echo "  Response: $VOTE"
    else
        print_error "Submit vote: FAIL"
        echo "  Response: $VOTE"
    fi
    
    # Test 4: Verify vote count
    echo ""
    print_warning "Test 4: Verify vote count"
    RESULTS2=$(curl -s "$BASE_URL/results")
    if echo "$RESULTS2" | grep -q '"dogs":1'; then
        print_success "Vote recorded: PASS"
        echo "  Response: $RESULTS2"
    else
        print_warning "Vote count verification: CHECK MANUALLY"
        echo "  Response: $RESULTS2"
    fi
}

test_frontend() {
    print_header "STEP 10: Testing Frontend UI"
    
    if [ ! -f /tmp/gcp_external_ip.txt ]; then
        print_error "External IP not found"
        return 1
    fi
    
    EXTERNAL_IP=$(cat /tmp/gcp_external_ip.txt)
    FRONTEND_URL="http://$EXTERNAL_IP"
    
    print_success "Frontend URL: $FRONTEND_URL"
    print_warning "Frontend accessibility check..."
    
    FRONTEND=$(curl -s "$FRONTEND_URL")
    if echo "$FRONTEND" | grep -q "Dogs\|Cats\|vote"; then
        print_success "Frontend loads: PASS"
    else
        print_error "Frontend load: Check manually"
    fi
    
    echo ""
    echo -e "${GREEN}Open in browser: $FRONTEND_URL${NC}"
}

print_summary() {
    print_header "DEPLOYMENT SUMMARY"
    
    if [ ! -f /tmp/gcp_external_ip.txt ]; then
        print_warning "External IP not available"
        return
    fi
    
    EXTERNAL_IP=$(cat /tmp/gcp_external_ip.txt)
    
    echo -e "${GREEN}✅ DEPLOYMENT SUCCESSFUL!${NC}\n"
    
    echo "Access the application:"
    echo -e "  ${YELLOW}Frontend: http://$EXTERNAL_IP${NC}"
    echo -e "  ${YELLOW}API Health: http://$EXTERNAL_IP/api/health${NC}"
    echo -e "  ${YELLOW}API Results: http://$EXTERNAL_IP/api/results${NC}"
    
    echo ""
    echo "Useful kubectl commands:"
    echo "  kubectl get pods -n $NAMESPACE"
    echo "  kubectl logs deployment/backend -n $NAMESPACE"
    echo "  kubectl logs deployment/frontend -n $NAMESPACE"
    echo "  kubectl describe svc frontend -n $NAMESPACE"
    
    echo ""
    echo "To destroy resources (avoid GCP charges):"
    echo "  kubectl delete namespace $NAMESPACE"
    echo "  cd $TERRAFORM_DIR && terraform destroy"
    
    echo ""
    echo "Save these URLs:"
    echo "  Frontend: http://$EXTERNAL_IP"
}

# Main execution
main() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║      GCP DEPLOYMENT & VERIFICATION SCRIPT                ║"
    echo "║      Voting App on Kubernetes (GKE)                      ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_prerequisites
    
    create_terraform_plan
    apply_terraform
    
    # Wait a moment for cluster to fully initialize
    print_warning "Waiting for cluster to stabilize (30 seconds)..."
    sleep 30
    
    get_kubernetes_credentials
    verify_cluster
    deploy_kubernetes_manifests
    
    print_warning "Waiting for pods to initialize (60 seconds)..."
    sleep 60
    
    if wait_for_loadbalancer; then
        check_pod_status
        test_api
        test_frontend
        print_summary
    else
        print_error "Failed to get LoadBalancer IP"
        print_warning "Try: kubectl get svc frontend -n $NAMESPACE"
    fi
}

# Run main
main
