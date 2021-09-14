## frontend

resource "aws_security_group" "frontend-alb-sg" {
  name   = "frontend-dev-alb-sg"
  vpc_id = local.network_info["vpc"]

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }
}

resource "aws_security_group_rule" "http_from_anywhere" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend-alb-sg.id
}

resource "aws_security_group_rule" "outbound_internet_access" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend-alb-sg.id
}

## backend

resource "aws_security_group" "backend-alb-sg" {
  name   = "backend-dev-alb-sg"
  vpc_id = local.network_info["vpc"]

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }
}

resource "aws_security_group_rule" "http_from_frontend-lb" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  source_security_group_id = aws_security_group.frontend_sg.id
  security_group_id = aws_security_group.backend-alb-sg.id
}

resource "aws_security_group_rule" "http_to_frontend" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend-alb-sg.id
}
