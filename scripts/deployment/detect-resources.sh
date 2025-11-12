#!/bin/bash

# DETECT-RESOURCES.sh
# Auto-detects GCP resources (cluster, namespace, Cloud SQL)
# Source this script in other deployment scripts to get dynamic values

set -e

# Get project ID
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: No GCP project configured"
    echo "   Run: gcloud config set project PROJECT_ID"
    exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════════
# 1. DETECT KUBERNETES CLUSTER
# ═══════════════════════════════════════════════════════════════════════════════

detect_cluster() {
    local clusters=$(gcloud container clusters list --format="value(name,location)" 2>/dev/null || echo "")
    
    if [ -z "$clusters" ]; then
        CLUSTER_NAME=""
        CLUSTER_ZONE=""
        return
    fi
    
    # Use first cluster found
    CLUSTER_NAME=$(echo "$clusters" | head -1 | awk '{print $1}')
    CLUSTER_ZONE=$(echo "$clusters" | head -1 | awk '{print $2}')
}

# ═══════════════════════════════════════════════════════════════════════════════
# 2. DETECT KUBERNETES NAMESPACE
# ═══════════════════════════════════════════════════════════════════════════════

detect_namespace() {
    local namespaces=""
    
    if [ -z "$CLUSTER_NAME" ]; then
        NAMESPACE=""
        return
    fi
    
    # Get cluster credentials
    gcloud container clusters get-credentials "$CLUSTER_NAME" \
        --zone "$CLUSTER_ZONE" \
        --project "$PROJECT_ID" 2>/dev/null || return
    
    # List namespaces
    namespaces=$(kubectl get ns -o custom-columns=NAME:.metadata.name --no-headers 2>/dev/null || echo "")
    
    if [ -z "$namespaces" ]; then
        NAMESPACE=""
        return
    fi
    
    # Prefer voting-app namespace, otherwise first non-system namespace
    NAMESPACE=$(echo "$namespaces" | grep "^voting-app$" | head -1 || \
                echo "$namespaces" | grep -v "^kube-" | grep -v "^default$" | head -1 || \
                echo "$namespaces" | head -1)
}

# ═══════════════════════════════════════════════════════════════════════════════
# 3. DETECT CLOUD SQL INSTANCE
# ═══════════════════════════════════════════════════════════════════════════════

detect_sql_instance() {
    local instances=$(gcloud sql instances list --format="value(name)" 2>/dev/null || echo "")
    
    if [ -z "$instances" ]; then
        SQL_INSTANCE=""
        return
    fi
    
    # Prefer voting-app instances, otherwise first one
    SQL_INSTANCE=$(echo "$instances" | grep "voting" | head -1 || echo "$instances" | head -1)
}

# ═══════════════════════════════════════════════════════════════════════════════
# RUN ALL DETECTIONS
# ═══════════════════════════════════════════════════════════════════════════════

detect_cluster
detect_namespace
detect_sql_instance

# ═══════════════════════════════════════════════════════════════════════════════
# EXPORT VARIABLES FOR USE IN OTHER SCRIPTS
# ═══════════════════════════════════════════════════════════════════════════════

export PROJECT_ID
export CLUSTER_NAME
export CLUSTER_ZONE
export NAMESPACE
export SQL_INSTANCE
