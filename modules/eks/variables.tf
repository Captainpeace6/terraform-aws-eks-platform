variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes minor version for the control plane and nodes."
  type        = string
  default     = "1.33"
}

variable "vpc_id" {
  description = "VPC the cluster runs in."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the control plane ENIs and worker nodes."
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Expose the Kubernetes API publicly. Keep false for prod and reach it over VPN or a bastion."
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint, when it is enabled."
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "KMS key used for Kubernetes secrets envelope encryption and the control plane log group."
  type        = string
}

variable "node_groups" {
  description = "Managed node groups, keyed by name."
  type = map(object({
    instance_types = list(string)
    capacity_type  = optional(string, "ON_DEMAND")
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size_gb   = optional(number, 50)
    labels         = optional(map(string), {})
  }))
}

variable "log_retention_days" {
  description = "Retention for control plane logs."
  type        = number
  default     = 365
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
