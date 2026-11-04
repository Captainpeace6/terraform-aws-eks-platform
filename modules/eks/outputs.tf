output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority" {
  description = "Base64 CA certificate for the cluster."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN, for IRSA role trust policies."
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "node_role_arn" {
  description = "IAM role used by worker nodes."
  value       = aws_iam_role.node.arn
}
