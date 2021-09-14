provider "aws" {
    region = var.region
}

terraform {
  backend "s3" {
    key = "dev/rds/terraform.tfstate"
    dynamodb_table = "tf-locks-rds-2b88ad"
  }
}

## variables & data sources block

data "aws_s3_bucket_object" "network_info" {
  bucket = var.state_bucket
  key    = "dev/networking/network-info.json"
}

locals {
  network_info = jsondecode(data.aws_s3_bucket_object.network_info.body)
  unique_db_instances = flatten([
    for zone, numbers in var.db.availability_zones : [
      for number in range(1, numbers+1) : { 
        zone = zone
        id = number
      }
    ]
  ])
}

## resources

resource "aws_db_subnet_group" "db_subnets" {
  name       = "main"
  subnet_ids = flatten(values(local.network_info["subnets"]["db"]))

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }
}

resource "aws_rds_cluster" "rds_cluster" {
  cluster_identifier      = format("aurora-mysql")
  engine                  = "aurora-mysql"
  engine_version          = "5.7.mysql_aurora.2.03.2"
  availability_zones      = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  db_subnet_group_name    = aws_db_subnet_group.db_subnets.id
  database_name           = var.db.database_name
  master_username         = "demoaws"
  master_password         = "passw0rd"
  backup_retention_period = 5
  preferred_backup_window = "04:00-06:00"
  skip_final_snapshot     = true
  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }

}

resource "aws_rds_cluster_instance" "rds_cluster_instances" {
  for_each = {
      for db in local.unique_db_instances : "${db.zone}:${db.id}" => db
    }

  identifier         = format("%s-aurora-mysql-%s-%s",var.project,each.value.zone,each.value.id)
  cluster_identifier = aws_rds_cluster.rds_cluster.id
  availability_zone  = each.value.zone
  instance_class     = "db.t3.small"
  engine             = aws_rds_cluster.rds_cluster.engine
  engine_version     = aws_rds_cluster.rds_cluster.engine_version

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }

}

