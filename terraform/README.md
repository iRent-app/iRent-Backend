# iRent Backend - Terraform Infrastructure

This Terraform configuration creates all necessary AWS infrastructure for deploying the iRent backend application using ECS Fargate.

## What Gets Created

- **ECR Repository**: For storing Docker images
- **VPC**: With public subnets across 2 availability zones
- **Application Load Balancer**: For distributing traffic to ECS tasks
- **ECS Cluster**: Fargate cluster for running containers
- **ECS Service**: Manages running tasks with auto-scaling capability
- **Security Groups**: For ALB and ECS tasks
- **IAM Roles & Policies**: For ECS task execution and GitHub Actions
- **CloudWatch Log Group**: For application logs

## Prerequisites

1. **AWS Account**: Active AWS account with appropriate permissions
2. **AWS CLI**: Installed and configured
   ```bash
   aws configure
   ```
3. **Terraform**: Version 1.0 or higher
   ```bash
   # Download from https://www.terraform.io/downloads
   # Or use package manager:
   # Windows (Chocolatey): choco install terraform
   # macOS (Homebrew): brew install terraform
   # Linux: Check your package manager
   ```

## Quick Start

### 1. Initialize Terraform
```bash
cd terraform
terraform init
```

### 2. Review the Plan
```bash
terraform plan
```

### 3. Apply Configuration
```bash
terraform apply
```

Type `yes` when prompted to create resources.

### 4. Save Outputs
After apply completes, save the outputs:
```bash
terraform output > terraform-outputs.txt
```

### 5. Create GitHub Actions Access Keys
```bash
aws iam create-access-key --user-name irent-backend-github-actions
```

**⚠️ IMPORTANT**: Save the `AccessKeyId` and `SecretAccessKey` immediately. You cannot retrieve the secret key later.

### 6. Configure GitHub Secrets

Go to your GitHub repository: **Settings → Secrets and variables → Actions**

Add these secrets (get values from `terraform output`):

| Secret Name | Value Source |
|-------------|--------------|
| `AWS_ACCESS_KEY_ID` | From IAM access key creation (step 5) |
| `AWS_SECRET_ACCESS_KEY` | From IAM access key creation (step 5) |
| `AWS_REGION` | `terraform output aws_region` or your chosen region |
| `ECS_CLUSTER` | `terraform output ecs_cluster_name` |
| `ECS_SERVICE` | `terraform output ecs_service_name` |
| `ECS_TASK_DEFINITION` | `terraform output ecs_task_definition_family` |
| `ECR_REPOSITORY` | `terraform output ecr_repository_name` |

### 7. Deploy Application

Push to the `feature/pipeline` branch:
```bash
git add .
git commit -m "Deploy to AWS ECS"
git push origin feature/pipeline
```

The GitHub Actions workflow will automatically build, push, and deploy your application.

## Accessing Your Application

Get the Application Load Balancer URL:
```bash
terraform output alb_url
```

Or view in outputs:
```bash
terraform output alb_dns_name
```

Your application will be available at: `http://<alb-dns-name>`

Health check endpoint: `http://<alb-dns-name>/actuator/health`

## Customization

Edit `variables.tf` or create `terraform.tfvars`:

```hcl
# terraform.tfvars
aws_region                 = "eu-west-1"
project_name               = "my-backend"
ecs_task_cpu              = "512"
ecs_task_memory           = "1024"
ecs_service_desired_count = 2
```

Then reapply:
```bash
terraform apply
```

## Monitoring

### View Logs
```bash
# Tail logs in real-time
aws logs tail /ecs/irent-backend --follow

# View specific time range
aws logs tail /ecs/irent-backend --since 1h
```

### Check Service Status
```bash
# Get cluster name from terraform
CLUSTER=$(terraform output -raw ecs_cluster_name)
SERVICE=$(terraform output -raw ecs_service_name)

# Describe service
aws ecs describe-services --cluster $CLUSTER --services $SERVICE

# List running tasks
aws ecs list-tasks --cluster $CLUSTER --service-name $SERVICE

# View task details
TASK_ARN=$(aws ecs list-tasks --cluster $CLUSTER --service-name $SERVICE --query 'taskArns[0]' --output text)
aws ecs describe-tasks --cluster $CLUSTER --tasks $TASK_ARN
```

### CloudWatch Insights Query
```sql
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 20
```

## Updating Infrastructure

1. Modify Terraform files
2. Review changes:
   ```bash
   terraform plan
   ```
3. Apply changes:
   ```bash
   terraform apply
   ```

## Cost Estimation

Approximate monthly costs (us-east-1):
- **Fargate (1 task, 1 vCPU, 2GB)**: ~$30
- **Application Load Balancer**: ~$23
- **NAT Gateway** (if added): ~$32
- **Data Transfer**: Variable
- **CloudWatch Logs**: ~$0.50-$5

**Total**: ~$55-$90/month for basic setup

Reduce costs:
- Use smaller task size (0.5 vCPU, 1GB): ~$15/month
- Use NLB instead of ALB: ~$16/month
- Reduce log retention
- Use ECS Service Auto-scaling

## Troubleshooting

### Issue: Task fails to start
**Check logs:**
```bash
aws logs tail /ecs/irent-backend --follow
```

**Common causes:**
- Image pull errors (check ECR permissions)
- Health check failures (verify `/actuator/health` endpoint)
- Resource limits (increase CPU/memory in `variables.tf`)

### Issue: Cannot access ALB endpoint
**Check security groups:**
```bash
aws ec2 describe-security-groups --group-ids $(terraform output -raw security_group_alb)
```

**Verify target health:**
```bash
TG_ARN=$(aws elbv2 describe-target-groups --names irent-backend-tg --query 'TargetGroups[0].TargetGroupArn' --output text)
aws elbv2 describe-target-health --target-group-arn $TG_ARN
```

### Issue: GitHub Actions deployment fails
**Verify IAM permissions:**
```bash
aws iam get-user-policy --user-name irent-backend-github-actions --policy-name irent-backend-github-actions-policy
```

**Test ECR login:**
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(terraform output -raw ecr_repository_url)
```

## Cleanup

To destroy all resources:

```bash
# Preview what will be deleted
terraform plan -destroy

# Destroy all resources
terraform destroy
```

Type `yes` to confirm.

**⚠️ WARNING**: This will permanently delete:
- All Docker images in ECR
- All logs in CloudWatch
- The entire infrastructure

Make sure to backup anything important before destroying.

## State Management (Recommended for Production)

For production, store Terraform state in S3:

1. Create S3 bucket and DynamoDB table:
```bash
aws s3 mb s3://irent-terraform-state
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

2. Add backend configuration to `main.tf`:
```hcl
terraform {
  backend "s3" {
    bucket         = "irent-terraform-state"
    key            = "backend/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

3. Re-initialize:
```bash
terraform init -migrate-state
```

## Additional Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/intro.html)
- [AWS Fargate Pricing](https://aws.amazon.com/fargate/pricing/)
