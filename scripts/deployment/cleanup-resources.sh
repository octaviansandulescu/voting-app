#!/bin/bash

# CLEANUP-RESOURCES.sh
# Removes ALL Kubernetes and Cloud SQL resources
# Use with caution - this DELETES data!

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source detection script
source "$SCRIPT_DIR/detect-resources.sh"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "🗑️  CLEANUP - REMOVE ALL RESOURCES"
echo "════════════════════════════════════════════════════════════════"
echo ""

if [ -z "$CLUSTER_NAME" ] && [ -z "$SQL_INSTANCE" ]; then
    echo "❌ No resources found to cleanup!"
    echo ""
    echo "Active resources:"
    echo "  - Clusters: None"
    echo "  - Cloud SQL: None"
    exit 0
fi

# Show what will be deleted
echo "⚠️  WARNING: This will DELETE the following resources:"
echo ""

if [ ! -z "$CLUSTER_NAME" ]; then
    echo "  🔴 Kubernetes Cluster"
    echo "     - Name: $CLUSTER_NAME"
    echo "     - Zone: $CLUSTER_ZONE"
    if [ ! -z "$NAMESPACE" ]; then
        echo "     - Namespace: $NAMESPACE"
        POD_COUNT=$(kubectl get pods -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l || echo "0")
        echo "     - Pods: $POD_COUNT"
    fi
    echo ""
fi

if [ ! -z "$SQL_INSTANCE" ]; then
    echo "  🔴 Cloud SQL Database"
    echo "     - Instance: $SQL_INSTANCE"
    echo "     - ⚠️  ALL DATA WILL BE LOST"
    echo ""
fi

echo "════════════════════════════════════════════════════════════════"
echo ""
read -p "⛔ Type 'DELETE' to confirm complete removal: " CONFIRM

if [ "$CONFIRM" != "DELETE" ]; then
    echo "❌ Cleanup cancelled"
    exit 0
fi

echo ""
echo "🗑️  Starting cleanup..."
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# 1. DELETE KUBERNETES NAMESPACE (removes all pods, services, etc.)
# ═══════════════════════════════════════════════════════════════════════════════

if [ ! -z "$NAMESPACE" ] && [ ! -z "$CLUSTER_NAME" ]; then
    echo "Step 1/2: Deleting Kubernetes namespace..."
    echo "  - Namespace: $NAMESPACE"
    
    gcloud container clusters get-credentials "$CLUSTER_NAME" \
        --zone "$CLUSTER_ZONE" \
        --project "$PROJECT_ID" 2>/dev/null || true
    
    if kubectl get namespace "$NAMESPACE" 2>/dev/null; then
        kubectl delete namespace "$NAMESPACE" --wait=true 2>/dev/null || true
        echo "  ✅ Namespace deleted"
    else
        echo "  ℹ️  Namespace already gone"
    fi
    
    echo ""
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 2. DELETE KUBERNETES CLUSTER
# ═══════════════════════════════════════════════════════════════════════════════

if [ ! -z "$CLUSTER_NAME" ]; then
    echo "Step 2/2: Deleting Kubernetes cluster..."
    echo "  - Cluster: $CLUSTER_NAME"
    echo "  - Zone: $CLUSTER_ZONE"
    echo ""
    echo "  ⏳ This may take 5-10 minutes..."
    
    gcloud container clusters delete "$CLUSTER_NAME" \
        --zone "$CLUSTER_ZONE" \
        --quiet 2>/dev/null || true
    
    echo "  ✅ Cluster deleted"
    echo ""
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 3. DELETE CLOUD SQL INSTANCE
# ═══════════════════════════════════════════════════════════════════════════════

if [ ! -z "$SQL_INSTANCE" ]; then
    echo "Step 3/3: Deleting Cloud SQL instance..."
    echo "  - Instance: $SQL_INSTANCE"
    echo ""
    echo "  ⏳ This may take 5-10 minutes..."
    
    gcloud sql instances delete "$SQL_INSTANCE" \
        --quiet 2>/dev/null || true
    
    echo "  ✅ Cloud SQL instance deleted"
    echo ""
fi

echo "════════════════════════════════════════════════════════════════"
echo "✅ CLEANUP COMPLETE"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "All resources have been successfully deleted."
echo ""
echo "To redeploy everything:"
echo "  cd 3-KUBERNETES/terraform && terraform apply"
echo "  ./scripts/deployment/start-deployment.sh"
echo ""
