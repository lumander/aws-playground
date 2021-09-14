## frontend load balancers

resource "aws_alb_target_group" "frontend-tg" {
  name                 = format("frontend-tg-%s", substr(uuid(),0,6))
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = local.network_info["vpc"]
  target_type = "ip"

  health_check {
    path     = "/*"
    protocol = "HTTP"
  }

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [name]
  }
}

resource "aws_alb" "frontend-alb" {
  name            = "frontend-dev-alb"
  subnets         = flatten(values(local.network_info["subnets"]["public"]))
  security_groups = [aws_security_group.frontend-alb-sg.id]

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.frontend-alb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.frontend-tg.id
    type             = "forward"
  }
}

## backend load balancers

resource "aws_alb_target_group" "backend-tg" {
  name                 = format("backend-tg-%s", substr(uuid(),0,6))
  port                 = 9000
  protocol             = "HTTP"
  vpc_id               = local.network_info["vpc"]
  target_type = "ip"

  health_check {
    path     = "/ping"
    protocol = "HTTP"
  }

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [ name ]
  }
}

resource "aws_alb" "backend-alb" {
  name            = "backend-dev-alb"
  subnets         = flatten(values(local.network_info["subnets"]["private"]))
  security_groups = [aws_security_group.backend-alb-sg.id]
  internal = true

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }
}

resource "aws_alb_listener" "backend-http" {
  load_balancer_arn = aws_alb.backend-alb.id
  port              = "9000"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.backend-tg.id
    type             = "forward"
  }
}
