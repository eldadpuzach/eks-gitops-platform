include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Lets AWS trust tokens issued by GitHub Actions.
# Only one provider per URL can exist in an AWS account.
terraform {
  source = "tfr:///terraform-aws-modules/iam/aws//modules/iam-oidc-provider?version=6.8.2"
}

inputs = {
  url = "https://token.actions.githubusercontent.com"
}
