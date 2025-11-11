# GCP Deployment Checklist

## Pre-Deployment Preparation
- [ ] GCP Project created and configured
  - Project ID: `diesel-skyline-474415-j6`
  - Region: `us-central1`
- [ ] `gcloud` CLI installed and authenticated
- [ ] `kubectl` installed
- [ ] `terraform` installed
- [ ] `docker` installed

## Pre-Deployment Validation
```bash
./validate.sh
```
- [ ] All checks pass (or only warnings)
- [ ] No missing tools or files

## Configuration Setup
```bash
./setup-gcp.sh
```
- [ ] Script completed successfully
- [ ] `terraform/terraform.tfvars` created
- [ ] Kubernetes manifests updated with correct images
- [ ] Required GCP APIs enabled
- [ ] DB password saved securely

## Infrastructure Deployment
```bash
./deploy.sh
```
- [ ] Terraform plan reviewed
- [ ] Terraform applied successfully
- [ ] GKE cluster created
- [ ] Cloud SQL instance created
- [ ] VPC network configured

## Kubernetes Verification
```bash
kubectl get pods -n voting-app
kubectl get svc -n voting-app
```
- [ ] Backend pod(s) running
- [ ] Frontend pod(s) running
- [ ] Services created
- [ ] Frontend LoadBalancer has external IP

## Application Testing
```bash
# Get frontend URL
kubectl get svc frontend -n voting-app
```
- [ ] Frontend loads in browser (http://EXTERNAL-IP)
- [ ] Can vote for dogs
- [ ] Can vote for cats
- [ ] Results update in real-time
- [ ] Backend responds to API calls

## Advanced Checks (Optional)
```bash
# Check logs
kubectl logs deployment/backend -n voting-app
kubectl logs deployment/frontend -n voting-app

# Test database connectivity
kubectl exec -it deployment/backend -n voting-app -- sh
# Inside pod: python -c "from database import engine; print(engine)"
```
- [ ] No errors in backend logs
- [ ] No errors in frontend logs
- [ ] Database connectivity confirmed

## Documentation & Handoff
- [ ] README.md updated with GCP URL
- [ ] Team notified of deployment
- [ ] Access instructions shared
- [ ] Monitoring/logging configured (optional)

## Post-Deployment
- [ ] Monitor application for 24 hours
- [ ] Check GCP billing dashboard for costs
- [ ] Set up alerts (optional)
- [ ] Document any issues

## Cleanup (When Ready)
```bash
# Option 1: Keep running
# Nothing to do - application is live

# Option 2: Stop temporarily
kubectl scale deployment/backend --replicas=0 -n voting-app
kubectl scale deployment/frontend --replicas=0 -n voting-app

# Option 3: Full cleanup
kubectl delete namespace voting-app
cd terraform
terraform destroy
```
- [ ] Cleanup action decided
- [ ] Resources stopped/deleted if needed
- [ ] Costs minimized

---

## Quick Reference

### Critical Information
- **GCP Project**: diesel-skyline-474415-j6
- **Region**: us-central1
- **Cluster Name**: voting-app-cluster
- **Database**: voting-app-mysql
- **Kubernetes Namespace**: voting-app

### Important Files
- Deployment Scripts: `setup-gcp.sh`, `deploy.sh`, `validate.sh`
- Configuration: `terraform/terraform.tfvars`
- Kubernetes: `k8s/*.yaml`
- Documentation: `docs/GCP_DEPLOYMENT.md`, `GCP_QUICKSTART.md`

### Emergency Contacts
- GCP Documentation: https://cloud.google.com/docs
- Kubernetes: https://kubernetes.io/docs
- Terraform: https://www.terraform.io/docs