output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  value = var.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  value = var.private_subnet_cidrs
}

# Security Groups

output "glue_sagemaker_lambda_security_group_id" {
  description = "ID of the glue_sagemaker_lambda security group"
  value       = aws_security_group.glue_sagemaker_lambda.id
}
