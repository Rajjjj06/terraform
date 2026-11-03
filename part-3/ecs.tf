resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-ecs-cluster"
  tags = {
    Name = "${var.project_name}-ecs-cluster"
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "frontend_logs" {
  name              = "/ecs/${var.project_name}/frontend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "backend_logs" {
  name              = "/ecs/${var.project_name}/backend"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = var.container_cpu
  memory = var.container_memory

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = var.frontend_image
      essential = true

      portMappings = [
        {
          containerPort = var.frontend_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "BACKEND_URL"
          value = "http://${aws_service_discovery_service.backend.name}.${aws_service_discovery_private_dns_namespace.main.name}:${var.backend_port}"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "frontend"
        }
      }
    }
  ])

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy
  ]
}


resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = var.container_cpu
  memory = var.container_memory

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = var.backend_image
      essential = true

      portMappings = [
        {
          containerPort = var.backend_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "backend"
        }
      }
    }
  ])

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy
  ]
}

resource "aws_ecs_service" "frontend" {
  name            = "${var.project_name}-frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.frontend-sg-1.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "frontend"
    container_port   = var.frontend_port
  }

  depends_on = [
    aws_lb_listener.frontend_listener
  ]

}

resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.backend-sg-2.id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.backend.arn
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_tg.arn
    container_name   = "backend"
    container_port   = var.backend_port
  }

  depends_on = [
    aws_lb_listener.backend_listener
  ]
}