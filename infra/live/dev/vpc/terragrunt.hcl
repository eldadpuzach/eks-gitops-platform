include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=6.7.3"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  cidr     = local.env_vars.locals.vpc_cidr
  region   = local.env_vars.locals.aws_region
}

inputs = {
  cidr = local.cidr
  azs  = ["${local.region}a", "${local.region}b"]

  # /20 private subnets for nodes and pods (VPC CNI gives each pod a VPC IP),
  # /24 public subnets for the NAT gateway and internet-facing load balancers.
  private_subnets = [cidrsubnet(local.cidr, 4, 0), cidrsubnet(local.cidr, 4, 1)]
  public_subnets  = [cidrsubnet(local.cidr, 8, 100), cidrsubnet(local.cidr, 8, 101)]

  # One NAT gateway for the whole VPC: cheaper, but not AZ-redundant.
  enable_nat_gateway = true
  single_nat_gateway = true

  # Tell Kubernetes which subnets to use for load balancers.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}
