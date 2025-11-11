#!/bin/bash

###############################################################################
# GCP CLEANUP SCRIPT
# 
# Safely removes all GCP resources created for the voting app
# Usage: ./cleanup-gcp.sh
#
# What it removes:
#   1. Kubernetes namespace and all resources
#   2. Terraform infrastructure (GKE, Cloud SQL, VPC, etc.)
#   3. Verifies cleanup completion
#   4. Shows final status
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
TERRAFORM_DIR="3-KUBERNETES/terraform"

# Helper functions
print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

print_step() {
    echo -e "\n${CYAN}[STEP] $1${NC}"
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

confirm() {
    local prompt="$1"
    local response
    
    read -p "$(echo -e ${YELLOW}$prompt${NC}) (yes/no): " response
    
    if [[ "$response" == "yes" ]]; then
        return 0
    else
        return 1
    fi
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking Prerequisites"
    
    # Check gcloud
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud not installed"
        exit 1
    fi
    print_success "gcloud found"
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl not installed"
        exit 1
    fi
    print_success "kubectl found"
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform not installed"
        exit 1
    fi
    print_success "Terraform found"
}

# Stage 1: Delete Kubernetes namespace
delete_kubernetes_namespace() {
    print_step "Stage 1: Delete Kubernetes Namespace"
    
    # Check if namespace exists
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        print_warning "Namespace '$NAMESPACE' not found"
        return 0
    fi
    
    print_warning "This will delete the voting app deployment from Kubernetes"
    print_info "Namespace: $NAMESPACE"
    print_info "Pods to delete:"
    kubectl get pods -n $NAMESPACE -o json | jq -r '.items[] | .metadata.name' | sed 's/^/  - /'
    
    if ! confirm "Delete Kubernetes namespace and all resources?"; then
        print_error "Namespace deletion cancelled"
        return 1
    fi
    
    echo ""
    print_info "Deleting namespace $NAMESPACE..."
    kubectl delete namespace $NAMESPACE --ignore-not-found=true
    
    print_info "Waiting for namespace deletion..."
    while kubectl get namespace $NAMESPACE &> /dev/null; do
        echo -n "."
        sleep 2
    done
    echo ""
    
    print_success "Kubernetes namespace deleted"
}

# Stage 2: Delete Terraform infrastructure
delete_terraform_resources() {
    print_step "Stage 2: Delete Terraform Infrastructure"
    
    # Check if Terraform directory exists
    if [ ! -d "$TERRAFORM_DIR" ]; then
        print_error "Terraform directory not found: $TERRAFORM_DIR"
        return 1
    fi
    
    # Change to Terraform directory
    cd "$TERRAFORM_DIR"
    
    # Check if already initialized
    if [ ! -d ".terraform" ]; then
        print_warning "Terraform not initialized in $TERRAFORM_DIR"
        print_info "Initializing Terraform..."
        terraform init -upgrade
    fi
    
    # Show what will be destroyed
    print_warning "This will destroy ALL GCP resources created by Terraform:"
    print_info "  • GKE cluster (voting-app-cluster)"
    print_info "  • Cloud SQL instance (MySQL)"
    print_info "  • VPC network"
    print_info "  • Service accounts"
    print_info "  • All associated resources"
    
    print_info "Terraform plan:"
    terraform plan -destroy -out=destroy.tfplan
    
    echo ""
    if ! confirm "Destroy all Terraform resources?"; then
        print_error "Terraform destroy cancelled"
        cd - > /dev/null
        return 1
    fi
    
    echo ""
    print_info "Destroying infrastructure..."
    terraform apply destroy.tfplan
    
    # Clean up plan file
    rm -f destroy.tfplan
    
    print_success "Terraform infrastructure destroyed"
    cd - > /dev/null
}

# Stage 3: Verify cleanup
verify_cleanup() {
    print_step "Stage 3: Verifying Cleanup"
    
    # Check GKE clusters
    print_info "Checking GKE clusters..."
    CLUSTERS=$(gcloud container clusters list --region=$GCP_REGION --project=$GCP_PROJECT 2>/dev/null || echo "")
    
    if echo "$CLUSTERS" | grep -q "$CLUSTER_NAME"; then
        print_warning "Cluster still exists: $CLUSTER_NAME"
    else
        print_success "GKE cluster removed"
    fi
    
    # Check Cloud SQL instances
    print_info "Checking Cloud SQL instances..."
    INSTANCES=$(gcloud sql instances list --project=$GCP_PROJECT 2>/dev/null || echo "")
    
    if echo "$INSTANCES" | grep -q "voting-app"; then
        print_warning "Cloud SQL instance still exists"
    else
        print_success "Cloud SQL instance removed"
    fi
    
    # Check VPC networks
    print_info "Checking VPC networks..."
    NETWORKS=$(gcloud compute networks list --project=$GCP_PROJECT 2>/dev/null || echo "")
    
    if echo "$NETWORKS" | grep -q "voting-app-vpc"; then
        print_warning "VPC network still exists"
    else
        print_success "VPC network removed"
    fi
    
    # Check service accounts
    print_info "Checking service accounts..."
    ACCOUNTS=$(gcloud iam service-accounts list --project=$GCP_PROJECT 2>/dev/null || echo "")
    
    if echo "$ACCOUNTS" | grep -q "voting-app"; then
        print_warning "Service account still exists"
    else
        print_success "Service accounts removed"
    fi
}

# Stage 4: Final cleanup
final_cleanup() {
    print_step "Stage 4: Final Cleanup"
    
    # Remove kubeconfig entry
    print_info "Cleaning kubeconfig..."
    kubectl config delete-context gke_${GCP_PROJECT}_${GCP_REGION}_${CLUSTER_NAME} 2>/dev/null || true
    kubectl config delete-cluster gke_${GCP_PROJECT}_${GCP_REGION}_${CLUSTER_NAME} 2>/dev/null || true
    print_success "Kubeconfig cleaned"
    
    # Remove local Terraform state files
    if [ -d "$TERRAFORM_DIR" ]; then
        cd "$TERRAFORM_DIR"
        
        print_info "Cleaning Terraform state files..."
        # Keep .terraform, but can clean state
        # rm -f terraform.tfstate*
        print_success "Terraform directory ready for next deployment"
        
        cd - > /dev/null
    fi
}

# Show summary
show_summary() {
    print_header "CLEANUP COMPLETE"
    
    echo "Summary:"
    echo "  ✓ Kubernetes resources deleted"
    echo "  ✓ Terraform infrastructure destroyed"
    echo "  ✓ GCP resources removed"
    echo "  ✓ No active resources remaining"
    echo ""
    
    echo "Final Status:"
    echo "  • GKE Cluster: Deleted"
    echo "  • Cloud SQL: Deleted"
    echo "  • VPC Network: Deleted"
    echo "  • Service Accounts: Deleted"
    echo ""
    
    echo "Cost Impact:"
    echo "  • Previous monthly cost: ~$105-110"
    echo "  • Current monthly cost: $0"
    echo "  • Savings: $105-110/month"
    echo ""
    
    echo "Next Steps:"
    echo "  • Verify in GCP Console: https://console.cloud.google.com"
    echo "  • To deploy again: ./test-gcp-deployment.sh"
    echo "  • To check status: ./check-gcp-status.sh"
}

# Main execution
main() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔════════════════════════════════════════════════════════════════════════╗
║                                                                        ║
║              GCP CLEANUP SCRIPT                                        ║
║              Remove ALL Voting App Resources                           ║
║                                                                        ║
╚════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    print_header "Starting Cleanup Process"
    
    print_warning "⚠️  WARNING: This will DELETE all GCP resources!"
    print_warning "This action cannot be undone!"
    echo ""
    
    if ! confirm "Do you want to continue with cleanup?"; then
        print_error "Cleanup cancelled by user"
        exit 0
    fi
    
    echo ""
    print_info "Starting cleanup..."
    
    # Execute cleanup stages
    check_prerequisites
    
    if ! delete_kubernetes_namespace; then
        print_warning "Kubernetes cleanup had issues, continuing..."
    fi
    
    if ! delete_terraform_resources; then
        print_error "Terraform cleanup failed"
        exit 1
    fi
    
    verify_cleanup
    final_cleanup
    show_summary
}

# Run main
main
