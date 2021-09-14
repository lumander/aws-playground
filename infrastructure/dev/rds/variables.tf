variable "region" {
  default = "eu-west-1"
}

variable environment {
  default = "dev"
}

variable "project" {
  default = "aws-playground"
}

variable "db" {
  default = {
    "database_name" = "deploychallengedb"
    "availability_zones" = {
      "eu-west-1a" = 1
      "eu-west-1b" = 1
      "eu-west-1c" = 1
    }
  }
}

variable "git_tag" {
  type = string
}

variable "state_bucket" {
  type = string
}