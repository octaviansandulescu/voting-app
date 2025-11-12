# Service Account Setup Guide

## Issue

Your service account `voting-app@diesel-skyline-474415-j6.iam.gserviceaccount.com` is missing required IAM roles for Terraform to create GCP resources.

**Current Error:**
```
Error 403: Required 'compute.networks.create' permission
```

---

## Required IAM Roles

For Terraform to create and manage GKE infrastructure, the service account needs:

### Minimum Required Roles

| Role | Permissions | Used For |
|------|-------------|----------|
| `roles/container.developer` | GKE cluster management | Create/update/delete GKE clusters |
| `roles/cloudsql.admin` | Cloud SQL management | Create/update/delete Cloud SQL instances |
| `roles/compute.networkAdmin` | Network management | Create VPC, subnets, firewall rules |
| `roles/iam.securityAdmin` | IAM management | Create service accounts, assign roles |

### Recommended (Simplified)

Use **`roles/editor`** (not recommended for production, but fine for development):
- Gives broad permissions to create/update resources
- Still cannot modify IAM policies or billing

---

## How to Grant Roles

### Option 1: Using gcloud CLI (Recommended)

**Prerequisites:**
- You must be authenticated as an account with `roles/Owner` or `roles/Editor` on the project
- The service account must already exist

**Commands:**

```bash
# Set variables
PROJECT_ID="diesel-skyline-474415-j6"
SA_EMAIL="voting-app@diesel-skyline-474415-j6.iam.gserviceaccount.com"

# Grant Container Developer role (GKE)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/container.developer"

# Grant Cloud SQL Admin role
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/cloudsql.admin"

# Grant Compute Network Admin role (VPC, Networks)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/compute.networkAdmin"

# Grant Service Account User role (for internal GCP services)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/iam.serviceAccountUser"

# Verify roles were granted
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:$SA_EMAIL" \
  --format="table(bindings.role)"
```

### Option 2: Using Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select project: `diesel-skyline-474415-j6`
3. Navigate to **IAM & Admin > IAM**
4. Find service account: `voting-app@diesel-skyline-474415-j6.iam.gserviceaccount.com`
5. Click **Edit** (pencil icon)
6. Click **Add Role** and add:
   - `Container Developer`
   - `Cloud SQL Admin`
   - `Compute Network Admin`
   - `Service Account User`
7. Click **Save**

### Option 3: Using Terraform (in project root)

```hcl
resource "google_project_iam_member" "sa_container_dev" {
  project = "diesel-skyline-474415-j6"
  role    = "roles/container.developer"
  member  = "serviceAccount:voting-app@diesel-skyline-474415-j6.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "sa_sql_admin" {
  project = "diesel-skyline-474415-j6"
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:voting-app@diesel-skyline-474415-j6.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "sa_network_admin" {
  project = "diesel-skyline-474415-j6"
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:voting-app@diesel-skyline-474415-j6.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "sa_user" {
  project = "diesel-skyline-474415-j6"
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:voting-app@diesel-skyline-474415-j6.iam.gserviceaccount.com"
}
```

---

## Verification

After granting roles, verify the service account has permissions:

```bash
# Export credentials
export GCP_CREDENTIALS=~/certs/diesel-skyline-474415-j6-5e5f35b560dc.json
export GOOGLE_APPLICATION_CREDENTIALS="$GCP_CREDENTIALS"

# Authenticate with service account
gcloud auth activate-service-account --key-file="$GCP_CREDENTIALS"

# Try to list compute networks (should work now)
gcloud compute networks list

# Try to list GKE clusters (should work now)
gcloud container clusters list --project="diesel-skyline-474415-j6"
```

**Expected output:** Either lists of resources or "No instances found" (but no 403 errors)

---

## After Granting Roles

Once roles are granted:

1. **Set credentials:**
   ```bash
   export GCP_CREDENTIALS=~/certs/diesel-skyline-474415-j6-5e5f35b560dc.json
   ```

2. **Deploy with Terraform:**
   ```bash
   cd /home/octavian/sandbox/voting-app/3-KUBERNETES/terraform
   terraform init
   terraform plan
   terraform apply
   ```

3. **Or use deployment script:**
   ```bash
   ./scripts/deployment/start-deployment.sh
   ```

---

## Troubleshooting

### Still getting 403 errors?

**Check 1:** Wait a few minutes (IAM role changes take time to propagate)

**Check 2:** Verify roles are actually assigned:
```bash
gcloud projects get-iam-policy diesel-skyline-474415-j6 \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:voting-app@diesel-skyline-474415-j6.iam.gserviceaccount.com" \
  --format="table(bindings.role)"
```

**Check 3:** Make sure you're using correct credentials file:
```bash
export GOOGLE_APPLICATION_CREDENTIALS=~/certs/diesel-skyline-474415-j6-5e5f35b560dc.json
gcloud auth list
gcloud config list
```

### Getting "access denied" on `get-iam-policy`?

That's normal - the service account doesn't need to read IAM policy. It only needs permissions to:
- Create/update/delete GKE resources ✅
- Create/update/delete Cloud SQL ✅
- Create/update/delete VPC networks ✅

### Need more restricted permissions?

For production, instead of `roles/container.developer`, create a custom role with only:
- `container.clusters.create`
- `container.clusters.delete`
- `container.clusters.get`
- `container.clusters.update`
- `container.nodePool.*` (all node pool operations)
- `compute.networks.*` (all network operations)
- `cloudsql.instances.*` (all SQL operations)

---

## Security Best Practices

✅ **DO:**
- Use dedicated service accounts per environment
- Grant minimum required permissions (principle of least privilege)
- Rotate service account keys regularly
- Store keys securely (never in git)
- Use Workload Identity in production (instead of service account keys)

❌ **DON'T:**
- Use `roles/Owner` or `roles/Editor` for service accounts
- Share service account keys between projects
- Commit service account keys to git
- Use service account keys in CI/CD (use Workload Identity instead)

---

## See Also

- [Google Cloud IAM Roles](https://cloud.google.com/iam/docs/understanding-roles)
- [GKE Service Account Requirements](https://cloud.google.com/kubernetes-engine/docs/how-to/service-accounts)
- [Cloud SQL IAM Roles](https://cloud.google.com/sql/docs/mysql/iam-overview)
- [Workload Identity for CI/CD](../GCP_CREDENTIALS_SECURITY.md)

---

**Next:** Once roles are granted, run: `./scripts/deployment/start-deployment.sh`
