data "aws_partition" "current" {}

locals {
  control_plane_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

# --- Control plane ---------------------------------------------------------

data "aws_iam_policy_document" "cluster_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${var.cluster_name}-cluster"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Create the log group ourselves so retention and encryption are under our control
# (EKS would otherwise create it with "never expire").
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
  tags              = var.tags
}

resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster"
  description = "Additional security group for the EKS control plane"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.cluster_name}-cluster" })
}

resource "aws_vpc_security_group_egress_rule" "cluster_all" {
  security_group_id = aws_security_group.cluster.id
  description       = "Control plane to nodes and AWS APIs"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_eks_cluster" "this" {
  #checkov:skip=CKV_AWS_39:Public endpoint is opt-in per environment and limited to public_access_cidrs; prod keeps it off
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn

  enabled_cluster_log_types = local.control_plane_log_types

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.endpoint_public_access ? var.public_access_cidrs : null
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = var.kms_key_arn
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster,
    aws_cloudwatch_log_group.cluster,
  ]
}

# --- IRSA: lets pods assume IAM roles through service accounts --------------

data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
  tags            = var.tags
}

# --- Managed node groups ---------------------------------------------------

data "aws_iam_policy_document" "node_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.cluster_name}-node"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = toset([
    "AmazonEKSWorkerNodePolicy",
    "AmazonEKS_CNI_Policy",
    "AmazonEC2ContainerRegistryReadOnly",
    "AmazonSSMManagedInstanceCore",
  ])

  role       = aws_iam_role.node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/${each.value}"
}

# Launch template so we can enforce IMDSv2 and encrypted root volumes on every node.
resource "aws_launch_template" "node" {
  for_each = var.node_groups

  name_prefix = "${var.cluster_name}-${each.key}-"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1 # pods use IRSA / Pod Identity, not the node's IMDS credentials
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = each.value.disk_size_gb
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.kms_key_arn
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.cluster_name}-${each.key}" })
  }

  tags = var.tags
}

resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids
  instance_types  = each.value.instance_types
  capacity_type   = each.value.capacity_type
  labels          = each.value.labels

  launch_template {
    id      = aws_launch_template.node[each.key].id
    version = aws_launch_template.node[each.key].latest_version
  }

  scaling_config {
    min_size     = each.value.min_size
    max_size     = each.value.max_size
    desired_size = each.value.desired_size
  }

  update_config {
    max_unavailable_percentage = 25
  }

  tags = var.tags

  # The cluster autoscaler owns desired_size after creation.
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [aws_iam_role_policy_attachment.node]
}

# --- Core add-ons, pinned by EKS to versions compatible with the cluster -----

resource "aws_eks_addon" "this" {
  for_each = toset(["vpc-cni", "coredns", "kube-proxy", "eks-pod-identity-agent"])

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.value
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  tags                        = var.tags

  depends_on = [aws_eks_node_group.this]
}
