# GitHub Actions OIDC Setup (Recommended)

## Overview

This guide sets up **Workload Identity Federation (OIDC)** with GitHub - **NO JSON keys stored in GitHub!**

This is the **most secure** method because:
- ✅ No secrets exposed in GitHub
- ✅ No key rotation needed
- ✅ Works with fork contributions (Dependabot, etc.)
- ✅ Automatic token exchange via OIDC
- ✅ Audit trail in GCP Cloud Audit Logs

---

## ⚠️ Important: OIDC Parameter Names

The GitHub Actions `google-github-actions/auth@v2` uses these exact parameter names:
- `workload_identity_provider` ← Correct
- `service_account` ← Correct (NOT `service_account_email`)
- `audience` ← Optional

These are used in workflows, not the secret names!

---

## How OIDC Works

```
GitHub Actions
    ↓
  Requests token from GitHub
    ↓
  GitHub issues OIDC token
    ↓
  Workflow sends token to GCP
    ↓
  GCP verifies token signature
    ↓
  GCP issues temporary access token
    ↓
  Workflow uses access token for 1 hour
    ↓
  Token expires (no refresh, no keys stored)
```

---

## Quick Setup (Automated)

### 1. Run Setup Script

```bash
# Clone repository (if you haven't)
git clone https://github.com/YOUR_USERNAME/voting-app.git
cd voting-app

# Run setup script
bash scripts/setup-oidc-github.sh
```

### 2. Follow Prompts

```
Enter GCP Project ID: voting-app-prod
Enter GitHub repository owner: octaviansandulescu
Enter GitHub repository name: voting-app
```

### 3. Copy Secrets

Script will output:

```
WORKLOAD_IDENTITY_PROVIDER=projects/123456789/locations/global/workloadIdentityPools/github-pool/providers/github
SERVICE_ACCOUNT_EMAIL=github-actions-oidc@voting-app-prod.iam.gserviceaccount.com
```

### 4. Add to GitHub Secrets

1. Go to: https://github.com/YOUR_USERNAME/voting-app/settings/secrets/actions
2. Click "New repository secret"
3. Add Secret #1:
   - Name: `WORKLOAD_IDENTITY_PROVIDER`
   - Value: (paste from script output)
4. Click "New repository secret"
5. Add Secret #2:
   - Name: `SERVICE_ACCOUNT_EMAIL`
   - Value: (paste from script output)

### 5. Test

Push to `main` branch and watch GitHub Actions run!

---

## Manual Setup (Detailed)

If you prefer to set up manually:

### Step 1: Enable APIs

```bash
export PROJECT_ID="voting-app-prod"

gcloud services enable iamcredentials.googleapis.com \
  --project=$PROJECT_ID

gcloud services enable cloudresourcemanager.googleapis.com \
  --project=$PROJECT_ID

gcloud services enable sts.googleapis.com \
  --project=$PROJECT_ID
```

### Step 2: Create Workload Identity Pool

```bash
gcloud iam workload-identity-pools create github-pool \
  --location=global \
  --display-name="GitHub Actions" \
  --project=$PROJECT_ID

# Get project number (you'll need it)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
echo "Project Number: $PROJECT_NUMBER"
```

### Step 3: Create OIDC Provider

```bash
export GITHUB_OWNER="octaviansandulescu"

gcloud iam workload-identity-pools providers create-oidc github \
  --location=global \
  --workload-identity-pool=github-pool \
  --display-name="GitHub" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.aud=assertion.aud,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --issuer-uri=https://token.actions.githubusercontent.com \
  --project=$PROJECT_ID \
  --attribute-condition="assertion.repository_owner == '${GITHUB_OWNER}'"
```

### Step 4: Create Service Account

```bash
gcloud iam service-accounts create github-actions-oidc \
  --display-name="GitHub Actions OIDC" \
  --project=$PROJECT_ID

export SA_EMAIL="github-actions-oidc@${PROJECT_ID}.iam.gserviceaccount.com"
```

### Step 5: Grant Permissions

```bash
# GCR (Docker image push)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.admin"

# GKE (Kubernetes deployment)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/container.developer"

# Cloud SQL (database access)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/cloudsql.client"
```

### Step 6: Link Repository to Service Account

```bash
export GITHUB_REPOSITORY="octaviansandulescu/voting-app"
export POOL_NAME="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-pool"

gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL \
  --project=$PROJECT_ID \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${POOL_NAME}/attribute.repository/${GITHUB_REPOSITORY}"
```

### Step 7: Get Configuration Values

```bash
# For GitHub Secrets
echo "WORKLOAD_IDENTITY_PROVIDER=${POOL_NAME}/providers/github"
echo "SERVICE_ACCOUNT_EMAIL=${SA_EMAIL}"
```

### Step 8: Add to GitHub Secrets

Go to: https://github.com/YOUR_USERNAME/voting-app/settings/secrets/actions

Add:
1. `WORKLOAD_IDENTITY_PROVIDER` = (value from Step 7)
2. `SERVICE_ACCOUNT_EMAIL` = (value from Step 7)

---

## Verify Setup

### Check Workload Identity Pool

```bash
gcloud iam workload-identity-pools describe github-pool \
  --location=global \
  --project=$PROJECT_ID
```

### Check OIDC Provider

```bash
gcloud iam workload-identity-pools providers describe-oidc github \
  --location=global \
  --workload-identity-pool=github-pool \
  --project=$PROJECT_ID
```

### Check Service Account IAM Bindings

```bash
gcloud iam service-accounts get-iam-policy github-actions-oidc@${PROJECT_ID}.iam.gserviceaccount.com
```

### Check Roles

