output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.backend.name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.backend.name
}

output "ecs_task_definition_family" {
  description = "Family name of the ECS task definition"
  value       = aws_ecs_task_definition.backend.family
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_url" {
  description = "URL of the Application Load Balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

output "github_actions_user_name" {
  description = "IAM user name for GitHub Actions"
  value       = aws_iam_user.github_actions.name
}

output "github_actions_user_arn" {
  description = "ARN of the IAM user for GitHub Actions"
  value       = aws_iam_user.github_actions.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for ECS tasks"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "security_group_ecs_tasks" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "mssql_service_dns" {
  description = "DNS name to reach MSSQL via service discovery"
  value       = "${aws_service_discovery_service.mssql.name}.${aws_service_discovery_private_dns_namespace.mssql_ns.name}"
}

output "mssql_secret_arn" {
  description = "ARN of the MSSQL SA password secret in Secrets Manager"
  value       = aws_secretsmanager_secret.mssql.arn
}

output "frontend_service_name" {
  description = "Name of the Frontend ECS service"
  value       = aws_ecs_service.frontend.name
}

output "frontend_task_definition_family" {
  description = "Family name of the Frontend ECS task definition"
  value       = aws_ecs_task_definition.frontend.family
}

output "backend_api_url" {
  description = "Backend API URL (ALB URL with /api prefix)"
  value       = "http://${aws_lb.main.dns_name}/api"
}

output "instructions" {
  description = "Next steps after Terraform apply"
  value       = <<-EOT
    
    ✅ Infrastructure created successfully!
    
    Next steps:
    
    1. Create access keys for GitHub Actions user:
       aws iam create-access-key --user-name ${aws_iam_user.github_actions.name}
    
    2. Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):
       - AWS_ACCESS_KEY_ID: (from step 1)
       - AWS_SECRET_ACCESS_KEY: (from step 1)
       - AWS_REGION: ${var.aws_region}
       - ECS_CLUSTER: ${aws_ecs_cluster.main.name}
       - ECS_SERVICE: ${aws_ecs_service.backend.name}
       - ECS_TASK_DEFINITION: ${aws_ecs_task_definition.backend.family}
       - ECR_REPOSITORY: ${aws_ecr_repository.backend.name}
       
       For Frontend repository:
       - AWS_REGION: ${var.aws_region}
       - ECS_CLUSTER: ${aws_ecs_cluster.main.name}
       - ECS_SERVICE: ${aws_ecs_service.frontend.name}
       - ECS_TASK_DEFINITION: ${aws_ecs_task_definition.frontend.family}
       - BACKEND_API_URL: http://${aws_lb.main.dns_name}/api
    
    3. Your application will be accessible at:
       Frontend: http://${aws_lb.main.dns_name}
       Backend API: http://${aws_lb.main.dns_name}/api
    
    4. View logs:
       aws logs tail ${aws_cloudwatch_log_group.ecs.name} --follow
    
    5. Push to feature/pipeline branch to trigger deployment
  EOT
}
