#!/bin/bash

###############################################################################
# GCP DEPLOYMENT STATUS SCRIPT
# 
# Shows status of all processes, resources, and deployment stages
# Usage: ./check-gcp-status.sh
#
# Checks:
#   - GCP infrastructure (GKE, SQL, VPC)
#   - Kubernetes cluster and pods
#   - Services and LoadBalancer IP
#   - Application health
#   - Database connectivity
#   - Costs and resource usage
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
GCP_PROJECT="diesel-skyline-474415-j6"
GCP_REGION="us-central1"
CLUSTER_NAME="voting-app-cluster"
NAMESPACE="voting-app"

# Helper functions
print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

print_section() {
    echo -e "\n${CYAN}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# Main checks
check_gcloud() {
    print_section "GCP CLI Status"
    
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud not installed"
        return 1
    fi
    print_success "gcloud installed"
    
    # Check authentication
    ACCOUNT=$(gcloud config get-value account 2>/dev/null || echo "")
    if [ -z "$ACCOUNT" ]; then
        print_error "Not authenticated with gcloud"
        return 1
    fi
    print_success "Authenticated as: $ACCOUNT"
    
    # Check project
    PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
    if [ "$PROJECT" != "$GCP_PROJECT" ]; then
        print_warning "Current project: $PROJECT (expected: $GCP_PROJECT)"
    else
        print_success "Project: $PROJECT"
    fi
}

check_gke_cluster() {
    print_section "GKE Cluster Status"
    
    # List clusters
    CLUSTERS=$(gcloud container clusters list --region=$GCP_REGION --project=$GCP_PROJECT 2>/dev/null || echo "")
    
    if [ -z "$CLUSTERS" ]; then
        print_error "No clusters found"
        print_info ""
        print_info "Cluster not yet deployed. To create it, run:"
        print_info "  ${CYAN}./test-gcp-deployment.sh${NC}"
        print_info ""
        print_info "This will:"
        print_info "  1. Create GKE cluster (3 nodes)"
        print_info "  2. Create Cloud SQL database"
        print_info "  3. Deploy voting app"
        print_info "  4. Set up services and LoadBalancer"
        print_info ""
        print_info "Time: ~20-25 minutes"
        print_info "Cost: ~$2 for testing"
        return 1
    fi
    
    # Check if voting-app-cluster exists
    if echo "$CLUSTERS" | grep -q "$CLUSTER_NAME"; then
        print_success "Cluster '$CLUSTER_NAME' exists"
        
        # Get cluster details
        CLUSTER_INFO=$(gcloud container clusters describe $CLUSTER_NAME \
            --region=$GCP_REGION \
            --project=$GCP_PROJECT \
            --format='value(status,location,currentMasterVersion,currentNodeCount)' 2>/dev/null)
        
        STATUS=$(echo "$CLUSTER_INFO" | awk '{print $1}')
        LOCATION=$(echo "$CLUSTER_INFO" | awk '{print $2}')
        VERSION=$(echo "$CLUSTER_INFO" | awk '{print $3}')
        NODE_COUNT=$(echo "$CLUSTER_INFO" | awk '{print $4}')
        
        if [ "$STATUS" = "RUNNING" ]; then
            print_success "Cluster status: $STATUS"
        else
            print_warning "Cluster status: $STATUS"
        fi
        
        print_info "Location: $LOCATION"
        print_info "Master version: $VERSION"
        print_info "Node count: $NODE_COUNT"
    else
        print_error "Cluster '$CLUSTER_NAME' not found"
        print_info ""
        print_info "Cluster not yet deployed. To create it, run:"
        print_info "  ${CYAN}./test-gcp-deployment.sh${NC}"
        print_info ""
        return 1
    fi
}

check_gke_nodes() {
    print_section "GKE Nodes Status"
    
    # Get node pool status
    NODES=$(gcloud container node-pools list --cluster=$CLUSTER_NAME \
        --region=$GCP_REGION \
        --project=$GCP_PROJECT \
        --format='table(name,config.machineType,initialNodeCount,status)' 2>/dev/null)
    
    if [ -z "$NODES" ]; then
        print_warning "Could not retrieve node information"
        return 1
    fi
    
    echo "$NODES"
}

check_cloud_sql() {
    print_section "Cloud SQL Status"
    
    # List Cloud SQL instances
    INSTANCES=$(gcloud sql instances list --project=$GCP_PROJECT 2>/dev/null || echo "")
    
    if [ -z "$INSTANCES" ]; then
        print_warning "No Cloud SQL instances found"
        return 1
    fi
    
    # Check for voting-app database instance
    if echo "$INSTANCES" | grep -q "voting-app"; then
        print_success "Cloud SQL instance found"
        echo "$INSTANCES" | grep "voting-app"
        
        # Get instance details
        INSTANCE_NAME=$(echo "$INSTANCES" | grep "voting-app" | awk '{print $1}')
        if [ ! -z "$INSTANCE_NAME" ]; then
            INSTANCE_STATUS=$(gcloud sql instances describe $INSTANCE_NAME \
                --project=$GCP_PROJECT \
                --format='value(state,databaseVersion,currentDiskSize)' 2>/dev/null)
            
            STATE=$(echo "$INSTANCE_STATUS" | awk '{print $1}')
            DBVERSION=$(echo "$INSTANCE_STATUS" | awk '{print $2}')
            DISKSIZE=$(echo "$INSTANCE_STATUS" | awk '{print $3}')
            
            if [ "$STATE" = "RUNNABLE" ]; then
                print_success "Instance state: $STATE"
            else
                print_warning "Instance state: $STATE"
            fi
            
            print_info "Database version: $DBVERSION"
            print_info "Disk size: $DISKSIZE"
        fi
    else
        print_warning "Cloud SQL instance 'voting-app' not found"
    fi
}

check_kubernetes() {
    print_section "Kubernetes Cluster Info"
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        print_warning "Try: gcloud container clusters get-credentials $CLUSTER_NAME --region $GCP_REGION"
        return 1
    fi
    
    print_success "Connected to Kubernetes cluster"
    kubectl cluster-info | grep -E "Kubernetes|server"
}

check_namespace() {
    print_section "Kubernetes Namespace Status"
    
    # Check if namespace exists
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        print_success "Namespace '$NAMESPACE' exists"
        
        # Get namespace details
        NS_STATUS=$(kubectl get namespace $NAMESPACE -o json | jq -r '.status.phase' 2>/dev/null || echo "unknown")
        print_info "Status: $NS_STATUS"
    else
        print_error "Namespace '$NAMESPACE' not found"
        print_warning "Application not deployed yet"
        return 1
    fi
}

check_deployments() {
    print_section "Kubernetes Deployments"
    
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        print_warning "Namespace not found"
        return 1
    fi
    
    # Get deployment status
    DEPS=$(kubectl get deployments -n $NAMESPACE -o wide 2>/dev/null)
    
    if [ -z "$DEPS" ]; then
        print_warning "No deployments found"
        return 1
    fi
    
    echo "$DEPS"
    
    # Check backend deployment
    BACKEND=$(kubectl get deployment backend -n $NAMESPACE -o json 2>/dev/null)
    if [ ! -z "$BACKEND" ]; then
        BACKEND_READY=$(echo "$BACKEND" | jq -r '.status.readyReplicas // 0')
        BACKEND_DESIRED=$(echo "$BACKEND" | jq -r '.spec.replicas')
        
        if [ "$BACKEND_READY" = "$BACKEND_DESIRED" ]; then
            print_success "Backend: $BACKEND_READY/$BACKEND_DESIRED ready"
        else
            print_warning "Backend: $BACKEND_READY/$BACKEND_DESIRED ready"
        fi
    fi
    
    # Check frontend deployment
    FRONTEND=$(kubectl get deployment frontend -n $NAMESPACE -o json 2>/dev/null)
    if [ ! -z "$FRONTEND" ]; then
        FRONTEND_READY=$(echo "$FRONTEND" | jq -r '.status.readyReplicas // 0')
        FRONTEND_DESIRED=$(echo "$FRONTEND" | jq -r '.spec.replicas')
        
        if [ "$FRONTEND_READY" = "$FRONTEND_DESIRED" ]; then
            print_success "Frontend: $FRONTEND_READY/$FRONTEND_DESIRED ready"
        else
            print_warning "Frontend: $FRONTEND_READY/$FRONTEND_DESIRED ready"
        fi
    fi
}

check_pods() {
    print_section "Kubernetes Pods"
    
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        print_warning "Namespace not found"
        return 1
    fi
    
    # Get pod status
    PODS=$(kubectl get pods -n $NAMESPACE -o wide 2>/dev/null)
    
    if [ -z "$PODS" ]; then
        print_warning "No pods found"
        return 1
    fi
    
    echo "$PODS"
    
    # Count pod status
    RUNNING=$(kubectl get pods -n $NAMESPACE -o json 2>/dev/null | jq -r '.items[] | select(.status.phase=="Running") | .metadata.name' | wc -l)
    PENDING=$(kubectl get pods -n $NAMESPACE -o json 2>/dev/null | jq -r '.items[] | select(.status.phase=="Pending") | .metadata.name' | wc -l)
    FAILED=$(kubectl get pods -n $NAMESPACE -o json 2>/dev/null | jq -r '.items[] | select(.status.phase=="Failed") | .metadata.name' | wc -l)
    
    echo ""
    print_info "Running pods: $RUNNING"
    
    if [ $PENDING -gt 0 ]; then
        print_warning "Pending pods: $PENDING"
    fi
    
    if [ $FAILED -gt 0 ]; then
        print_error "Failed pods: $FAILED"
    fi
}

check_services() {
    print_section "Kubernetes Services & LoadBalancer"
    
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        print_warning "Namespace not found"
        return 1
    fi
    
    # Get services
    SERVICES=$(kubectl get services -n $NAMESPACE -o wide 2>/dev/null)
    
    if [ -z "$SERVICES" ]; then
        print_warning "No services found"
        return 1
    fi
    
    echo "$SERVICES"
    
    # Check LoadBalancer IP
    FRONTEND_IP=$(kubectl get svc frontend -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -z "$FRONTEND_IP" ]; then
        print_warning "LoadBalancer IP not yet assigned"
    else
        print_success "Frontend LoadBalancer IP: $FRONTEND_IP"
        print_info "Access frontend at: http://$FRONTEND_IP"
        print_info "API health: http://$FRONTEND_IP/api/health"
    fi
}

check_application_health() {
    print_section "Application Health"
    
    # Get LoadBalancer IP
    FRONTEND_IP=$(kubectl get svc frontend -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -z "$FRONTEND_IP" ]; then
        print_warning "LoadBalancer IP not assigned yet"
        return 1
    fi
    
    # Test health endpoint
    HEALTH=$(curl -s http://$FRONTEND_IP/api/health 2>/dev/null || echo "")
    
    if [ -z "$HEALTH" ]; then
        print_error "Cannot reach health endpoint"
        return 1
    fi
    
    if echo "$HEALTH" | grep -q "healthy"; then
        print_success "Backend health check: PASS"
        echo "  Response: $HEALTH"
    else
        print_warning "Backend health check response: $HEALTH"
    fi
    
    # Test results endpoint
    RESULTS=$(curl -s http://$FRONTEND_IP/api/results 2>/dev/null || echo "")
    
    if echo "$RESULTS" | grep -q "total"; then
        print_success "Results endpoint: PASS"
        echo "  Response: $RESULTS"
    else
        print_warning "Results endpoint: Could not verify"
    fi
}

check_resource_usage() {
    print_section "Resource Usage & Estimates"
    
    # Get GKE node count
    NODE_COUNT=$(gcloud container clusters describe $CLUSTER_NAME \
        --region=$GCP_REGION \
        --project=$GCP_PROJECT \
        --format='value(currentNodeCount)' 2>/dev/null || echo "0")
    
    # Get running time (approximation from cluster creation)
    CREATED_TIME=$(gcloud container clusters describe $CLUSTER_NAME \
        --region=$GCP_REGION \
        --project=$GCP_PROJECT \
        --format='value(createTime)' 2>/dev/null || echo "unknown")
    
    print_info "Cluster nodes: $NODE_COUNT"
    print_info "Created: $CREATED_TIME"
    
    # Cost estimation
    if [ "$NODE_COUNT" -gt 0 ]; then
        echo ""
        print_info "Cost Estimation:"
        
        # GKE pricing: ~$0.04-0.06 per node per hour
        HOURLY_COST=$(echo "scale=2; $NODE_COUNT * 0.05" | bc 2>/dev/null || echo "~0.15")
        DAILY_COST=$(echo "scale=2; $HOURLY_COST * 24" | bc 2>/dev/null || echo "~3.6")
        MONTHLY_COST=$(echo "scale=2; $DAILY_COST * 30" | bc 2>/dev/null || echo "~108")
        
        echo "  • Nodes: $NODE_COUNT × $0.05/hour = $HOURLY_COST/hour"
        echo "  • Daily (24h): ~$DAILY_COST"
        echo "  • Monthly: ~$MONTHLY_COST"
        echo "  • Cloud SQL: FREE (f1-micro tier)"
        echo ""
        print_warning "⚠️  Don't forget to cleanup when done!"
        echo "  Run: ./cleanup-gcp.sh"
    fi
}

check_persistent_volumes() {
    print_section "Persistent Volumes & Storage"
    
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        print_warning "Namespace not found"
        return 1
    fi
    
    # Get PVCs
    PVCS=$(kubectl get pvc -n $NAMESPACE -o wide 2>/dev/null)
    
    if [ -z "$PVCS" ]; then
        print_info "No persistent volumes"
        return 0
    fi
    
    echo "$PVCS"
}

show_summary() {
    print_header "STATUS SUMMARY"
    
    echo "Quick Action Guide:"
    echo ""
    echo "View detailed logs:"
    echo "  kubectl logs deployment/backend -n $NAMESPACE"
    echo "  kubectl logs deployment/frontend -n $NAMESPACE"
    echo ""
    echo "Describe resources:"
    echo "  kubectl describe pod <pod-name> -n $NAMESPACE"
    echo "  kubectl describe svc frontend -n $NAMESPACE"
    echo ""
    echo "Get metrics:"
    echo "  kubectl top nodes"
    echo "  kubectl top pods -n $NAMESPACE"
    echo ""
    echo "Cleanup resources:"
    echo "  ./cleanup-gcp.sh"
    echo ""
}

# Main execution
main() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔════════════════════════════════════════════════════════════════════════╗
║                                                                        ║
║              GCP DEPLOYMENT STATUS CHECK                              ║
║              Voting App on Kubernetes (GKE)                           ║
║                                                                        ║
╚════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    print_header "Starting Status Check"
    
    # Check if deployment exists first
    CLUSTERS=$(gcloud container clusters list --region=$GCP_REGION --project=$GCP_PROJECT 2>/dev/null || echo "")
    if [ -z "$CLUSTERS" ]; then
        echo -e "${YELLOW}"
        cat << "EOF"
┌─────────────────────────────────────────────────────────────────────────────┐
│                        🚀 DEPLOYMENT NOT FOUND                              │
│                                                                             │
│  Your GCP resources have not been deployed yet.                            │
│                                                                             │
│  TO DEPLOY:                                                                │
│  ──────────                                                                │
│  Run the deployment script:                                                │
│                                                                             │
│    $ ./test-gcp-deployment.sh                                              │
│                                                                             │
│  This will:                                                                │
│    ✓ Create GKE cluster (3 nodes)                                         │
│    ✓ Create Cloud SQL database                                            │
│    ✓ Deploy voting app containers                                         │
│    ✓ Configure networking & services                                      │
│    ✓ Validate deployment                                                  │
│                                                                             │
│  Timeline:  ~20-25 minutes                                                │
│  Cost:      ~$2 for testing                                               │
│                                                                             │
│  After deployment, you can run this script to monitor status:              │
│    $ ./check-gcp-status.sh                                                │
│                                                                             │
│  Then test the app in your browser at the LoadBalancer IP!                │
│                                                                             │
│  When done, cleanup safely (saves ~$108/month):                           │
│    $ ./cleanup-gcp.sh                                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
EOF
        echo -e "${NC}"
        return 0
    fi
    
    check_gcloud
    check_gke_cluster
    check_gke_nodes
    check_cloud_sql
    check_kubernetes
    check_namespace
    check_deployments
    check_pods
    check_services
    check_application_health
    check_resource_usage
    check_persistent_volumes
    show_summary
}

main
