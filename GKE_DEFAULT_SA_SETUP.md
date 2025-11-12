# Creating GKE Default Service Account Key

## Quick Steps (5 minutes)

### Step 1: Go to Google Cloud Console
https://console.cloud.google.com

### Step 2: Select Your Project
- Select project: **diesel-skyline-474415-j6**

### Step 3: Navigate to Service Accounts
1. Click **≡** (menu) > **IAM & Admin** > **Service Accounts**
2. You should see:
   - `245684762179-compute@developer.gserviceaccount.com` (GKE Default)
   - `voting-app@diesel-skyline-474415-j6.iam.gserviceaccount.com` (Custom)

### Step 4: Create Key for GKE Default Service Account
1. Click on: **245684762179-compute@developer.gserviceaccount.com**
2. Go to **Keys** tab
3. Click **Add Key** → **Create new key**
4. Select **JSON**
5. Click **Create**
6. A JSON file will download automatically

### Step 5: Save the Key
1. Open your terminal
2. Run:
```bash
# Move the downloaded key to certs directory
mv ~/Downloads/diesel-skyline-474415-j6-*.json ~/certs/gke-default-sa-key.json

# Verify it's there
ls -lh ~/certs/gke-default-sa-key.json
```

### Step 6: Test Deployment
```bash
cd /home/octavian/sandbox/voting-app
./scripts/deployment/start-deployment.sh
```

---

## Why This Works

The GKE default service account (`245684762179-compute@developer.gserviceaccount.com`) has:
- ✅ Full compute permissions
- ✅ GKE cluster creation rights
- ✅ Cloud SQL permissions
- ✅ VPC network permissions
- ✅ No manual IAM role assignment needed!

---

## Expected Output After Saving Key

```bash
$ ls -lh ~/certs/
total 8.0K
-rw-r--r-- 1 octavian octavian 2.4K Nov 12 15:00 gke-default-sa-key.json
-rw-r--r-- 1 octavian octavian 2.4K Nov  9 13:09 diesel-skyline-474415-j6-5e5f35b560dc.json
```

Then deployment will work! 🚀

---

## Troubleshooting

**Can't find the service account?**
- Make sure you're in project: `diesel-skyline-474415-j6`
- Click **Filter** and search for: `245684762179-compute`

**Downloaded file has different name?**
- Rename it to: `gke-default-sa-key.json`
- Move to: `~/certs/`

**Still getting 403 errors?**
- Verify file was saved correctly: `cat ~/certs/gke-default-sa-key.json`
- Try again: `./scripts/deployment/start-deployment.sh`
