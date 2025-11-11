# Phase 3.1: Testing & CI/CD Automation Guide

**Estimated Time**: 10 minutes | **Difficulty**: Intermediate | **Prerequisites**: All deployment guides

## Overview

In this guide, you'll set up GitHub Actions to automatically test and deploy your application. This is the final piece of professional DevOPS - continuous integration and continuous deployment (CI/CD).

**What you'll learn**:
- ✅ How GitHub Actions CI/CD works
- ✅ How to write GitHub Actions workflows
- ✅ How to automatically run tests on every push
- ✅ How to build and push Docker images
- ✅ How to deploy to production automatically
- ✅ How to prevent broken code from reaching production

## Prerequisites

Before starting, ensure you have:

```bash
# Required
git --version                    # Git is installed
gh --version                     # GitHub CLI (optional but helpful)
your repository pushed to github # Code is on GitHub
```

**System Requirements**:
- GitHub account with repository access
- Repository admin permissions (to add secrets)
- GCP project credentials (service account JSON)

## Understanding CI/CD

### The CI/CD Pipeline

```
Developer Pushes Code
         ↓
GitHub detects push
         ↓
Runs Tests Automatically
         ↓
Build Docker Images ────→ [FAILED] → Notify Developer, Stop
         ↓
Push to Registry
         ↓
Deploy to Staging ────→ [FAILED] → Notify Developer, Stop
         ↓
Deploy to Production
         ↓
Notify: Deployment Successful ✅
```

### Why CI/CD?

✅ **Prevents bugs**: Tests run automatically before deployment  
✅ **Faster releases**: Deploy multiple times per day  
✅ **Reduces manual errors**: Automation instead of humans  
✅ **Audit trail**: Every deployment is logged  
✅ **Rollback capability**: Easy to revert bad deployments  

## Step 1: Prepare GitHub Repository

### 1.1 Ensure Repository Structure

```bash
# Your repo should have:
# .github/workflows/  ← We'll create workflow files here
# src/backend/        ← Backend code
# src/frontend/       ← Frontend code
# docker-compose.yml  ← Docker config
# 3-KUBERNETES/k8s/   ← Kubernetes manifests
```

Verify:
```bash
ls -la .github/
ls -la src/
ls -la 3-KUBERNETES/
```

### 1.2 Create .github/workflows Directory

```bash
mkdir -p .github/workflows
```

## Step 2: Add GitHub Secrets

### 2.1 What Secrets Do We Need?

These should NEVER be in code:
- GCP project ID
- GCP service account JSON
- Docker registry credentials
- Database passwords
- API keys
- SSH keys

### 2.2 Add Secrets via GitHub Web UI

1. Go to your GitHub repository
2. Settings → Secrets and variables → Actions
3. Click "New repository secret"

Add these secrets:

| Secret Name | Value | Example |
|------------|-------|---------|
| `GCP_PROJECT_ID` | Your GCP project ID | `voting-app-prod-12345` |
| `GCP_SA_KEY` | Service account JSON | `{...}` (contents of service account JSON) |
| `DOCKER_REGISTRY_PASSWORD` | Base64 encoded or token | (optional, GCR uses GCP_SA_KEY) |

### 2.3 Create GCP Service Account (if needed)

```bash
# If you don't have a service account yet
PROJECT_ID=$(gcloud config get-value project)

# Create service account
gcloud iam service-accounts create github-actions \
  --display-name="GitHub Actions CI/CD"

# Grant necessary roles
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member=serviceAccount:github-actions@${PROJECT_ID}.iam.gserviceaccount.com \
  --role=roles/container.developer

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member=serviceAccount:github-actions@${PROJECT_ID}.iam.gserviceaccount.com \
  --role=roles/storage.admin

# Create key
gcloud iam service-accounts keys create ~/github-actions-key.json \
  --iam-account=github-actions@${PROJECT_ID}.iam.gserviceaccount.com

# Get contents (this is what goes in GCP_SA_KEY secret)
cat ~/github-actions-key.json

# Copy entire output to GitHub secret GCP_SA_KEY
```

## Step 3: Create CI/CD Workflow File

### 3.1 Create Test Workflow

