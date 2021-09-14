## resources block

resource "aws_security_group" "frontend_sg" {
  name = format("%s-frontend-lb-access",var.environment)
  description = "Allow public access to frontend"
  vpc_id = local.network_info.vpc
  
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = [aws_security_group.frontend-alb-sg.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }
}

resource "aws_ecs_task_definition" "frontend_task" {
  family                = format("frontend-%s", substr(uuid(),0,6))
  container_definitions = templatefile(
    "templates/frontend.tpl",
    {
      repository_url = local.ecs_info.ecr.frontend.repository_url,
      tag = var.git_tag,
      backend-lb = aws_alb.backend-alb.dns_name
    }
  )
  requires_compatibilities = [ "FARGATE" ]
  task_role_arn = aws_iam_role.frontend_ecs_task_role.arn
  execution_role_arn       = aws_iam_role.frontend_ecs_task_execution_role.arn
  network_mode = "awsvpc"
  cpu = "256"
  memory = "512"
  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }

  depends_on = [
    null_resource.docker_build
  ]
  lifecycle {
    ignore_changes = [ family ]
  }
}

resource "aws_ecs_service" "frontend_service" {
  name            = "frontend"
  cluster         = local.ecs_info.ecs.fargate_arn
  task_definition = aws_ecs_task_definition.frontend_task.arn
  desired_count   = 3
  launch_type     = "FARGATE"
  deployment_maximum_percent = 200
  deployment_minimum_healthy_percent = 100

  network_configuration {
    subnets = flatten(values(local.network_info["subnets"]["private"]))
    security_groups = [aws_security_group.frontend_sg.id] #,aws_security_group.backend-alb-sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.frontend-tg.arn
    container_name   = "frontend"
    container_port   = 80
  }

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }
}

resource "aws_iam_role" "frontend_ecs_task_role" {
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy" "frontend-ecs_task_role_ecr_attachment_policy" {
  role = aws_iam_role.frontend_ecs_task_role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
       {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchGetImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:PutImage"            ],
            "Resource": "${local.ecs_info.ecr.frontend.arn}"
        }
    ]
}
EOF
}

resource "aws_iam_role" "frontend_ecs_task_execution_role" {
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "frontend-ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.frontend_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
