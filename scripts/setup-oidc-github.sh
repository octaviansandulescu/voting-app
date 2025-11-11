#!/bin/bash

# GCP OIDC Setup Script for GitHub Actions
# This script sets up Workload Identity Federation with GitHub without storing secrets
# Usage: bash setup-oidc-github.sh

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}GCP OIDC Setup for GitHub Actions${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Get project configuration
echo -e "${YELLOW}Step 1: Configuration${NC}"
read -p "Enter GCP Project ID (e.g., voting-app-prod): " PROJECT_ID
read -p "Enter GitHub repository owner (e.g., octaviansandulescu): " GITHUB_OWNER
read -p "Enter GitHub repository name (e.g., voting-app): " GITHUB_REPO

export PROJECT_ID
export GITHUB_OWNER
export GITHUB_REPO
export GITHUB_REPOSITORY="${GITHUB_OWNER}/${GITHUB_REPO}"

echo -e "${GREEN}✓ Configuration:${NC}"
echo "  Project ID: $PROJECT_ID"
echo "  Repository: $GITHUB_REPOSITORY"
echo ""

# Step 2: Get project number
echo -e "${YELLOW}Step 2: Getting project number...${NC}"
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
echo -e "${GREEN}✓ Project number: $PROJECT_NUMBER${NC}"
echo ""

# Step 3: Enable required APIs
echo -e "${YELLOW}Step 3: Enabling required APIs...${NC}"
gcloud services enable iamcredentials.googleapis.com \
  --project=$PROJECT_ID || true
gcloud services enable cloudresourcemanager.googleapis.com \
  --project=$PROJECT_ID || true
gcloud services enable sts.googleapis.com \
  --project=$PROJECT_ID || true
gcloud services enable serviceusage.googleapis.com \
  --project=$PROJECT_ID || true

echo -e "${GREEN}✓ APIs enabled${NC}"
echo ""

# Step 4: Create Workload Identity Pool
echo -e "${YELLOW}Step 4: Creating Workload Identity Pool...${NC}"
POOL_ID="github-pool"
POOL_NAME="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}"

# Check if pool already exists
if gcloud iam workload-identity-pools describe ${POOL_ID} \
  --location=global \
  --project=$PROJECT_ID >/dev/null 2>&1; then
  echo -e "${YELLOW}⚠ Pool already exists: $POOL_NAME${NC}"
else
  gcloud iam workload-identity-pools create ${POOL_ID} \
    --location=global \
    --display-name="GitHub Actions" \
    --project=$PROJECT_ID \
    --disabled=false
  echo -e "${GREEN}✓ Workload Identity Pool created${NC}"
fi
echo ""

# Step 5: Create OIDC Provider
echo -e "${YELLOW}Step 5: Creating OIDC Provider...${NC}"
PROVIDER_ID="github"

# Check if provider already exists
if gcloud iam workload-identity-pools providers describe-oidc ${PROVIDER_ID} \
  --location=global \
  --workload-identity-pool=${POOL_ID} \
  --project=$PROJECT_ID >/dev/null 2>&1; then
  echo -e "${YELLOW}⚠ Provider already exists${NC}"
else
  gcloud iam workload-identity-pools providers create-oidc ${PROVIDER_ID} \
    --location=global \
    --workload-identity-pool=${POOL_ID} \
    --display-name="GitHub" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.aud=assertion.aud,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
    --issuer-uri=https://token.actions.githubusercontent.com \
    --project=$PROJECT_ID \
    --attribute-condition="assertion.repository_owner == '${GITHUB_OWNER}'"
  echo -e "${GREEN}✓ OIDC Provider created${NC}"
fi
echo ""

# Step 6: Create Service Account
echo -e "${YELLOW}Step 6: Creating Service Account...${NC}"
SA_NAME="github-actions-oidc"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Check if service account already exists
if gcloud iam service-accounts describe ${SA_EMAIL} --project=$PROJECT_ID >/dev/null 2>&1; then
  echo -e "${YELLOW}⚠ Service account already exists: $SA_EMAIL${NC}"
else
  gcloud iam service-accounts create ${SA_NAME} \
    --display-name="GitHub Actions OIDC" \
    --project=$PROJECT_ID
  echo -e "${GREEN}✓ Service account created: $SA_EMAIL${NC}"
fi
echo ""

# Step 7: Grant required roles
echo -e "${YELLOW}Step 7: Granting roles to service account...${NC}"

# GCR (Google Container Registry) permissions
echo "  - Granting GCR permissions..."
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.admin" \
  --condition=None >/dev/null 2>&1 || true

# GKE permissions
echo "  - Granting GKE permissions..."
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/container.developer" \
  --condition=None >/dev/null 2>&1 || true

# Cloud SQL permissions (if using Cloud SQL)
echo "  - Granting Cloud SQL permissions..."
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/cloudsql.client" \
  --condition=None >/dev/null 2>&1 || true

echo -e "${GREEN}✓ Roles granted${NC}"
echo ""

# Step 8: Create Workload Identity binding
echo -e "${YELLOW}Step 8: Creating Workload Identity binding...${NC}"

WORKLOAD_IDENTITY_PROVIDER="${POOL_NAME}/providers/${PROVIDER_ID}"

# Create attribute condition to match specific repository
gcloud iam service-accounts add-iam-policy-binding ${SA_EMAIL} \
  --project=$PROJECT_ID \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${POOL_NAME}/attribute.repository/${GITHUB_REPOSITORY}" >/dev/null 2>&1 || true

echo -e "${GREEN}✓ Workload Identity binding created${NC}"
echo ""

# Step 9: Display configuration
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ OIDC Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Add these secrets to GitHub:${NC}"
echo ""
echo "  1. Go to: https://github.com/${GITHUB_REPOSITORY}/settings/secrets/actions"
echo ""
echo "  2. Add Secret #1:"
echo "     Name: WORKLOAD_IDENTITY_PROVIDER"
echo "     Value: ${WORKLOAD_IDENTITY_PROVIDER}"
echo ""
echo "  3. Add Secret #2:"
echo "     Name: SERVICE_ACCOUNT_EMAIL"
echo "     Value: ${SA_EMAIL}"
echo ""
echo -e "${YELLOW}Or copy-paste this for quick setup:${NC}"
echo ""
cat << EOF
WORKLOAD_IDENTITY_PROVIDER=${WORKLOAD_IDENTITY_PROVIDER}
SERVICE_ACCOUNT_EMAIL=${SA_EMAIL}
EOF
echo ""
echo -e "${YELLOW}Verify setup:${NC}"
echo ""
echo "  kubectl logs -l app=voting-app -n voting-app --tail=50"
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Next steps:${NC}"
echo -e "${BLUE}========================================${NC}"
echo "1. Copy the secrets above"
echo "2. Go to GitHub repository settings"
echo "3. Add the two secrets to Actions"
echo "4. Update workflows to use OIDC (already done in workflows)"
echo "5. Push code to main branch to test"
echo ""
echo -e "${YELLOW}No JSON keys needed! 🎉${NC}"
echo ""
