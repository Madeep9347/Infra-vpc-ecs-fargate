# ECS Cluster
resource "aws_ecs_cluster" "fargate_cluster" {
  name = "my-fargate-cluster"
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "my_ecs_task_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach ECS Task Execution Role Policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Security Groups for ALB and ECS
resource "aws_security_group" "alb_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb_sg"
  }
}

resource "aws_security_group" "ecs_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs_sg"
  }
}

# ALB and Listeners
resource "aws_lb" "ecs_alb" {
  name               = "ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnets

  tags = {
    Name = "ecs-alb"
  }
}

resource "aws_lb_listener" "ecs_alb_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Okay"
      status_code  = "200"
    }
  }
}

# SQS Queue
resource "aws_sqs_queue" "my_sqs_queue" {
  name                      = "my-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600
  delay_seconds              = 0
  receive_wait_time_seconds  = 0

  tags = {
    Name = "my-queue"
  }
}

# IAM Role Policy for SQS Access
resource "aws_iam_role_policy" "ecs_task_sqs_access" {
  name = "ecs-task-sqs-access"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = aws_sqs_queue.my_sqs_queue.arn
      }
    ]
  })
}

# ECS Task Definition for Auth Service
resource "aws_ecs_task_definition" "auth_task" {
  family                   = "auth-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "auth-container",
    image     = var.auth_container_image,
    essential = true,
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }],
    environment = [
      {
        name  = "SQS_QUEUE_URL"
        value = aws_sqs_queue.my_sqs_queue.url
      }
    ]
  }])
}

# ECS Task Definition for EnvironXchange Service
resource "aws_ecs_task_definition" "environxchange_task" {
  family                   = "environxchange-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "environxchange-container",
    image     = var.environxchange_container_image,
    essential = true,
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }],
    environment = [
      {
        name  = "SQS_QUEUE_URL"
        value = aws_sqs_queue.my_sqs_queue.url
      }
    ]
  }])
}

# ECS Services
resource "aws_ecs_service" "auth_service" {
  name            = "auth-service"
  cluster         = aws_ecs_cluster.fargate_cluster.id
  task_definition = aws_ecs_task_definition.auth_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.auth_tg.arn
    container_name   = "auth-container"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.ecs_alb_listener]
}

resource "aws_ecs_service" "environxchange_service" {
  name            = "environxchange-service"
  cluster         = aws_ecs_cluster.fargate_cluster.id
  task_definition = aws_ecs_task_definition.environxchange_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.environxchange_tg.arn
    container_name   = "environxchange-container"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.ecs_alb_listener]
}

# ALB Target Groups
resource "aws_lb_target_group" "auth_tg" {
  name        = "auth-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_lb_target_group" "environxchange_tg" {
  name        = "environxchange-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

# ALB Listener Rules
resource "aws_lb_listener_rule" "auth_rule" {
  listener_arn = aws_lb_listener.ecs_alb_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth_tg.arn
  }

  condition {
    path_pattern {
      values = ["/auth*"]
    }
  }
}

resource "aws_lb_listener_rule" "environxchange_rule" {
  listener_arn = aws_lb_listener.ecs_alb_listener.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.environxchange_tg.arn
  }

  condition {
    path_pattern {
      values = ["/environxchange*"]
    }
  }
}
