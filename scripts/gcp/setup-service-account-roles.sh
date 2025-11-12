#!/bin/bash

# ============================================================================
# GCP Service Account IAM Setup Script
# ============================================================================
# Grants required IAM roles to voting-app service account
# Usage: ./setup-service-account-roles.sh
# ============================================================================

set -e

# Get absolute paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║              GCP Service Account - IAM Setup                           ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# Step 1: Extract service account info from credentials file
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}📋 Finding service account credentials...${NC}"

CREDS_FILE=""

# Look for credentials in order:
# 1. GCP_CREDENTIALS environment variable
# 2. ~/certs/ directory
# 3. PROJECT_ROOT/certs/ directory

if [ -n "$GCP_CREDENTIALS" ] && [ -f "$GCP_CREDENTIALS" ]; then
    CREDS_FILE="$GCP_CREDENTIALS"
elif [ -d "$HOME/certs" ]; then
    FOUND=$(find "$HOME/certs" -maxdepth 1 -name "*.json" 2>/dev/null | grep -v Zone | head -1)
    if [ -n "$FOUND" ]; then
        CREDS_FILE="$FOUND"
    fi
elif [ -d "$PROJECT_ROOT/certs" ]; then
    FOUND=$(find "$PROJECT_ROOT/certs" -maxdepth 1 -name "*.json" 2>/dev/null | grep -v Zone | head -1)
    if [ -n "$FOUND" ]; then
        CREDS_FILE="$FOUND"
    fi
fi

if [ -z "$CREDS_FILE" ] || [ ! -f "$CREDS_FILE" ]; then
    echo -e "${RED}❌ ERROR: No service account credentials found${NC}"
    echo ""
    echo "Please place service account JSON in one of:"
    echo "  - ~/certs/service-account-key.json"
    echo "  - $PROJECT_ROOT/certs/service-account-key.json"
    echo "  - Or set: export GCP_CREDENTIALS=/path/to/key.json"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Found credentials: $CREDS_FILE${NC}"
echo ""

# Extract service account email and project ID
SA_EMAIL=$(grep -o '"client_email": "[^"]*' "$CREDS_FILE" | cut -d'"' -f4)
PROJECT_ID=$(grep -o '"project_id": "[^"]*' "$CREDS_FILE" | cut -d'"' -f4)

echo -e "${BLUE}📌 Service Account Details:${NC}"
echo "   Email:   $SA_EMAIL"
echo "   Project: $PROJECT_ID"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# Step 2: Check if user can modify IAM
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}🔐 Verifying current user permissions...${NC}"

# Try to get current user identity
CURRENT_ACCOUNT=$(gcloud config get-value account 2>/dev/null || echo "unknown")
echo -e "   Current account: $CURRENT_ACCOUNT"

# Check if current account can modify IAM
if ! gcloud projects get-iam-policy "$PROJECT_ID" &> /dev/null; then
    echo -e "${YELLOW}⚠️  Current account may not have IAM permissions${NC}"
fi

echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# Step 3: Display what will be done
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}📋 Required IAM Roles:${NC}"
echo ""

ROLES=(
    "roles/container.developer:GKE cluster management"
    "roles/cloudsql.admin:Cloud SQL management"
    "roles/compute.networkAdmin:VPC and network management"
    "roles/iam.serviceAccountUser:Service account operations"
)

for role_item in "${ROLES[@]}"; do
    ROLE="${role_item%%:*}"
    DESCRIPTION="${role_item##*:}"
    echo "   ✓ $ROLE"
    echo "     └─ $DESCRIPTION"
done

echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# Step 4: Confirm before proceeding
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${YELLOW}❓ Continue with IAM role assignment? (yes/no)${NC}"
read -r CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}⏳ Assigning IAM roles...${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# Step 5: Grant roles
# ═══════════════════════════════════════════════════════════════════════════════

ROLES_ARRAY=(
    "roles/container.developer"
    "roles/cloudsql.admin"
    "roles/compute.networkAdmin"
    "roles/iam.serviceAccountUser"
)

FAILED=false

for ROLE in "${ROLES_ARRAY[@]}"; do
    echo -n "  Granting $ROLE... "
    
    if gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SA_EMAIL" \
        --role="$ROLE" \
        --quiet \
        &> /dev/null; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${RED}❌${NC}"
        FAILED=true
    fi
done

echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# Step 6: Verify roles were assigned
# ═══════════════════════════════════════════════════════════════════════════════

if [ "$FAILED" = false ]; then
    echo -e "${BLUE}✅ Verifying role assignment...${NC}"
    echo ""
    
    gcloud projects get-iam-policy "$PROJECT_ID" \
        --flatten="bindings[].members" \
        --filter="bindings.members:serviceAccount:$SA_EMAIL" \
        --format="table(bindings.role)" | head -10
    
    echo ""
    echo -e "${GREEN}✅ IAM roles successfully assigned!${NC}"
    echo ""
    echo -e "${BLUE}📌 Next steps:${NC}"
    echo ""
    echo "  1. Export credentials:"
    echo "     export GCP_CREDENTIALS=$CREDS_FILE"
    echo ""
    echo "  2. Deploy to Kubernetes:"
    echo "     cd $PROJECT_ROOT"
    echo "     ./scripts/deployment/start-deployment.sh"
    echo ""
else
    echo -e "${RED}⚠️  Some roles failed to assign${NC}"
    echo ""
    echo -e "${YELLOW}This might be because:${NC}"
    echo "  • Current account lacks IAM admin permissions"
    echo "  • Need to use an Owner or Editor account to assign roles"
    echo ""
    echo -e "${BLUE}Manual assignment:${NC}"
    echo "  1. Go to: https://console.cloud.google.com"
    echo "  2. Project: $PROJECT_ID"
    echo "  3. Navigate to: IAM & Admin > IAM"
    echo "  4. Find: $SA_EMAIL"
    echo "  5. Click Edit and add roles listed above"
    echo ""
    exit 1
fi
