variable "region" {
  description = "AWS region for this environment."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR range."
  type        = string
}

variable "azs" {
  description = "Availability zones to use."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs, one per AZ."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs, one per AZ."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Share one NAT gateway across AZs."
  type        = bool
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
}

variable "endpoint_public_access" {
  description = "Expose the Kubernetes API publicly."
  type        = bool
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint."
  type        = list(string)
  default     = []
}

variable "node_groups" {
  description = "Managed node groups for the cluster."
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

variable "github_repository" {
  description = "Repository whose workflows may deploy to this account (owner/name)."
  type        = string
}
