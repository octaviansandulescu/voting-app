# GitHub Actions Setup Guide

## Overview

Three GitHub Actions workflows are configured:
1. **CI - Test** (`ci-test.yml`) - Runs tests automatically (NO GCP needed)
2. **Build & Push** (`build-push.yml`) - Builds Docker images and pushes to GCR (requires GCP)
3. **Deploy to GKE** (`deploy.yml`) - Deploys to GKE cluster (requires GCP)

## Prerequisites

You need:
- Google Cloud Project with GKE cluster
- Service Account with GCR and GKE permissions
- GitHub repository admin access

---

## Step 1: Create Service Account in GCP

```bash
# Set your GCP project ID
export PROJECT_ID="voting-app-prod"

# Create service account
gcloud iam service-accounts create github-actions \
  --display-name="GitHub Actions CI/CD" \
  --project=$PROJECT_ID

# Get service account email
export SA_EMAIL="github-actions@${PROJECT_ID}.iam.gserviceaccount.com"
echo "Service Account: $SA_EMAIL"
```

## Step 2: Grant Permissions

```bash
# Grant GCR push permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.admin"

# Grant GKE access
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/container.developer"

# Grant Cloud SQL access (if using Cloud SQL)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/cloudsql.client"
```

## Step 3: Create Service Account Key

```bash
# Create JSON key
gcloud iam service-accounts keys create ~/github-actions-key.json \
  --iam-account=$SA_EMAIL \
  --project=$PROJECT_ID

# Read the key (you'll need this in next step)
cat ~/github-actions-key.json
```

⚠️ **SECURITY WARNING:** Keep this file safe! Never commit to GitHub.

## Step 4: Add Secrets to GitHub

Go to GitHub repository → **Settings → Secrets and variables → Actions**

### Add these secrets:

#### 1. **GCP_SA_KEY** (Service Account Key)
- **Name:** `GCP_SA_KEY`
- **Value:** Full contents of `~/github-actions-key.json`

```bash
# Copy to clipboard (macOS)
cat ~/github-actions-key.json | pbcopy

# Copy to clipboard (Linux)
cat ~/github-actions-key.json | xclip -selection clipboard
```

Then paste into GitHub secret field.

#### 2. **GCP_PROJECT_ID** (Optional - for convenience)
- **Name:** `GCP_PROJECT_ID`
- **Value:** `voting-app-prod` (or your actual project ID)

**Note:** `GCP_PROJECT_ID` is already hardcoded in workflows as `voting-app-prod`, but you can override with a secret if needed.

---

## Step 5: Verify Setup

### Trigger CI Test (No GCP needed)
1. Make a change to `src/backend/`, `src/frontend/`, or `tests/`
2. Push to `main` branch
3. Go to GitHub → **Actions**
4. Watch **CI - Test** workflow run
5. Should complete in ~2 minutes ✅

### Trigger Build & Push (Requires GCP)
1. After tests pass, **Build & Push** should trigger automatically
2. Watch it in GitHub → **Actions**
3. Should see Docker images pushed to GCR:
   ```
   gcr.io/voting-app-prod/voting-app-backend:HASH
   gcr.io/voting-app-prod/voting-app-frontend:HASH
   ```

### Trigger Deploy (Requires GCP)
1. After build completes, **Deploy** should trigger automatically
2. Watch deployment in GitHub → **Actions**
3. Verify in GKE:
   ```bash
   kubectl -n voting-app get pods
   kubectl -n voting-app get services
   ```

---

## Troubleshooting

### Error: "credentials_json" not found

**Problem:** Secret `GCP_SA_KEY` not configured

**Solution:**
1. Go to GitHub → Settings → Secrets and variables → Actions
2. Verify `GCP_SA_KEY` secret exists
3. Delete and recreate with full JSON content
4. Retry workflow

### Error: Permission denied when pushing to GCR

**Problem:** Service account doesn't have GCR permissions

**Solution:**
```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.admin"
```

### Error: Could not connect to cluster

**Problem:** Service account doesn't have GKE access

**Solution:**
```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/container.developer"
```

### Workflow skipped or not triggering

