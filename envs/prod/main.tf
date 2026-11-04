locals {
  name         = "platform-${var.environment}"
  cluster_name = "platform-${var.environment}"

  tags = {
    Project     = "terraform-aws-eks-platform"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

data "aws_caller_identity" "current" {}

# One customer-managed key per environment, used for EKS secrets,
# node volumes and log groups.
data "aws_iam_policy_document" "kms" {
  # A KMS key policy's "*" resource means "this key"; account-root admin is the AWS-documented default.
  #checkov:skip=CKV_AWS_111:Key policy scope is the key itself
  #checkov:skip=CKV_AWS_356:Key policy scope is the key itself
  #checkov:skip=CKV_AWS_109:Root admin statement prevents the key from becoming unmanageable
  statement {
    sid       = "AccountAdmin"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid = "CloudWatchLogs"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "platform" {
  description             = "${local.name} platform encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms.json
}

resource "aws_kms_alias" "platform" {
  name          = "alias/${local.name}"
  target_key_id = aws_kms_key.platform.key_id
}

module "vpc" {
  source = "../../modules/vpc"

  name                 = local.name
  cluster_name         = local.cluster_name
  cidr_block           = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway
  kms_key_arn          = aws_kms_key.platform.arn
  tags                 = local.tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name           = local.cluster_name
  kubernetes_version     = var.kubernetes_version
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnet_ids
  endpoint_public_access = var.endpoint_public_access
  public_access_cidrs    = var.public_access_cidrs
  kms_key_arn            = aws_kms_key.platform.arn
  node_groups            = var.node_groups
  tags                   = local.tags
}

module "github_deploy_role" {
  source = "../../modules/github-oidc"

  role_name         = "${local.name}-github-deploy"
  github_repository = var.github_repository
  allowed_refs      = ["environment:${var.environment}"]
  policy_arns       = ["arn:aws:iam::aws:policy/PowerUserAccess"]
  tags              = local.tags
}
