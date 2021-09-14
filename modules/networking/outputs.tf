output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_private_subnets" {
  value = aws_subnet.vpc_private_subnets
}

output "vpc_db_private_subnets" {
  value = aws_subnet.vpc_db_private_subnets
}

output "vpc_public_subnets" {
  value = aws_subnet.vpc_public_subnets
}

output "ngw" {
  value = aws_nat_gateway.ngw
}