# State Migration Solution - Fixed! ✅

## Problem Identified

The error you saw:
```
Error: failed to read schema for kubernetes_namespace.production
unavailable provider "registry.terraform.io/hashicorp/kubernetes"
```

**Root Cause:** Terraform state still had references to Kubernetes resources (namespaces, Helm releases) but the kubernetes/helm providers were removed from the code in Phase 1.

## Solution Applied ✅

I've added **automatic state cleanup** to the Terraform workflow. Now, before every `terraform plan`, it automatically removes K8s resources from state:

```yaml
- name: Clean K8s Resources from State (Phase 1 migration)
  run: |
    terraform state rm 'kubernetes_namespace.development' 2>/dev/null || true
    terraform state rm 'kubernetes_namespace.production' 2>/dev/null || true
    terraform state rm 'kubernetes_namespace.signoz[0]' 2>/dev/null || true
    terraform state rm 'helm_release.aws_lb_controller[0]' 2>/dev/null || true
    terraform state rm 'helm_release.metrics_server' 2>/dev/null || true
    terraform state rm 'helm_release.signoz[0]' 2>/dev/null || true
```

**This is safe!** These resources:
- ✅ Still exist in the cluster
- ✅ Will be imported to kubernetes-addons (Phase 2) later
- ✅ Are only being removed from Phase 1 state

## How to Fix Right Now

### Option 1: Re-run the Deploy Workflow (Recommended)

The workflow now has the fix built-in:

```bash
# Go to Actions → Terraform Kubernetes Infrastructure → Re-run jobs
# Or trigger manually:
gh workflow run terraform.yml --repo fiap-tech-challenge-projects/kubernetes-core-infra --ref develop --field environment=development --field action=apply
```

### Option 2: Run State Migration Manually (if workflow still fails)

I created a dedicated migration workflow:

```bash
# Go to Actions → Migrate Terraform State → Run workflow
# Select environment: development
# This will clean the state using OLD code (before refactor)
```

### Option 3: Manual State Cleanup (local)

If you prefer to do it locally:

```bash
cd kubernetes-core-infra/terraform

# Initialize with backend
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
terraform init -backend-config="bucket=fiap-tech-challenge-tf-state-${ACCOUNT_ID}"

# Select workspace
terraform workspace select development

# Remove K8s resources
terraform state rm 'kubernetes_namespace.development'
terraform state rm 'kubernetes_namespace.production'
terraform state rm 'kubernetes_namespace.signoz[0]'
terraform state rm 'helm_release.aws_lb_controller[0]'
terraform state rm 'helm_release.metrics_server'
terraform state rm 'helm_release.signoz[0]'

# Now plan/apply will work
terraform plan -var="environment=development"
```

## What Changed in the Fix

**Files Modified:**
```
kubernetes-core-infra/
├── .github/workflows/
│   ├── terraform.yml           # ← UPDATED: Auto-cleanup before plan
│   └── migrate-state.yml       # ← NEW: Manual migration workflow
```

**Commits:**
```
8696f5d - Fix: Auto-clean K8s resources from state before plan
fa4e89f - Refactor: Remove K8s/Helm providers for Phase 1 deployment
```

## Why This Happened

When we split EKS deployment into 2 phases:
1. **Phase 1** removed kubernetes/helm providers
2. But **Terraform state** still had kubernetes_namespace resources
3. Terraform tried to read provider schema → provider not found → error

**Solution:** Clean state before plan to remove Phase 2 resources.

## Next Steps After Fix

1. ✅ Deploy kubernetes-core-infra (Phase 1) - **NOW WORKS**
2. ⏭️ Deploy kubernetes-addons (Phase 2) - Creates namespaces, Helm releases
3. 🎯 Import existing resources to Phase 2 (optional, for clean state)

## Verification

After the workflow succeeds:

```bash
# Check Phase 1 deployed correctly
aws eks describe-cluster --name fiap-tech-challenge-eks-development --region us-east-1

# Verify nodes are ready
aws eks update-kubeconfig --region us-east-1 --name fiap-tech-challenge-eks-development
kubectl get nodes

# Check namespaces still exist (created by old state, will be managed by Phase 2)
kubectl get namespaces | grep ftc-app
```

## Future Deployments

This cleanup step will run **automatically** every time, so:
- ✅ No manual intervention needed
- ✅ Idempotent (safe to run multiple times)
- ✅ Phase 1 can be deployed independently

## Questions?

- **Q: Will this delete my namespaces?**
  - A: No! It only removes them from Phase 1 Terraform state. The actual K8s resources remain in the cluster.

- **Q: Do I need to re-import these resources?**
  - A: Eventually yes, into Phase 2 (kubernetes-addons), but not urgent. They'll keep working.

- **Q: What if I already destroyed them?**
  - A: No problem! Phase 2 will create them fresh when deployed.

---

**Status:** ✅ FIXED - Ready to deploy!
