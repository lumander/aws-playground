provider "aws" {
    region = var.region
}

terraform {
  backend "s3" {
    key = "dev/networking/terraform.tfstate"
    dynamodb_table = "tf-locks-networking-2b88ad"
  }
}

module "vpc" {
    source         = "../../../modules/networking"
    vpc_cidr_block = var.vpc["vpc_cidr_block"]
    subnets        = var.vpc["subnets"]
    environment    = var.environment
    project        = var.project
    git_tag        = var.git_tag
}

resource "aws_s3_bucket_object" "network_info" {
  bucket = var.state_bucket
  key    = "dev/networking/network-info.json"
  content = <<EOF
    {
      "vpc": "${module.vpc.vpc_id}",
      "subnets": {
        "public":${jsonencode({for subnet in values(module.vpc.vpc_public_subnets) : subnet.availability_zone => subnet.id...})},
        "private":${jsonencode({for subnet in values(module.vpc.vpc_private_subnets) : subnet.availability_zone => subnet.id...})},
        "db":${jsonencode({for subnet in values(module.vpc.vpc_db_private_subnets) : subnet.availability_zone => subnet.id...})}

      }
    }
    EOF
  content_type = "application/json"

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }
}