```bash
cat > .github/workflows/ci-test.yml << 'EOF'
name: CI - Test

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'src/backend/**'
      - 'src/frontend/**'
      - 'tests/**'
      - '.github/workflows/ci-test.yml'
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: voting_app_test
          MYSQL_USER: voting_user
          MYSQL_PASSWORD: voting_password_test
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=3
        ports:
          - 3306:3306

    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        working-directory: ./src/backend
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
      
      - name: Create database tables
        run: |
          mysql -h 127.0.0.1 -u voting_user -pvoking_password_test voting_app_test < src/backend/schema.sql
      
      - name: Run tests with coverage
        working-directory: ./src/backend
        env:
          DATABASE_HOST: 127.0.0.1
          DATABASE_USER: voting_user
          DATABASE_PASSWORD: voting_password_test
          DATABASE_NAME: voting_app_test
          DEPLOYMENT_MODE: testing
        run: |
          pytest tests/ \
            --cov=. \
            --cov-report=xml \
            --cov-report=html \
            -v
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./src/backend/coverage.xml
          flags: unittests
          name: codecov-umbrella
          fail_ci_if_error: false

EOF

cat .github/workflows/ci-test.yml
```

### 3.2 Commit Workflow File

```bash
git add .github/workflows/ci-test.yml
git commit -m "Add: GitHub Actions CI test workflow"
git push origin main
```

## Step 4: Create Build & Push Workflow

### 4.1 Create Build Workflow

```bash
cat > .github/workflows/build-push.yml << 'EOF'
name: Build & Push Docker Images

on:
  push:
    branches: [ main ]
    paths:
      - 'src/backend/**'
      - 'src/frontend/**'
      - '.github/workflows/build-push.yml'
      - 'docker-compose.yml'
  workflow_run:
    workflows: ["CI - Test"]
    types: [completed]
    branches: [main]

env:
  REGISTRY: gcr.io
  IMAGE_TAG: ${{ github.sha }}

jobs:
  build-push:
    runs-on: ubuntu-latest
    if: github.event_name == 'push' || github.event.workflow_run.conclusion == 'success'
    
    permissions:
      contents: read
      id-token: write

    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v1
        with:
          service_account_key: ${{ secrets.GCP_SA_KEY }}
          project_id: ${{ secrets.GCP_PROJECT_ID }}
          export_default_credentials: true
      
      - name: Configure Docker for GCR
        run: |
          gcloud auth configure-docker
      
      - name: Build Backend Image
        run: |
          docker build \
            -t ${{ env.REGISTRY }}/${{ secrets.GCP_PROJECT_ID }}/voting-app-backend:${{ env.IMAGE_TAG }} \
            -t ${{ env.REGISTRY }}/${{ secrets.GCP_PROJECT_ID }}/voting-app-backend:latest \
            -f src/backend/Dockerfile \
            src/backend/
      
      - name: Build Frontend Image
        run: |
          docker build \
            -t ${{ env.REGISTRY }}/${{ secrets.GCP_PROJECT_ID }}/voting-app-frontend:${{ env.IMAGE_TAG }} \
            -t ${{ env.REGISTRY }}/${{ secrets.GCP_PROJECT_ID }}/voting-app-frontend:latest \
            -f src/frontend/Dockerfile \
            src/frontend/
      
      - name: Push Backend Image
        run: |
          docker push ${{ env.REGISTRY }}/${{ secrets.GCP_PROJECT_ID }}/voting-app-backend:${{ env.IMAGE_TAG }}
          docker push ${{ env.REGISTRY }}/${{ secrets.GCP_PROJECT_ID }}/voting-app-backend:latest
      
      - name: Push Frontend Image
        run: |
          docker push ${{ env.REGISTRY }}/${{ secrets.GCP_PROJECT_ID }}/voting-app-frontend:${{ env.IMAGE_TAG }}
          docker push ${{ env.REGISTRY }}/${{ secrets.GCP_PROJECT_ID }}/voting-app-frontend:latest
      
      - name: Output Image Details
        run: |
          echo "Backend Image: ${{ env.REGISTRY }}/${{ secrets.GCP_PROJECT_ID }}/voting-app-backend:${{ env.IMAGE_TAG }}"
          echo "Frontend Image: ${{ env.REGISTRY }}/${{ secrets.GCP_PROJECT_ID }}/voting-app-frontend:${{ env.IMAGE_TAG }}"

EOF

cat .github/workflows/build-push.yml
```

