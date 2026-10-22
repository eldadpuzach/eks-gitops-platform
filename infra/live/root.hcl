# Root Terragrunt config. Every unit includes this file with:
#   include "root" { path = find_in_parent_folders("root.hcl") }

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  account_id = local.account_vars.locals.account_id
  aws_region = local.env_vars.locals.aws_region
  env        = local.env_vars.locals.env
  project    = "eks-gitops-platform"
}

# State: one S3 bucket per account, one key per unit (e.g. dev/vpc/terraform.tfstate).
# use_lockfile = S3-native locking (Terraform >= 1.10), so no DynamoDB table is needed.
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = "${local.project}-tfstate-${local.account_id}"
    key          = "${path_relative_to_include()}/terraform.tfstate"
    region       = local.aws_region
    encrypt      = true
    use_lockfile = true
  }
}

# Same provider block in every unit. allowed_account_ids stops a run
# if the shell points at the wrong AWS account.
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region              = "${local.aws_region}"
      allowed_account_ids = ["${local.account_id}"]

      default_tags {
        tags = {
          Project     = "${local.project}"
          Environment = "${local.env}"
          ManagedBy   = "terragrunt"
          Owner       = "eldad"
        }
      }
    }
  EOF
}

# *_override.tf merges into the module's own terraform block,
# so this pins versions without clashing with the module's versions.tf.
generate "versions" {
  path      = "versions_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = ">= 1.10"
      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "~> 6.69"
        }
      }
    }
  EOF
}

# Shared inputs, available to every unit.
inputs = {
  name = "${local.project}-${local.env}"
}
