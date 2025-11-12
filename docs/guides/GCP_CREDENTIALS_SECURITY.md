# GCP Credentials Security Guide

**CRITICAL**: Never commit GCP service account keys to GitHub!

---

## Overview

GCP credentials contain sensitive authentication material:
- 🔐 Private encryption keys
- 🔐 OAuth tokens
- 🔐 API access permissions
- 🔐 Project identifiers

**These must be protected!**

---

## Local Setup

### 1. Create Secure Credentials Directory

```bash
# Create directory outside of repository
mkdir -p ~/certs
chmod 700 ~/certs   # Only you can read/write
```

**Location**: `~/certs/` (outside voting-app directory)  
**Why**: Prevents accidental commits if directory is moved

### 2. Get Service Account Key from GCP

**Step by step**:

1. Go to [GCP Console](https://console.cloud.google.com/)
2. Select your project
3. Navigate to **Service Accounts** (APIs & Services → Service Accounts)
4. Select your service account
5. Go to **Keys** tab
6. Click **Create new key** → **JSON**
7. Save to `~/certs/`

**File format**: `{project-id}-key.json` or similar

### 3. Set Secure Permissions

```bash
# Make key readable only by you
chmod 600 ~/certs/*.json

# Verify
ls -la ~/certs/
# Output should show: -rw------- (600 permissions)
```

### 4. Use with Deployment Scripts

**Option A: Set environment variable**
```bash
export GCP_CREDENTIALS="$HOME/certs/diesel-skyline-474415-j6-5e5f35b560dc.json"
./scripts/deployment/start-deployment.sh
```

**Option B: Auto-detection**
```bash
# Scripts automatically find *-diesel*.json in ~/certs/
./scripts/deployment/start-deployment.sh
```

**Option C: Application Default Credentials**
```bash
gcloud auth application-default login
./scripts/deployment/start-deployment.sh
```

---

## Git Protection

### .gitignore Configuration

All credential files are protected:

```gitignore
# GCP Credentials - CRITICAL SECURITY!
*.json                           # All JSON files
certs/                          # Entire certs directory
3-KUBERNETES/terraform/*.json   # Terraform JSON files
3-KUBERNETES/terraform/terraform.tfvars  # Terraform variables
```

### Verify Protection

```bash
# Check if credentials would be committed
git status

# Should show:
# nothing to commit (working tree clean)
# OR
# Untracked files (not staged)

# These should NOT appear:
# modified:   certs/key.json
# new file:   key.json
```

### Emergency: If Accidentally Committed

```bash
# 1. Remove from git history
git rm --cached ~/certs/*.json
git commit -m "Remove accidentally committed credentials"

# 2. Rotate the key IMMEDIATELY
# - Go to GCP Console
# - Delete the exposed key
# - Create a new one
# - Update local copy

# 3. Force push (if private repo)
git push --force origin main
```

---

## Environment Variables

### For Local Development

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# GCP Credentials (local development only)
export GCP_CREDENTIALS="$HOME/certs/diesel-skyline-474415-j6-5e5f35b560dc.json"
export GCP_PROJECT_ID="diesel-skyline-474415-j6"
```

Then reload:
```bash
source ~/.bashrc  # or ~/.zshrc
```

### For CI/CD (GitHub Actions)

**DO NOT** store credentials as GitHub Secrets!

Instead, use **Workload Identity Federation** (secure, time-limited tokens):
- ✅ No long-lived keys
- ✅ Audit logging
- ✅ Time-limited access
- ✅ Automatic rotation

See: `docs/guides/GITHUB_OIDC_SETUP.md`

---

## Deployment Scripts

### How `start-deployment.sh` Handles Credentials

**Detection priority**:

1. Check `GCP_CREDENTIALS` environment variable
2. Look for `*-diesel*.json` in `~/certs/`
3. Try gcloud application-default credentials
4. Fail with helpful error message

**Automatic setup**:

```bash
# Script automatically:
export GOOGLE_APPLICATION_CREDENTIALS="<found-key>"
gcloud auth activate-service-account --key-file="<key>"

# Terraform inherits the credentials
terraform apply -auto-approve
```

**Usage**:

```bash
# Set once
export GCP_CREDENTIALS="~/certs/key.json"

# Then just run
./scripts/deployment/start-deployment.sh
# ✅ Everything works!
```

---

## Troubleshooting

### Error: "Could not find default credentials"

**Cause**: No credentials configured  
**Solution**:
```bash
# Option 1: Set environment variable
export GCP_CREDENTIALS="$HOME/certs/key.json"

# Option 2: Use gcloud login
gcloud auth application-default login

# Option 3: Run deployment script again
./scripts/deployment/start-deployment.sh
```

### Error: "Permission denied" for key file

**Cause**: Key has wrong permissions  
**Solution**:
```bash
chmod 600 ~/certs/key.json
ls -la ~/certs/key.json
# Should show: -rw------- key.json
```

### Error: "Invalid JSON" or "Malformed JSON"

**Cause**: Corrupted key file  
**Solution**:
```bash
# Verify JSON is valid
cat ~/certs/key.json | jq .

# If error, download new key from GCP
# 1. Go to GCP Console
# 2. Service Accounts → Select account
# 3. Keys → Create new key → JSON
# 4. Save to ~/certs/
```

### Error: "Invalid service account"

**Cause**: Wrong GCP project or service account  
**Solution**:
```bash
# Check what's in the key
cat ~/certs/key.json | jq '.project_id'
# Should show: diesel-skyline-474415-j6

# Verify gcloud is pointing to right project
gcloud config get-value project
# Should match the key's project_id
```

### Script can't find credentials in ~/certs/

**Cause**: No JSON files in directory  
**Solution**:
```bash
# List files in certs
ls -la ~/certs/

# Should show something like:
# -rw------- user user key.json

# If empty, download new key from GCP Console
```

---

## Security Checklist

- [ ] Credentials stored in `~/certs/` (outside repo)
- [ ] Permissions are `600` (read-only for you)
- [ ] `.gitignore` includes `*.json` and `certs/`
- [ ] Environment variable `GCP_CREDENTIALS` set
- [ ] Never commit `terraform.tfvars` with credentials
- [ ] Never save credentials in environment files
- [ ] Old keys deleted from GCP Console
- [ ] CI/CD uses Workload Identity (not JSON keys)
- [ ] Audit logging enabled in GCP
- [ ] Keys rotated regularly (every 90 days)

---

## Key Rotation

### When to Rotate

- ✅ Every 90 days (security best practice)
- ✅ When credentials might be exposed
- ✅ When team member leaves
- ✅ After security incident

### How to Rotate

1. **Create new key**:
   - Go to GCP Console
   - Service Accounts → Select account
   - Keys → Create new key → JSON
   - Save to `~/certs/`

2. **Update environment**:
   ```bash
   export GCP_CREDENTIALS="$HOME/certs/new-key.json"
   ```

3. **Delete old key**:
   - Go to GCP Console
   - Service Accounts → Select account
   - Keys → Find old key → Delete

4. **Update all environments**:
   - Local: Update `GCP_CREDENTIALS`
   - CI/CD: Update GitHub Actions secrets
   - Anywhere else using the key

---

## Best Practices Summary

### ✅ DO

- ✅ Store credentials in `~/certs/`
- ✅ Set `600` permissions
- ✅ Use environment variables
- ✅ Rotate keys regularly
- ✅ Use Workload Identity for CI/CD
- ✅ Enable audit logging
- ✅ Delete unused keys

### ❌ DON'T

- ❌ Commit credentials to GitHub
- ❌ Share credentials in Slack/email
- ❌ Use same key everywhere
- ❌ Leave permissions as `644` or `644`
- ❌ Store in environment files
- ❌ Hardcode paths in scripts
- ❌ Leave old keys active

---

## References

- [GCP Service Account Setup](https://cloud.google.com/docs/authentication/getting-started)
- [Workload Identity Federation](https://cloud.google.com/docs/authentication/workload-identity-federation)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GitHub OIDC Setup](docs/guides/GITHUB_OIDC_SETUP.md)

---

## Getting Help

If credentials don't work:

1. Verify file exists: `ls -la ~/certs/`
2. Check syntax: `jq . ~/certs/key.json`
3. Test gcloud: `gcloud auth list`
4. Check permissions: `stat ~/certs/key.json`
5. See troubleshooting section above

**Still stuck?** Review:
- `docs/guides/KUBERNETES_SETUP.md`
- `docs/guides/GITHUB_OIDC_SETUP.md`
- [Google Cloud Documentation](https://cloud.google.com/docs)