### 4.2 Commit Build Workflow

```bash
git add .github/workflows/build-push.yml
git commit -m "Add: GitHub Actions build and push workflow"
git push origin main
```

## Step 5: Create Deployment Workflow

### 5.1 Create Deploy Workflow

```bash
cat > .github/workflows/deploy.yml << 'EOF'
name: Deploy to GKE

on:
  push:
    branches: [ main ]
    paths:
      - 'src/backend/**'
      - 'src/frontend/**'
      - '3-KUBERNETES/**'
      - '.github/workflows/deploy.yml'
  workflow_run:
    workflows: ["Build & Push Docker Images"]
    types: [completed]
    branches: [main]

env:
  REGISTRY: gcr.io
  IMAGE_TAG: ${{ github.sha }}
  CLUSTER_NAME: voting-app-cluster
  CLUSTER_ZONE: us-central1-a
  DEPLOYMENT_NAMESPACE: voting-app

jobs:
  deploy:
    runs-on: ubuntu-latest
    if: github.event_name == 'push' || github.event.workflow_run.conclusion == 'success'
    
    permissions:
      contents: read
      id-token: write

    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v1
        with:
          service_account_key: ${{ secrets.GCP_SA_KEY }}
          project_id: ${{ secrets.GCP_PROJECT_ID }}
      
      - name: Get GKE Credentials
        run: |
          gcloud container clusters get-credentials ${{ env.CLUSTER_NAME }} \
            --zone ${{ env.CLUSTER_ZONE }} \
            --project ${{ secrets.GCP_PROJECT_ID }}
      
      - name: Update Backend Image
        run: |
          kubectl -n ${{ env.DEPLOYMENT_NAMESPACE }} set image \
            deployment/voting-app-backend \
            voting-app-backend=${{ env.REGISTRY }}/${{ secrets.GCP_PROJECT_ID }}/voting-app-backend:${{ env.IMAGE_TAG }} \
            --record
      
      - name: Update Frontend Image
        run: |
          kubectl -n ${{ env.DEPLOYMENT_NAMESPACE }} set image \
            deployment/voting-app-frontend \
            voting-app-frontend=${{ env.REGISTRY }}/${{ secrets.GCP_PROJECT_ID }}/voting-app-frontend:${{ env.IMAGE_TAG }} \
            --record
      
      - name: Wait for Rollout
        run: |
          kubectl -n ${{ env.DEPLOYMENT_NAMESPACE }} rollout status \
            deployment/voting-app-backend --timeout=5m
          kubectl -n ${{ env.DEPLOYMENT_NAMESPACE }} rollout status \
            deployment/voting-app-frontend --timeout=5m
      
      - name: Verify Deployment
        run: |
          kubectl -n ${{ env.DEPLOYMENT_NAMESPACE }} get pods
          kubectl -n ${{ env.DEPLOYMENT_NAMESPACE }} get services
      
      - name: Post Success Comment
        if: success()
        run: |
          echo "✅ Deployment successful!"
          echo "Images deployed:"
          echo "  Backend: ${{ env.REGISTRY }}/${{ secrets.GCP_PROJECT_ID }}/voting-app-backend:${{ env.IMAGE_TAG }}"
          echo "  Frontend: ${{ env.REGISTRY }}/${{ secrets.GCP_PROJECT_ID }}/voting-app-frontend:${{ env.IMAGE_TAG }}"
      
      - name: Notify on Failure
        if: failure()
        run: |
          echo "❌ Deployment failed!"
          echo "Rollback deployment with:"
          echo "  kubectl rollout undo deployment/voting-app-backend -n ${{ env.DEPLOYMENT_NAMESPACE }}"

EOF

cat .github/workflows/deploy.yml
```

### 5.2 Commit Deploy Workflow

```bash
git add .github/workflows/deploy.yml
git commit -m "Add: GitHub Actions deployment workflow"
git push origin main
```

## Step 6: Monitor CI/CD Pipeline

### 6.1 View Workflow Runs

1. Go to your GitHub repository
2. Click "Actions" tab
3. You should see your workflows

Each workflow shows:
- ✅ Successful runs (green)
- ❌ Failed runs (red)
- ⏳ Running jobs (yellow)

