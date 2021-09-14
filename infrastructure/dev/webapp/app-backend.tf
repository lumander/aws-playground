## resources block

resource "aws_security_group" "backend_sg" {
  name = format("%s-backend-lb-access",var.environment)
  description = "Allow frontend access to backend"

  vpc_id = local.network_info.vpc
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = [aws_security_group.backend-alb-sg.id]
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


resource "aws_ecs_task_definition" "backend_task" {
  family                = format("backend-%s", substr(uuid(),0,6))
  container_definitions = templatefile(
    "templates/backend.tpl",
    {
      repository_url = local.ecs_info.ecr.backend.repository_url,
      tag = var.git_tag
    }
  )
  requires_compatibilities = [ "FARGATE" ]
  task_role_arn = aws_iam_role.backend_ecs_task_role.arn
  execution_role_arn       = aws_iam_role.backend_ecs_task_execution_role.arn
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

resource "aws_ecs_service" "backend_service" {
  name            = "backend"
  cluster         = local.ecs_info.ecs.fargate_arn
  task_definition = aws_ecs_task_definition.backend_task.arn
  desired_count   = 3
  launch_type     = "FARGATE"
  deployment_maximum_percent = 200
  deployment_minimum_healthy_percent = 100

  network_configuration {
    subnets = flatten(values(local.network_info["subnets"]["private"]))
    security_groups = [aws_security_group.backend_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.backend-tg.arn
    container_name   = "backend"
    container_port   = 9000
  }

  tags = {
    "environment" = var.environment
    "project" = var.project
    "tag" = var.git_tag
  }
}

resource "aws_iam_role" "backend_ecs_task_role" {
 
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

resource "aws_iam_role_policy" "backend_ecs_task_role_ecr_attachment_policy" {
  role = aws_iam_role.backend_ecs_task_role.id
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
            "Resource": "${local.ecs_info.ecr.backend.arn}"
        }
    ]
}
EOF
}

resource "aws_iam_role" "backend_ecs_task_execution_role" {
 
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

resource "aws_iam_role_policy_attachment" "backend-ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.backend_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

