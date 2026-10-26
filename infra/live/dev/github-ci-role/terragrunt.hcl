include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "tfr:///terraform-aws-modules/iam/aws//modules/iam-role?version=6.8.2"
}

# The role trusts the OIDC provider, so create that first.
dependencies {
  paths = ["../github-oidc"]
}

dependency "ecr" {
  config_path = "../ecr"

  mock_outputs = {
    repository_arn = "arn:aws:ecr:eu-west-1:111111111111:repository/mock"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  name            = "eks-gitops-platform-dev-github-ci"
  use_name_prefix = false

  # Only workflow runs on the main branch of this repo can assume the role.
  # Pull requests build and scan, but never get AWS credentials.
  # GitHub's sub claim uses immutable IDs (owner@id/repo@id): a repo recreated
  # under the same name gets a new ID and cannot assume this role.
  enable_github_oidc = true
  oidc_subjects      = ["eldadpuzach@37382556/eks-gitops-platform@1429302892:ref:refs/heads/main"]

  # Push to this one ECR repo, nothing else.
  create_inline_policy = true
  inline_policy_permissions = {
    EcrLogin = {
      actions   = ["ecr:GetAuthorizationToken"]
      resources = ["*"]
    }
    EcrPush = {
      actions = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeImages",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart",
      ]
      resources = [dependency.ecr.outputs.repository_arn]
    }
  }
}
