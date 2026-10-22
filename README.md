# eks-gitops-platform

A small GitOps platform on Amazon EKS:

- **Terragrunt** wraps community Terraform modules for the VPC, EKS, ECR and GitHub OIDC.
- **GitHub Actions** builds the app image, scans it with **Trivy**, and pushes it to **ECR** using OIDC (no static AWS keys).
- **ArgoCD** watches this repo and syncs the app to the cluster.

> Work in progress.

## Architecture

```
GitHub repo ──push──▶ GitHub Actions
                        ├─ build image
                        ├─ Trivy scan (fail on HIGH/CRITICAL)
                        ├─ push to Amazon ECR (OIDC role)
                        └─ bump image tag in k8s/app (GitOps commit)
                                     │
ArgoCD (in EKS) ◀──watches repo──────┘──▶ syncs app to the cluster
```

## Repo layout

| Path | What |
|---|---|
| `app/` | Small web app and Dockerfile |
| `infra/live/root.hcl` | Remote state (S3, native locking) and provider generation |
| `infra/live/dev/` | One folder per unit: `vpc`, `eks`, `ecr`, `github-oidc` |
| `k8s/app/` | App manifests, synced by ArgoCD |
| `k8s/argocd/` | ArgoCD `Application` manifests |
| `.github/workflows/` | CI pipeline |

## How to run

Requirements: Terraform >= 1.10, Terragrunt 1.x, AWS CLI, kubectl.

```bash
cp infra/live/account.hcl.example infra/live/account.hcl   # set your account ID
export AWS_PROFILE=<your-profile>
cd infra/live/dev
terragrunt backend bootstrap --all   # create the S3 state bucket once
terragrunt run --all plan
```

## Cost notes

TODO

## What I'd do in production

TODO
