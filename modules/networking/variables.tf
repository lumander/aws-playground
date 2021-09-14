variable "vpc_cidr_block" {
    type = string
    description = "CIDR block of the vpc"
}

variable "environment" {
    type = string
    description = "Environment"
    validation {
      condition     = var.environment == "dev" || var.environment == "stg" || var.environment == "prod"
      error_message = "The environment must be properly set!"
  }
}

variable "project" {
    type = string
    description = "Project where to create the resource"
}

variable "git_tag" {
  type = string
}

variable "subnets" {
    type =  map(map(list(string)))   
    description = "Map containing public and private subnets and their zones"
}
