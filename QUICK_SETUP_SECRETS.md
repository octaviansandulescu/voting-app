# Quick GitHub Secrets Setup (5 minutes)

## What You Need

To enable GitHub Actions CI/CD with GCP, you need to add 2 secrets to your GitHub repository.

---

## Step 1: Generate Secrets (GCP - 3 minutes)

Run this command in your terminal:

```bash
bash scripts/setup-oidc-github.sh
```

Follow the prompts:
```
Enter GCP Project ID: voting-app-prod
Enter GitHub repository owner: YOUR_USERNAME
Enter GitHub repository name: voting-app
```

The script will output 2 lines like this:

```
WORKLOAD_IDENTITY_PROVIDER=projects/123456789/locations/global/workloadIdentityPools/github-pool/providers/github
SERVICE_ACCOUNT_EMAIL=github-actions-oidc@voting-app-prod.iam.gserviceaccount.com
```

**Copy these values!** (or leave the terminal open)

---

## Step 2: Add Secrets to GitHub (2 minutes)

### Method A: Via GitHub Web UI (Easy)

1. Go to: https://github.com/YOUR_USERNAME/voting-app/settings/secrets/actions

2. Click **"New repository secret"**

3. **Secret #1:**
   - Name: `WORKLOAD_IDENTITY_PROVIDER`
   - Value: (paste the full `projects/123456789/...` value from script)
   - Click **"Add secret"**

4. Click **"New repository secret"** again

5. **Secret #2:**
   - Name: `SERVICE_ACCOUNT_EMAIL`
   - Value: (paste the `github-actions-oidc@...` value from script)
   - Click **"Add secret"**

### Method B: Via GitHub CLI (If you prefer)

```bash
# Install GitHub CLI if needed
# brew install gh  (macOS)
# apt install gh   (Linux)

# Authenticate
gh auth login

# Add secrets
gh secret set WORKLOAD_IDENTITY_PROVIDER --body "projects/123456789/locations/global/workloadIdentityPools/github-pool/providers/github" --repo YOUR_USERNAME/voting-app

gh secret set SERVICE_ACCOUNT_EMAIL --body "github-actions-oidc@voting-app-prod.iam.gserviceaccount.com" --repo YOUR_USERNAME/voting-app
```

---

## Step 3: Verify Setup

1. Make a small change to your code:
```bash
echo "# test" >> src/backend/main.py
git add src/backend/main.py
git commit -m "test: trigger workflows"
git push origin main
```

2. Go to: https://github.com/YOUR_USERNAME/voting-app/actions

3. Watch workflows run:
   - ✅ **CI - Test** (always runs, ~2 min) - Tests your code
   - 🟡 **Build & Push** (if secrets set, ~5 min) - Builds Docker images
   - 🟡 **Deploy** (if secrets set, ~5 min) - Deploys to GKE

---

## What Happens

### If Secrets ARE Set (Full CI/CD):
```
1. Push code → CI - Test ✅ (2 min)
   ↓
2. Tests pass → Build & Push ✅ (5 min)
   ↓
3. Build complete → Deploy ✅ (5 min)
   ↓
4. App updates on GKE! 🎉
```

### If Secrets are NOT Set (Testing only):
```
1. Push code → CI - Test ✅ (2 min)
   ↓
2. Build & Push ⏭️ (Skipped - shows setup instructions)
   ↓
3. Deploy ⏭️ (Skipped - shows setup instructions)
```

---

## Troubleshooting

### "Workflow still fails"

1. Verify secrets were added:
   - Go to: Settings → Secrets and variables → Actions
   - You should see both secrets listed

2. Check workflows have correct syntax:
   - Go to: Actions → CI - Test (or Build & Push)
   - Look for error messages

3. Try again:
   - Make another commit and push
   - Workflows should run automatically

### "Script says 'command not found: gcloud'"

Need to install Google Cloud SDK:

```bash
# macOS
brew install google-cloud-sdk

# Linux (Debian/Ubuntu)
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt update && sudo apt install google-cloud-sdk

# Then authenticate
gcloud auth login
```

### "Script says 'permission denied'"

Make script executable:
```bash
chmod +x scripts/setup-oidc-github.sh
bash scripts/setup-oidc-github.sh
```

---

## What Each Secret Does

### WORKLOAD_IDENTITY_PROVIDER
- **What:** GCP Workload Identity Pool configuration
- **Why:** Tells GCP where tokens come from (GitHub)
- **Format:** `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github`

### SERVICE_ACCOUNT_EMAIL
- **What:** GCP Service Account email
- **Why:** Tells GitHub which service account to use
- **Format:** `github-actions-oidc@PROJECT_ID.iam.gserviceaccount.com`

---

## No Secrets Stored!

⚠️ **IMPORTANT:** These are NOT sensitive data!

- ✅ `WORKLOAD_IDENTITY_PROVIDER` - Public information (can't be used alone)
- ✅ `SERVICE_ACCOUNT_EMAIL` - Public information (can't be used alone)
- ❌ No JSON keys stored anywhere
- ❌ No passwords stored anywhere
- ✅ Fully secure OIDC setup!

Only tokens are exchanged automatically between GitHub and GCP. Tokens expire in 1 hour.

---

## Next Steps

1. ✓ Run setup script
2. ✓ Add secrets to GitHub
3. ✓ Push code to test
4. ✓ Watch GitHub Actions run
5. ✓ Monitor deployment in GKE

**Done! You have a production-ready CI/CD pipeline! 🎉**

---

## Still Need Help?

- Full guide: [docs/guides/GITHUB_OIDC_SETUP.md](../guides/GITHUB_OIDC_SETUP.md)
- Troubleshooting: [docs/guides/GITHUB_ACTIONS_SETUP.md](../guides/GITHUB_ACTIONS_SETUP.md)
- Code: [.github/workflows/](.../.github/workflows/)
