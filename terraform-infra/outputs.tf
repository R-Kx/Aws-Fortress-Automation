output "alb_dns" {
    value       = aws_lb.flask_alb.dns_name
    description = "web url"
}

output "rds_endpoint" {
    value       = aws_db_instance.flask_rds.endpoint
    description = "address of rds"
}

output "ecr_url" {
    value       = aws_ecr_repository.flask_app.repository_url
    description = "url for ecr image"
}

output "s3_bucket_name" {
    value       = aws_s3_bucket.flask_bucket.id
    description = "name of s3 bucket"
}

/*output "secrets_manager_arn" {
    value       = aws_secretsmanager_secret.db_secret_pass.arn
    description = "Arn for secrets manager"
}*/

output "vpc_id" {
    value       = aws_vpc.flask_vpc.id
    description = "ID of VPC"
}

output "private_subnets" {
    value       = aws_subnet.private[*].id
    description = "ID s for private subnets"
}

output "launch_template_tags" {
    value       = aws_launch_template.flask_api_lt.tag_specifications[*].tags
    description = "Tags defined in Launch Template for ec2 servers"
}
output "asg_tags" {
    value       = aws_autoscaling_group.flask_asg.tag
    description = "Tags defined in asg"
}

/*output "rds_password" {
    value       = random_password.db-pass.result
    sensitive   = true
    description = "pass for rds"
}*/

output "rds_endpoint_address" {
    value = aws_db_instance.flask_rds.address
}