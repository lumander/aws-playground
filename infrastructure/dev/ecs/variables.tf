variable "region" {
  default = "eu-west-1"
}

variable environment {
  default = "dev"
}

variable "project" {
  default = "aws-playground"
}

variable "git_tag" {
  type = string
}

variable "state_bucket" {
  type = string
}