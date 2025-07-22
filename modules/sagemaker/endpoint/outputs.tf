output "sagemaker_execution_role_arn" {
  description = "The ARN of the SageMaker execution role"
  value       = aws_iam_role.sagemaker_execution_role.arn
}

output "sagemaker_model_name" {
  description = "The name of the SageMaker model"
  value       = aws_sagemaker_model.xgb_model.name
}

output "sagemaker_endpoint_config_name" {
  description = "The name of the SageMaker endpoint configuration"
  value       = aws_sagemaker_endpoint_configuration.xgb_endpoint_config.name
}
