provider "aws" {
  region = var.aws_region
}

# ------------------------------------------------------------------------------
# 1. ECR REPOSITORY (For your Docker Image)
# ------------------------------------------------------------------------------
resource "aws_ecr_repository" "app_repo" {
  name                 = var.service_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true # Helps with easy teardown for the assessment

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ------------------------------------------------------------------------------
# 2. DYNAMODB TABLE (Serverless Storage)
# ------------------------------------------------------------------------------
resource "aws_dynamodb_table" "events_table" {
  name         = "SkynetEvents_${var.environment}"
  billing_mode = "PAY_PER_REQUEST" # Crucial for the $25-$75 budget
  hash_key     = "eventId"

  attribute {
    name = "eventId"
    type = "S"
  }

  tags = {
    Environment = var.environment
    Service     = var.service_name
  }
}

# ------------------------------------------------------------------------------
# 3. CLOUDWATCH LOG GROUP (Observability)
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ecs/${var.service_name}-${var.environment}"
  retention_in_days = 7 # Prevents infinite storage growth

  tags = {
    Environment = var.environment
    Service     = var.service_name
  }
}

# Output the ECR URL so you can push your image to it easily
output "ecr_repository_url" {
  value = aws_ecr_repository.app_repo.repository_url
}