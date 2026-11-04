# Lets GitHub Actions get short-lived AWS credentials through OIDC,
# so no long-lived access keys are ever stored as repository secrets.

data "aws_caller_identity" "current" {}

locals {
  provider_url = "token.actions.githubusercontent.com"
  provider_arn = var.create_provider ? aws_iam_openid_connect_provider.github[0].arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.provider_url}"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_provider ? 1 : 0

  url            = "https://${local.provider_url}"
  client_id_list = ["sts.amazonaws.com"]
  # AWS validates GitHub's certificate chain itself; the thumbprint is still a required field.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  tags            = var.tags
}

data "aws_iam_policy_document" "assume" {
  #checkov:skip=CKV_AWS_358:sub is pinned to a single owner/repo via var.github_repository
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Pin the role to one repo and to specific branches/environments.
    condition {
      test     = "StringLike"
      variable = "${local.provider_url}:sub"
      values   = [for ref in var.allowed_refs : "repo:${var.github_repository}:${ref}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = var.role_name
  assume_role_policy   = data.aws_iam_policy_document.assume.json
  max_session_duration = 3600
  tags                 = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each   = toset(var.policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = each.value
}
