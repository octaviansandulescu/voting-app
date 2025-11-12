#!/bin/bash

# ============================================================================
# Generate Kubernetes secret from Terraform outputs
# ============================================================================
# This script reads database credentials from Terraform state
# and creates a valid Kubernetes secret manifest
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/3-KUBERNETES/terraform"
OUTPUT_FILE="$SCRIPT_DIR/01-secrets-generated.yaml"

# Setup GCP credentials
if [ -z "$GCP_CREDENTIALS" ]; then
    if [ -f "$HOME/certs/gke-default-sa-key.json" ]; then
        export GCP_CREDENTIALS="$HOME/certs/gke-default-sa-key.json"
    fi
fi

if [ -n "$GCP_CREDENTIALS" ]; then
    export GOOGLE_APPLICATION_CREDENTIALS="$GCP_CREDENTIALS"
fi

echo "📋 Extracting database credentials from Terraform..."

cd "$TERRAFORM_DIR"

# Get values from Terraform outputs
DB_HOST=$(terraform output -raw sql_instance_ip 2>/dev/null || echo "")
DB_PORT=$(terraform output -raw sql_instance_port 2>/dev/null || echo "3306")
DB_USER=$(terraform output -raw sql_database_user 2>/dev/null || echo "voting_user")
DB_PASSWORD=$(terraform output -raw sql_database_password 2>/dev/null || echo "")
DB_NAME=$(terraform output -raw sql_database_name 2>/dev/null || echo "voting_app_k8s")

# Fallback for IP if empty
if [ -z "$DB_HOST" ]; then
    # Try getting from gcloud
    INSTANCE_NAME=$(terraform output -raw sql_instance_connection_name 2>/dev/null || echo "")
    if [ ! -z "$INSTANCE_NAME" ]; then
        DB_HOST=$(gcloud sql instances describe "${INSTANCE_NAME##*:}" --format='value(ipAddresses[0].ipAddress)' 2>/dev/null || echo "")
    fi
fi

# Validate we have credentials
if [ -z "$DB_HOST" ] || [ -z "$DB_PASSWORD" ]; then
    echo "❌ ERROR: Could not extract database credentials from Terraform"
    echo "   DB_HOST: $DB_HOST"
    echo "   DB_USER: $DB_USER"
    echo "   DB_NAME: $DB_NAME"
    exit 1
fi

echo "✅ Credentials extracted:"
echo "   DB_HOST: $DB_HOST"
echo "   DB_PORT: $DB_PORT"
echo "   DB_USER: $DB_USER"
echo "   DB_NAME: $DB_NAME"
echo "   DB_PASSWORD: ****"
echo ""

# Generate secret manifest
cat > "$OUTPUT_FILE" << EOF
###############################################################################
# KUBERNETES SECRETS - DATABASE CREDENTIALS
# 
# AUTO-GENERATED from Terraform outputs
# Do NOT commit to git - this file contains credentials
###############################################################################

apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: voting-app
type: Opaque
stringData:
  DB_HOST: "$DB_HOST"
  DB_PORT: "$DB_PORT"
  DB_USER: "$DB_USER"
  DB_PASSWORD: "$DB_PASSWORD"
  DB_NAME: "$DB_NAME"

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: voting-app
data:
  DEPLOYMENT_MODE: "kubernetes"
  FRONTEND_URL: "http://localhost"
  BACKEND_PORT: "8000"
  DEBUG: "False"
EOF

echo "✅ Secret manifest generated: $OUTPUT_FILE"
echo ""
