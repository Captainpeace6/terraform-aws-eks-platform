variable "name" {
  description = "Name prefix for all VPC resources."
  type        = string
}

variable "cidr_block" {
  description = "CIDR range for the VPC."
  type        = string
}

variable "azs" {
  description = "Availability zones to spread subnets across."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "One public subnet CIDR per AZ (load balancers, NAT)."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "One private subnet CIDR per AZ (EKS worker nodes)."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway for all AZs (cheaper, for non-prod) instead of one per AZ."
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "EKS cluster name, used for the subnet discovery tags the AWS load balancer controller reads."
  type        = string
}

variable "flow_log_retention_days" {
  description = "How long to keep VPC flow logs in CloudWatch."
  type        = number
  default     = 365
}

variable "kms_key_arn" {
  description = "KMS key used to encrypt the flow log group."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