### 6.2 View Workflow Details

Click on any workflow run to see:
- Test results
- Build logs
- Deployment status
- Artifact storage
- Logs from each step

### 6.3 Troubleshoot Failures

```bash
# If tests fail, check:
1. Click failed workflow
2. Click "Test" job
3. Expand sections to see error logs
4. Common issues:
   - Database connection failed
   - Python dependencies missing
   - Import errors
```

## Step 7: Set Up Status Checks

### 7.1 Require Checks Before Merge

1. Go to Settings → Branches
2. Click "Add rule"
3. Create rule for "main" branch:
   - Require status checks to pass: ✅
   - Select "CI - Test" ✅
   - Select "Build & Push Docker Images" ✅
   - Require approval before merge: ✅

This prevents broken code from reaching main!

## Step 8: CI/CD Best Practices

### 8.1 What the Pipeline Does

**On Every Push to `main`**:
1. ✅ Run all tests
2. ✅ Generate coverage report
3. ✅ Build Docker images
4. ✅ Push to Google Container Registry
5. ✅ Deploy to GKE
6. ✅ Wait for pods to be ready
7. ✅ Verify deployment succeeded

**If Any Step Fails**:
- 🛑 Stop the pipeline
- 📧 Notify developer (via GitHub UI)
- 🚫 Don't deploy to production

### 8.2 Commit Message Best Practices

```bash
# Good commit messages (descriptive)
git commit -m "Fix: database connection timeout in voting endpoint"
git commit -m "Feature: add statistics endpoint with vote breakdown"
git commit -m "Test: add security tests for SQL injection prevention"

# Bad commit messages (too vague)
git commit -m "fix stuff"
git commit -m "updates"
git commit -m "wip"
```

### 8.3 Branch Strategy

```bash
# Typical workflow:
1. Create feature branch
   git checkout -b feature/new-endpoint

2. Make changes and commit
   git commit -m "Feature: add statistics endpoint"

3. Push to GitHub
   git push origin feature/new-endpoint

4. Create Pull Request on GitHub
   - Request review
   - Wait for CI to pass
   - Address comments

5. Merge to main (via GitHub UI)
   - CI automatically runs on merge
   - If all checks pass, deployment happens
```

## Step 9: Viewing Test Results

### 9.1 Coverage Reports

After tests pass, check coverage:

```bash
# Inside GitHub Actions workflow
# Coverage is uploaded to Codecov
# See: codecov.io/gh/YOUR_USERNAME/voting-app
```

### 9.2 Test Logs

View detailed test output:

1. Go to Actions → Select workflow
2. Click "Test" job
3. Expand "Run tests with coverage" step
4. See all test results

Example:
```
tests/test_api.py::test_health_endpoint PASSED
tests/test_api.py::test_vote_submission PASSED
tests/test_api.py::test_results_endpoint PASSED
tests/test_database.py::test_database_connection PASSED

========== 4 passed in 0.82s ==========
Coverage: 95%
```

## Step 10: Manual Workflow Triggers

### 10.1 Trigger Workflow Manually

In GitHub Actions UI:
1. Click "Run workflow"
2. Select branch
3. Click "Run workflow" button

This is useful for:
- Testing after a failed deployment
- Redeploying without code changes
- Testing new secrets

## Step 11: Secrets Management in CI/CD

### Security Best Practices

✅ **DO**:
- Store all sensitive data in GitHub Secrets
- Use service accounts with minimum permissions
- Rotate service account keys regularly
- Audit who has access to secrets
- Use masked secrets in logs

❌ **DON'T**:
- Commit `.env` files
- Commit service account keys
- Log secrets in workflow output
- Hardcode passwords in YAML files
- Share secrets via Slack/email

### 11.1 Mask Secrets in Logs

GitHub automatically masks secrets, but to be extra safe:

```yaml
# In workflow YAML:
- name: My Step
  run: |
    echo "::add-mask::${{ secrets.MY_SECRET }}"
    # Now the secret value won't appear in logs
```

## Step 12: Monitoring and Alerts

### 12.1 Workflow Status

Check status badges in your README:

