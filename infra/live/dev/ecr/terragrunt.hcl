include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "tfr:///terraform-aws-modules/ecr/aws?version=3.2.0"
}

inputs = {
  repository_name = "eks-gitops-platform/app"

  # Immutable tags: a SHA tag always points at the same image.
  repository_image_tag_mutability = "IMMUTABLE"
  repository_image_scan_on_push   = true

  # Access is granted by IAM (the GitHub OIDC role), not a repo policy.
  create_repository_policy = false
  attach_repository_policy = false

  # Lets `terragrunt destroy` remove the repo even when it holds images.
  repository_force_delete = true

  repository_lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the last 20 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 20
      }
      action = { type = "expire" }
    }]
  })
}
