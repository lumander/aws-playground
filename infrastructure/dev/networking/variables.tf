variable "region" {
  default = "eu-west-1"
}

variable environment {
  default = "dev"
}

variable "project" {
  default = "aws-playground"
}

variable "vpc" {
  default = {
    "vpc_cidr_block" = "172.32.0.0/16"
    "subnets" = {
      "private" = {
        "eu-west-1a" = ["172.32.0.0/24"]
        "eu-west-1b" = ["172.32.2.0/24"]
        "eu-west-1c" = ["172.32.4.0/24"]
      }
      "db" = {
        "eu-west-1a" = ["172.32.1.0/24"]
        "eu-west-1b" = ["172.32.3.0/24"]
        "eu-west-1c" = ["172.32.5.0/24"]
      }
      "public" = {
        "eu-west-1a" = ["172.32.6.0/24"]
        "eu-west-1b" = ["172.32.7.0/24"]
        "eu-west-1c" = ["172.32.8.0/24"]
      }

    }
  }
}

variable "git_tag" {
  type = string
}

variable "state_bucket" {
  type = string
}