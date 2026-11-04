variable "role_name" {
  description = "Name of the IAM role GitHub Actions will assume."
  type        = string
}

variable "github_repository" {
  description = "Repository allowed to assume the role, as owner/name."
  type        = string
}

variable "allowed_refs" {
  description = "Subject claims allowed to assume the role, e.g. ref:refs/heads/main or environment:prod."
  type        = list(string)
}

variable "policy_arns" {
  description = "Managed policies attached to the role."
  type        = list(string)
}

variable "create_provider" {
  description = "Create the GitHub OIDC provider. Set false if the account already has one."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
