provider "aws" {
    region = var.region
}

terraform {
  backend "s3" {
    key = "dev/ecs/terraform.tfstate"
    dynamodb_table = "tf-locks-ecs-2b88ad"
  }
}

## ecs fargate cluster

resource "aws_ecs_cluster" "ecs_fargate" {
  name = "aws-ecs-${var.environment}"

  capacity_providers = [ "FARGATE" ]

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }
}

### ECS Service-Linked role - manages logs, autoscaling, lb and so on
#
#resource "aws_iam_service_linked_role" "ecs" {
#  aws_service_name = "ecs.amazonaws.com"
#}

## artifact storage for ecs they match image name

resource "aws_ecr_repository" "backend" {
  name                 = "${var.project}-be"
  
  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }
}

resource "aws_ecr_repository" "frontend" {
  name                 = "${var.project}-fe"
  
  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }
}

resource "aws_s3_bucket_object" "ecs_info" {
  bucket = var.state_bucket
  key    = "dev/ecs/ecs-info.json"
  content = <<EOF
    {
      "ecs": {
        "fargate_arn":"${aws_ecs_cluster.ecs_fargate.arn}"
      },
      "ecr": {
        "endpoint": "${split("/", aws_ecr_repository.backend.repository_url)[0]}",
        "backend":{
          "arn":"${aws_ecr_repository.backend.arn}",
          "repository_url":"${aws_ecr_repository.backend.repository_url}"
        },
        "frontend":{
          "arn":"${aws_ecr_repository.frontend.arn}",
          "repository_url":"${aws_ecr_repository.frontend.repository_url}"
        }
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
