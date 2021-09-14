variable "region" {
  default = "eu-west-1"
}

variable "environment" {}

variable "git_tag" {
  type = string
  default = "0.0.1"
}

variable "project" {
  default = "aws-playground"
}
