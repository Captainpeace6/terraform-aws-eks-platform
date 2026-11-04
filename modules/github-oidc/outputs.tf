output "role_arn" {
  description = "ARN to put in the workflow's role-to-assume."
  value       = aws_iam_role.this.arn
}
