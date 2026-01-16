variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "irent-backend"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "irent-backend"
}

variable "container_name" {
  description = "Name of the container (must match GitHub workflow IMAGE_NAME)"
  type        = string
  default     = "backend"
}

variable "ecs_task_cpu" {
  description = "Fargate task CPU units (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "1024"
}

variable "ecs_task_memory" {
  description = "Fargate task memory in MB (512, 1024, 2048, etc.)"
  type        = string
  default     = "2048"
}

variable "ecs_service_desired_count" {
  description = "Number of tasks to run in the ECS service"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "iRent"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

variable "mssql_sa_password" {
  description = "MSSQL SA password (pipeline uses this hard-coded value)"
  type        = string
  default     = "MyP@ssw0rd123!"
}