```markdown
[![CI - Test](https://github.com/YOUR_USERNAME/voting-app/actions/workflows/ci-test.yml/badge.svg?branch=main)](https://github.com/YOUR_USERNAME/voting-app/actions)

[![Build & Push](https://github.com/YOUR_USERNAME/voting-app/actions/workflows/build-push.yml/badge.svg?branch=main)](https://github.com/YOUR_USERNAME/voting-app/actions)
```

### 12.2 Email Notifications

GitHub can notify you of:
- ✅ Successful deployments
- ❌ Failed tests
- ⚠️ Manual review required

Configure in GitHub Settings → Notifications

## Step 13: Troubleshooting Workflows

### Issue: Tests fail in CI but pass locally

```bash
# Common causes:
1. Database not initialized in CI
   → Check service setup in workflow

2. Different Python version in CI
   → Ensure python-version matches local

3. Missing environment variables
   → Add to workflow or GitHub secrets

4. Race condition in tests
   → Tests aren't idempotent
   → Add setup/teardown
```

### Issue: Docker build fails in GitHub Actions

```bash
# Common causes:
1. Missing Dockerfile
   → Verify path in workflow

2. Build context wrong
   → Check working-directory

3. Secret not available
   → Verify secret name in GitHub

4. Docker authentication failed
   → Check GCP_SA_KEY secret
```

### Issue: GKE deployment fails

```bash
# Common causes:
1. Cluster doesn't exist
   → Verify cluster name and zone

2. Service account permissions
   → Add missing IAM roles

3. Namespace doesn't exist
   → Apply namespace manifest first

4. Image not found
   → Verify image pushed to GCR
```

## Step 14: Workflow Diagram

```
┌─────────────────────────────────────────────────────┐
│  Developer Pushes Code to GitHub                    │
└──────────────────┬──────────────────────────────────┘
                   ↓
        ┌──────────────────────┐
        │  CI - Test Workflow  │
        │  - Run pytest        │
        │  - Generate coverage │
        └──────────┬───────────┘
                   ↓
         ┌─────────────────────┐
         │  Tests Pass? ──NO──→ Stop, Notify ❌
         └──────────┬──────────┘
                    │ YES
                    ↓
        ┌─────────────────────────────────────┐
        │  Build & Push Docker Images Workflow│
        │  - Build backend image              │
        │  - Build frontend image             │
        │  - Push to Google Container Registry│
        └──────────┬──────────────────────────┘
                   ↓
        ┌──────────────────────┐
        │  Build Success? ─NO→  Stop, Notify ❌
        └──────────┬───────────┘
                   │ YES
                   ↓
        ┌───────────────────────────────┐
        │  Deploy to GKE Workflow       │
        │  - Get cluster credentials    │
        │  - Update deployments         │
        │  - Wait for rollout           │
        │  - Verify pods running        │
        └──────────┬────────────────────┘
                   ↓
        ┌──────────────────────┐
        │  Deploy Success? ─NO→ Rollback, Notify ❌
        └──────────┬───────────┘
                   │ YES
                   ↓
           ✅ Deployment Complete!
```

## Security Checklist - CI/CD

- ✅ All secrets in GitHub Secrets (not in code)
- ✅ Service account has minimum required permissions
- ✅ Tests pass in CI before deployment
- ✅ No hardcoded credentials in workflows
- ✅ Branch protection requires status checks
- ✅ Pull request reviews required
- ✅ Audit logs for all deployments
- ✅ Rollback procedure tested

## Next Steps

Congratulations! Your CI/CD pipeline is live! 🎉

**What you've accomplished**:
- ✅ Automated testing on every push
- ✅ Automated Docker builds
- ✅ Automated deployments to production
- ✅ Prevented broken code from reaching main

**What's next?**
1. Monitor your pipeline with alerts
2. Set up monitoring dashboard (Prometheus + Grafana)
3. Document your processes
4. Train team members

**Ready for monitoring?** → Move to `docs/guides/MONITORING_SETUP.md`

## Resources

- **GitHub Actions Documentation**: https://docs.github.com/en/actions
- **Google Cloud Build**: https://cloud.google.com/build/docs
- **CI/CD Best Practices**: https://martinfowler.com/articles/continuousIntegration.html
- **Deployment Strategies**: https://semver.org/

---

**Questions?** Review TESTING_FUNDAMENTALS.md or SECURITY.md

**Ready for monitoring?** Continue to `docs/guides/MONITORING_SETUP.md` →