```bash
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten=bindings[].members \
  --format='table(bindings.role)' \
  --filter="bindings.members:serviceAccount:github-actions-oidc@${PROJECT_ID}.iam.gserviceaccount.com"
```

---

## Test Pipeline

### 1. Trigger CI Test (No GCP needed)

```bash
# Make a change to backend
echo "# test" >> src/backend/main.py
git add src/backend/main.py
git commit -m "test: trigger CI"
git push origin main
```

Watch: https://github.com/YOUR_USERNAME/voting-app/actions

### 2. Check Logs

```bash
# GitHub Actions logs will show:
# ✓ Authenticate to Google Cloud (OIDC)
# ✓ Set up Cloud SDK
# ✓ Build Backend Image
# ✓ Push Backend Image
```

### 3. Verify in GCP

```bash
# Check GCR images
gcloud container images list --project=$PROJECT_ID

# Check GCR image tags
gcloud container images list-tags gcr.io/$PROJECT_ID/voting-app-backend
```

### 4. Check Deployment

```bash
# Get pod status
kubectl -n voting-app get pods -w

# Check deployment history
kubectl -n voting-app rollout history deployment/voting-app-backend

# View logs
kubectl -n voting-app logs -l app=voting-app-backend --tail=50
```

---

## Troubleshooting

### Error: "OIDC token exchange failed"

**Problem:** Workload Identity Provider not accepting tokens

**Solution:**
1. Check attribute-condition in OIDC provider:
```bash
gcloud iam workload-identity-pools providers describe-oidc github \
  --location=global \
  --workload-identity-pool=github-pool \
  --project=$PROJECT_ID \
  --format=json | jq '.attributeCondition'
```

2. Verify repository_owner matches:
```bash
# Should output your GitHub username
echo $GITHUB_OWNER
```

### Error: "Service account not found"

**Problem:** Wrong service account email

**Solution:**
```bash
# List service accounts
gcloud iam service-accounts list --project=$PROJECT_ID

# Use the full email address in secrets
```

### Error: "Permission denied: Failed to build image"

**Problem:** Service account missing GCR permissions

**Solution:**
```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.admin"
```

### Error: "Cluster not found"

**Problem:** Wrong cluster name or zone

**Solution:**
```bash
# List clusters
gcloud container clusters list --project=$PROJECT_ID

# Update deploy.yml with correct values
```

### Logs show "gcloud: command not found"

**Problem:** gcloud not installed in runner

**Solution:** Already included in workflow! Check this step:
```yaml
- name: Set up Cloud SDK
  uses: google-github-actions/setup-gcloud@v2
```

---

## Security Best Practices

### 1. Restrict Repository Access

Only allow specific repository:
```bash
# Already done with attribute-condition in OIDC provider
# Verify with:
gcloud iam workload-identity-pools providers describe-oidc github \
  --location=global \
  --workload-identity-pool=github-pool \
  --project=$PROJECT_ID \
  --format=json | jq '.attributeCondition'
```

### 2. Use Least Privilege Roles

Don't use `roles/editor` or `roles/owner`:
```bash
# Good - specific roles only
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.admin"  # Only for GCR

# Bad - too broad
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/editor"
```

### 3. Audit Access

Check who deployed what:
```bash
# View Cloud Audit Logs
gcloud logging read \
  "resource.type=k8s_cluster AND protoPayload.authenticationInfo.principalEmail=github-actions-oidc@${PROJECT_ID}.iam.gserviceaccount.com" \
  --limit=10 \
  --format=json
```

### 4. Monitor Token Usage

```bash
# Check recent authentications
gcloud logging read \
  "resource.type=k8s_cluster" \
  --format="table(timestamp, protoPayload.methodName, protoPayload.authenticationInfo.principalEmail)" \
  --limit=20
```

### 5. Rotate Roles Periodically

Review service account permissions quarterly:
```bash
gcloud iam service-accounts get-iam-policy $SA_EMAIL
```

---

## Clean Up (if needed)

### Remove OIDC Setup

```bash
# Delete service account (careful!)
gcloud iam service-accounts delete $SA_EMAIL --project=$PROJECT_ID

# Delete OIDC provider (optional)
gcloud iam workload-identity-pools providers delete github \
  --location=global \
  --workload-identity-pool=github-pool \
  --project=$PROJECT_ID

# Delete Workload Identity Pool (optional)
gcloud iam workload-identity-pools delete github-pool \
  --location=global \
  --project=$PROJECT_ID
```

### Remove GitHub Secrets

1. Go to: https://github.com/YOUR_USERNAME/voting-app/settings/secrets/actions
2. Delete `WORKLOAD_IDENTITY_PROVIDER`
3. Delete `SERVICE_ACCOUNT_EMAIL`

---

## Comparison: OIDC vs JSON Keys

| Feature | OIDC | JSON Keys |
|---------|------|-----------|
| Keys stored in GitHub | ❌ No | ⚠️ Yes |
| Risk if exposed | ✅ None | ❌ High |
| Works with forks | ✅ Yes | ❌ No |
| Token expiration | ✅ 1 hour | ⚠️ No (key valid forever) |
| Audit trail | ✅ Yes | ✅ Yes |
| Setup complexity | ⚠️ Medium | ✅ Easy |
| Recommended | ✅ YES | ❌ Old method |

---

## Next Steps

1. ✅ Run `bash scripts/setup-oidc-github.sh`
2. ✅ Add secrets to GitHub
3. ✅ Push to main branch
4. ✅ Watch workflows run in GitHub Actions
5. ✅ Verify deployment in GKE
6. ✅ Monitor with Prometheus/Grafana

**No JSON keys = More Secure! 🔐**

