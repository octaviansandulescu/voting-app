#!/bin/bash
echo "Deployment Status Check"
echo "======================="
echo ""
echo "GKE Cluster:"
gcloud container clusters list --project diesel-skyline-474415-j6 --format="table(name, status, location, createTime)" 2>/dev/null | head -5

echo ""
echo "Cloud SQL Instance:"
gcloud sql instances list --project diesel-skyline-474415-j6 --format="table(name, databaseVersion, state, region)" 2>/dev/null | head -5

echo ""
echo "Terraform State:"
cd terraform
if [ -f terraform.tfstate ]; then
  RESOURCES=$(grep -c '"type"' terraform.tfstate || echo "0")
  echo "Resources in state: $RESOURCES"
  echo "State file size: $(ls -lh terraform.tfstate | awk '{print $5}')"
else
  echo "No state file yet"
fi
