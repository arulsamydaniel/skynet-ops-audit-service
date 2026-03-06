# 1. NETWORKING (Use Default VPC for simplicity and cost)
data "aws_vpc" "default" {
  default = true
}
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 2. SECURITY GROUP (Allow traffic to port 3000)
resource "aws_security_group" "ecs_sg" {
  name        = "${var.service_name}-sg"
  description = "Allow inbound traffic to the audit service"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to the internet for assessment testing
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. IAM ROLES (Least Privilege Strategy)
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.service_name}-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.service_name}-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy" "dynamodb_access" {
  name = "DynamoDBAccessPolicy"
  role = aws_iam_role.ecs_task_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["dynamodb:PutItem", "dynamodb:Scan", "dynamodb:Query"]
      Resource = aws_dynamodb_table.events_table.arn # Restricts access to ONLY this table
    }]
  })
}

# 4. ECS CLUSTER & TASK DEFINITION
resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.service_name}-cluster"
}

resource "aws_ecs_task_definition" "app_task" {
  family                   = var.service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # Minimal pilot configuration
  memory                   = "512" 
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = var.service_name
    image     = "${aws_ecr_repository.app_repo.repository_url}:latest"
    essential = true
    portMappings = [{ containerPort = 3000, hostPort = 3000 }]
    
    # Passing the config environment variables expected by the assessment
    environment = [
      { name = "PORT", value = "3000" },
      { name = "STORE_BACKEND", value = "dynamodb" },
      { name = "DYNAMODB_TABLE_NAME", value = aws_dynamodb_table.events_table.name },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "METRICS_DEMO_ENABLED", value = "true" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.app_logs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# 5. ECS SERVICE
resource "aws_ecs_service" "app_service" {
  name            = "${var.service_name}-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true # Eliminates the need for a costly NAT Gateway
  }
}