include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "tfr:///terraform-aws-modules/eks/aws?version=21.29.0"
}

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
}

# Reads the VPC unit's outputs from its state. The mocks let `plan`
# work before the VPC exists; apply always uses the real outputs.
dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id          = "vpc-00000000000000000"
    private_subnets = ["subnet-00000000000000000", "subnet-11111111111111111"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  kubernetes_version = "1.37"

  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnets

  # Public API endpoint for kubectl from the laptop, limited to admin IPs.
  # CI never talks to the API: with GitOps, ArgoCD pulls from inside the cluster.
  endpoint_public_access       = true
  endpoint_public_access_cidrs = local.account_vars.locals.admin_cidrs

  # Access entries (API mode), and admin access for whoever runs the apply.
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  # Secrets use EKS default envelope encryption (AWS-owned key), so skip
  # the customer KMS key: it costs money and takes 7+ days to delete.
  create_kms_key    = false
  encryption_config = null

  # Audit log only, kept for a week.
  enabled_log_types                      = ["audit"]
  cloudwatch_log_group_retention_in_days = 7

  addons = {
    vpc-cni                = { before_compute = true }
    eks-pod-identity-agent = { before_compute = true }
    kube-proxy             = {}
    coredns                = {}
  }

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      capacity_type  = "SPOT"
      instance_types = ["t3.medium", "t3a.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }
}
