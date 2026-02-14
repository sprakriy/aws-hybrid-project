terraform {
  backend "s3" {
    bucket  = "sp-01102026-aws-kub" # Same bucket name
    key     = "vpn/terraform.tfstate" # DIFFERENT path for the VPN state
    region  = "us-east-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_vpc" "hybrid_lab" {
  cidr_block = "10.0.0.0/16" # Filter by CIDR block

}
/*
resource "aws_customer_gateway" "main" {
  bgp_asn    = 65000
  ip_address = "173.72.6.96" # The static IP or your router's current IP
  type       = "ipsec.1"

  tags = {
    Name = "office-to-aws-gateway"
  }
}

resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id      = data.aws_vpc.hybrid_lab.id

  tags = {
    Name = "main-vpc-vgw"
  }
}
*/
# This is the "Explicit Configuration" it's complaining about
provider "aws" {
  region = "us-east-1"
}

locals {
  # Your ACM ARNs from earlier
  server_cert_arn = "arn:aws:acm:us-east-1:319310747432:certificate/2b38949a-02ca-4996-af8f-61d1460cfdf1"
  client_cert_arn = "arn:aws:acm:us-east-1:319310747432:certificate/d2d4d73c-4d56-4265-bf28-23c39bc3aaf0"
  
  # Your Network Coordinates
  target_subnet_id = "subnet-005676b0cd928bdc1"
  target_vpc_cidr  = "10.0.0.0/16"
}

resource "aws_ec2_client_vpn_endpoint" "main" {
  description            = "Hybrid-Lab-VPN-Endpoint"
  server_certificate_arn =  "arn:aws:acm:us-east-1:319310747432:certificate/7e11ffa1-5460-4a35-9946-ca6ecf2ae06f"
  client_cidr_block      = "10.200.0.0/22" # IPs for your laptop/k3d
  split_tunnel           = true           # Only send AWS traffic through VPN

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = "arn:aws:acm:us-east-1:319310747432:certificate/7e11ffa1-5460-4a35-9946-ca6ecf2ae06f"
  #  root_certificate_chain_arn = local.client_cert_arn
  }

  connection_log_options {
    enabled = false
  }
}

# Network Association (Connecting the VPN to the Subnet)
resource "aws_ec2_client_vpn_network_association" "main" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
  subnet_id              = local.target_subnet_id

}

# Authorization Rule (Allowing traffic to flow)
resource "aws_ec2_client_vpn_authorization_rule" "all_vpc" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
  target_network_cidr    = local.target_vpc_cidr
  authorize_all_groups   = true
}
# This is the "Navigator" that was missing
resource "aws_ec2_client_vpn_route" "rds_route" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
  # destination_cidr_block = "10.0.0.0/16"
  destination_cidr_block = data.aws_vpc.hybrid_lab.cidr_block
  target_vpc_subnet_id   = aws_ec2_client_vpn_network_association.main.subnet_id

  # Forces Terraform to wait until the hardware interface is ready
  depends_on = [aws_ec2_client_vpn_network_association.main]
}