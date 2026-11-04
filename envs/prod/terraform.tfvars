region      = "us-east-1"
environment = "prod"

vpc_cidr             = "10.20.0.0/16"
azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.20.0.0/20", "10.20.16.0/20", "10.20.32.0/20"]
private_subnet_cidrs = ["10.20.64.0/18", "10.20.128.0/18", "10.20.192.0/18"]
single_nat_gateway   = false # one NAT per AZ so an AZ outage doesn't cut egress

kubernetes_version     = "1.33"
endpoint_public_access = false # API reachable only from inside the VPC

node_groups = {
  system = {
    instance_types = ["m6i.large"]
    min_size       = 2
    max_size       = 4
    desired_size   = 3
    labels         = { workload = "system" }
  }
  apps = {
    instance_types = ["m6i.xlarge", "m5.xlarge"]
    min_size       = 3
    max_size       = 12
    desired_size   = 3
    labels         = { workload = "apps" }
  }
}

github_repository = "Captainpeace6/terraform-aws-eks-platform"
