#!/bin/bash

# Simple monitoring script to check deployment progress

PROJECT="diesel-skyline-474415-j6"
REGION="us-central1"
CLUSTER="voting-app-cluster"

echo "🔍 Monitoring GCP Deployment Progress..."
echo ""

while true; do
    clear
    echo "═══════════════════════════════════════════════════════════════"
    echo "  GCP DEPLOYMENT PROGRESS MONITOR"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    # Cluster status
    CLUSTER_INFO=$(gcloud container clusters describe $CLUSTER \
        --region=$REGION --project=$PROJECT \
        --format="value(status,currentNodeCount,currentMasterVersion)" 2>/dev/null || echo "")
    
    if [ ! -z "$CLUSTER_INFO" ]; then
        STATUS=$(echo "$CLUSTER_INFO" | awk '{print $1}')
        NODE_COUNT=$(echo "$CLUSTER_INFO" | awk '{print $2}')
        VERSION=$(echo "$CLUSTER_INFO" | awk '{print $3}')
        
        echo "Cluster: $CLUSTER"
        echo "  Status: $STATUS"
        echo "  Nodes: $NODE_COUNT"
        echo "  Version: $VERSION"
        echo ""
    else
        echo "Cluster: Not found"
    fi
    
    # SQL status
    SQL_INFO=$(gcloud sql instances describe voting-app-cluster-db \
        --project=$PROJECT \
        --format="value(state)" 2>/dev/null || echo "")
    
    if [ ! -z "$SQL_INFO" ]; then
        echo "Cloud SQL: $SQL_INFO"
    else
        echo "Cloud SQL: Not found"
    fi
    echo ""
    
    # Terraform status
    echo "Terraform processes running:"
    ps aux | grep "terraform apply" | grep -v grep | wc -l > /tmp/tf_count.txt
    TF_COUNT=$(cat /tmp/tf_count.txt)
    if [ "$TF_COUNT" -gt 0 ]; then
        echo "  ✓ terraform apply running..."
    else
        echo "  ✗ terraform apply completed"
    fi
    echo ""
    
    # Next steps
    if [ "$STATUS" = "RUNNING" ]; then
        echo "Next step: Deploy Kubernetes resources"
        echo "Run: ./check-gcp-status.sh"
    else
        echo "Waiting for cluster to be RUNNING..."
        echo "Refresh in 10 seconds..."
    fi
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "Press Ctrl+C to stop monitoring"
    
    sleep 10
done