**Problem:** Push doesn't match `paths` trigger

**Solution:** Workflows only trigger on changes to:
- `src/backend/**`
- `src/frontend/**`
- `tests/**`
- `.github/workflows/**`

Try editing a file in one of these directories.

---

## Workflow Details

### CI - Test Workflow
```
Triggered: On every push to main/develop or PR
Runs: ~2-3 minutes
Needs: Python 3.11, MySQL 8.0
Tests: `pytest tests/`
Output: Coverage report
```

### Build & Push Workflow
```
Triggered: On push to main (after tests pass)
Runs: ~5-10 minutes
Needs: Docker, GCP credentials
Output: Docker images in GCR
```

### Deploy Workflow
```
Triggered: On push to main (after build passes)
Runs: ~5-10 minutes
Needs: kubectl, GKE cluster, GCP credentials
Output: Updated deployments in Kubernetes
```

---

## Manual Deployment (if needed)

If workflows fail, deploy manually:

```bash
# Build images locally
docker build -t gcr.io/voting-app-prod/voting-app-backend:v1.0 -f src/backend/Dockerfile src/backend/
docker build -t gcr.io/voting-app-prod/voting-app-frontend:v1.0 -f src/frontend/Dockerfile src/frontend/

# Authenticate
gcloud auth configure-docker

# Push images
docker push gcr.io/voting-app-prod/voting-app-backend:v1.0
docker push gcr.io/voting-app-prod/voting-app-frontend:v1.0

# Deploy
kubectl set image deployment/voting-app-backend voting-app-backend=gcr.io/voting-app-prod/voting-app-backend:v1.0 -n voting-app
kubectl set image deployment/voting-app-frontend voting-app-frontend=gcr.io/voting-app-prod/voting-app-frontend:v1.0 -n voting-app
```

---

## Security Best Practices

1. ✅ **Never commit secrets to GitHub**
   - Use GitHub Secrets, not `.env` files

2. ✅ **Rotate keys regularly**
   - Delete old keys
   - Create new ones quarterly

3. ✅ **Use least privilege**
   - Service account should only have needed roles
   - Consider using Workload Identity for OIDC (more secure)

4. ✅ **Audit access**
   - Check service account key usage
   - Monitor GitHub Actions execution

5. ✅ **Protect main branch**
   - Require PR reviews before merge
   - Require workflows pass before merging

---

## Alternative: OIDC Setup (More Secure)

Instead of Service Account Key, use OIDC (OpenID Connect):

### Create Workload Identity Pool

```bash
gcloud iam workload-identity-pools create github-pool \
  --location=global \
  --display-name="GitHub Actions"

gcloud iam workload-identity-pools providers create-oidc github \
  --location=global \
  --workload-identity-pool=github-pool \
  --display-name="GitHub" \
  --attribute-mapping=google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.aud=assertion.aud,attribute.repository=assertion.repository \
  --issuer-uri=https://token.actions.githubusercontent.com
```

### Create Service Account and Link

```bash
# Create service account
gcloud iam service-accounts create github-actions-oidc \
  --display-name="GitHub Actions OIDC"

# Get workload identity pool resource name
POOL_NAME=$(gcloud iam workload-identity-pools describe github-pool --location=global --format='value(name)')

# Create service account bindings
gcloud iam service-accounts add-iam-policy-binding github-actions-oidc@${PROJECT_ID}.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/$POOL_NAME/attribute.repository/octaviansandulescu/voting-app"
```

### Add GitHub Secrets

```
WORKLOAD_IDENTITY_PROVIDER: projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github
SERVICE_ACCOUNT_EMAIL: github-actions-oidc@voting-app-prod.iam.gserviceaccount.com
```

This is more secure because no keys are stored in GitHub!

---

## Next Steps

1. ✅ Set up service account in GCP
2. ✅ Grant required permissions
3. ✅ Create and download service account key
4. ✅ Add `GCP_SA_KEY` secret to GitHub
5. ✅ Test CI workflow on next push
6. ✅ Verify Docker images in GCR
7. ✅ Confirm deployment in GKE
8. Consider OIDC setup for enhanced security

