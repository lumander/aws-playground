provider "aws" {
    region = var.region  
}

resource "aws_s3_bucket" "state_bucket" {
  bucket = format("%s-%s-%s", var.project, var.environment, substr(uuid(),0,6))

# Prevent accidental deletion of this S3 bucket
  lifecycle {
    prevent_destroy = false
    ignore_changes = [ bucket ]
  }

# Enable versioning so we can see the full revision history of our
# state files
  versioning {
    enabled = true
  }

# Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "null_resource" "backend_hcl" {
  provisioner "local-exec" {
    command = <<EOF
      echo "bucket = \"${aws_s3_bucket.state_bucket.bucket}\"" > ../../${var.environment}/${var.environment}-backend.hcl
      echo "region = \"eu-west-1\"" >> ../../${var.environment}/${var.environment}-backend.hcl
    EOF
    interpreter = ["bash", "-c"]
  }
}

# lock tables

resource "aws_dynamodb_table" "tf_locks_networking" {
  name = "tf-locks-networking-2b88ad"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }

}

resource "aws_dynamodb_table" "tf_locks_ecs" {
  name = "tf-locks-ecs-2b88ad"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }

}

resource "aws_dynamodb_table" "tf_locks_rds" {
  name = "tf-locks-rds-2b88ad"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }

}

resource "aws_dynamodb_table" "tf_locks_webapp" {
  name = "tf-locks-webapp-2b88ad"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }

}