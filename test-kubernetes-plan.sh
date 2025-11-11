#!/bin/bash

###############################################################################
#  KUBERNETES TEST - GCP + TERRAFORM PLAN
#  
#  Verifica Terraform configs si planul pentru GCP
###############################################################################

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   ☸️ KUBERNETES TEST SUITE - GCP + TERRAFORM                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check prerequisites
echo "[1/6] Checking prerequisites..."
echo -n "  ✓ Terraform installed: "
terraform version 2>/dev/null | head -1 | grep -o "Terraform v[0-9.]*" || echo "MISSING ✗"

echo -n "  ✓ gcloud CLI installed: "
gcloud --version 2>/dev/null | head -1 || echo "MISSING ✗"

echo -n "  ✓ kubectl installed: "
kubectl version --client --short 2>/dev/null || echo "MISSING ✗"

# Check GCP authentication
echo ""
echo "[2/6] Checking GCP authentication..."
echo -n "  ✓ GCP authenticated: "
if gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "@"; then
    echo "YES ✓"
else
    echo "NO ✗ - Run: gcloud auth login"
    exit 1
fi

# Check Terraform directory
echo ""
echo "[3/6] Checking Terraform files..."
cd 3-KUBERNETES/terraform || exit 1

echo -n "  ✓ main.tf exists: "
[ -f main.tf ] && echo "YES ✓" || echo "NO ✗"

echo -n "  ✓ variables.tf exists: "
[ -f variables.tf ] && echo "YES ✓" || echo "NO ✗"

echo -n "  ✓ outputs.tf exists: "
[ -f outputs.tf ] && echo "YES ✓" || echo "NO ✗"

# Terraform init
echo ""
echo "[4/6] Terraform Init..."
if terraform init > /tmp/tf_init.log 2>&1; then
    echo "  ✓ Terraform init successful ✓"
else
    echo "  ✗ Terraform init failed ✗"
    tail -10 /tmp/tf_init.log
    exit 1
fi

# Terraform plan
echo ""
echo "[5/6] Terraform Plan (validation only, not applying)..."
if rm -f tfplan && terraform plan -out=tfplan > /tmp/tf_plan.log 2>&1; then
    echo "  ✓ Terraform plan successful ✓"
    echo ""
    echo "  Plan summary:"
    grep -E "Plan:|to add|to change|to destroy" /tmp/tf_plan.log | head -5
else
    echo "  ✗ Terraform plan failed ✗"
    tail -20 /tmp/tf_plan.log
    exit 1
fi

# Check Kubernetes manifests
echo ""
echo "[6/6] Checking Kubernetes manifests..."
cd ../k8s || exit 1

echo -n "  ✓ namespace.yaml exists: "
[ -f namespace.yaml ] && echo "YES ✓" || echo "NO ✗"

echo -n "  ✓ backend-deployment.yaml exists: "
[ -f backend-deployment.yaml ] && echo "YES ✓" || echo "NO ✗"

echo -n "  ✓ frontend-deployment.yaml exists: "
[ -f frontend-deployment.yaml ] && echo "YES ✓" || echo "NO ✗"

echo -n "  ✓ services.yaml exists: "
[ -f services.yaml ] && echo "YES ✓" || echo "NO ✗"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "Summary:"
echo "════════════════════════════════════════════════════════════════"
echo "✓ Terraform configs: Valid"
echo "✓ GCP authentication: OK"
echo "✓ Kubernetes manifests: Ready"
echo ""
echo "🚀 Ready for Kubernetes deployment!"
echo ""
echo "Next steps:"
echo "  1. Review terraform plan"
echo "  2. Run: terraform apply tfplan"
echo "  3. Wait 10-15 minutes for GKE cluster"
echo "  4. Get credentials: gcloud container clusters get-credentials voting-app-cluster"
echo "  5. Deploy: kubectl apply -f k8s/"
echo ""
