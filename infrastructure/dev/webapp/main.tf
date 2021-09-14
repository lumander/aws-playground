provider "aws" {
    region = var.region
}

terraform {
  backend "s3" {
    key = "dev/webapp/terraform.tfstate"
    dynamodb_table = "tf-locks-webapp-2b88ad"
  }
}

## variables & data sources block

data "aws_s3_bucket_object" "network_info" {
  bucket = var.state_bucket
  key    = "dev/networking/network-info.json"
}

data "aws_s3_bucket_object" "ecs_info" {
  bucket = var.state_bucket
  key    = "dev/ecs/ecs-info.json"
}

locals {
  network_info = jsondecode(data.aws_s3_bucket_object.network_info.body)
  ecs_info     = jsondecode(data.aws_s3_bucket_object.ecs_info.body)
}

resource "null_resource" "docker_build" {

  provisioner "local-exec" {
    command = <<EOF
      export ECR_REPO=${local.ecs_info.ecr.endpoint}
      export ECR_BACKEND_REPO=${local.ecs_info.ecr.backend.repository_url}
      export ECR_FRONTEND_REPO=${local.ecs_info.ecr.frontend.repository_url}
      export TAG=${var.git_tag}
      export INTERNAL_BE_LB=${aws_alb.backend-alb.dns_name}:9000

      bash -x ../../../code/build-n-push.sh
    EOF
    interpreter = ["bash", "-c"]
  }

  triggers = {
    deploy = var.git_tag
  }

}
