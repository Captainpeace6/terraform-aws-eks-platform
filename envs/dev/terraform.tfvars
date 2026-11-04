region      = "us-east-1"
environment = "dev"

vpc_cidr             = "10.10.0.0/16"
azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.10.0.0/20", "10.10.16.0/20", "10.10.32.0/20"]
private_subnet_cidrs = ["10.10.64.0/18", "10.10.128.0/18", "10.10.192.0/18"]
single_nat_gateway   = true # one NAT is fine for dev; saves ~$65/month

kubernetes_version     = "1.33"
endpoint_public_access = true
public_access_cidrs    = ["203.0.113.0/24"] # replace with your office/VPN range

node_groups = {
  general = {
    instance_types = ["t3.large"]
    capacity_type  = "SPOT"
    min_size       = 1
    max_size       = 4
    desired_size   = 2
  }
}

github_repository = "Captainpeace6/terraform-aws-eks-platform"
