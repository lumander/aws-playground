### vpc

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }
}

### subnets

locals {
  private_subnets = flatten([
    for zone, cidr_blocks in var.subnets["private"] : [
      for block in cidr_blocks : { 
        zone = zone
        cidr_block = block
      }
    ]
  ])

  db_private_subnets = flatten([
    for zone, cidr_blocks in var.subnets["db"] : [
      for block in cidr_blocks : { 
        zone = zone
        cidr_block = block
      }
    ]
  ])

  public_subnets = flatten([
    for zone, cidr_blocks in var.subnets["public"] : [
      for block in cidr_blocks : { 
        zone = zone
        cidr_block = block
      }
    ]
  ])
}

resource "aws_subnet" "vpc_private_subnets" {
  for_each = {
      for subnet in local.private_subnets : "${subnet.zone}:${subnet.cidr_block}" => subnet
    }

  vpc_id     = aws_vpc.vpc.id
  cidr_block = each.value.cidr_block
  availability_zone = each.value.zone

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
    "type" = "private"
  }
}

resource "aws_subnet" "vpc_db_private_subnets" {
  for_each = {
      for subnet in local.db_private_subnets : "${subnet.zone}:${subnet.cidr_block}" => subnet
    }

  vpc_id     = aws_vpc.vpc.id
  cidr_block = each.value.cidr_block
  availability_zone = each.value.zone

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
    "type" = "db"
  }
}

resource "aws_subnet" "vpc_public_subnets" {
  for_each = {
      for subnet in local.public_subnets : "${subnet.zone}:${subnet.cidr_block}" => subnet
    }

  vpc_id     = aws_vpc.vpc.id
  cidr_block = each.value.cidr_block
  availability_zone = each.value.zone

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
    "type" = "public"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }
}

resource "aws_route_table" "dev-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }
}

resource "aws_route_table_association" "pub-rt-bind" {
  for_each = aws_subnet.vpc_public_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.dev-rt.id
}

resource "aws_eip" "eip-ngw" {
  vpc      = true
  
  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.eip-ngw.id
  subnet_id     = values(aws_subnet.vpc_public_subnets)[0].id
  
  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }
}

resource "aws_route_table" "ngw-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }
}

resource "aws_route_table_association" "db-prv-rt-bind" {
  for_each = aws_subnet.vpc_db_private_subnets
  
  subnet_id      = each.value.id
  route_table_id = aws_route_table.ngw-rt.id
}

resource "aws_route_table_association" "prv-rt-bind" {
  for_each = aws_subnet.vpc_private_subnets
  
  subnet_id      = each.value.id
  route_table_id = aws_route_table.ngw-rt.id
}
