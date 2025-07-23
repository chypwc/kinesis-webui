# =============================================================================
# OUTPUTS FOR DEV ENVIRONMENT
# =============================================================================

# Data Pipeline Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket for Firehose delivery"
  value       = module.s3.bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3.bucket_arn
}

output "kinesis_stream_name" {
  description = "Name of the Kinesis Data Stream"
  value       = module.kinesis.stream_name
}

output "kinesis_stream_arn" {
  description = "ARN of the Kinesis Data Stream"
  value       = module.kinesis.stream_arn
}

output "firehose_stream_name" {
  description = "Name of the Firehose delivery stream"
  value       = module.firehose.firehose_stream_name
}

output "firehose_stream_arn" {
  description = "ARN of the Firehose delivery stream"
  value       = module.firehose.firehose_stream_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.function_arn
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = module.api_gateway.api_id
}

output "api_invoke_url" {
  description = "Invoke URL for the API Gateway"
  value       = module.api_gateway.invoke_url
}

# Webapp Hosting Outputs
output "webapp_bucket_name" {
  description = "Name of the S3 bucket for webapp hosting"
  value       = module.s3_webapp.bucket_id
}

output "webapp_bucket_arn" {
  description = "ARN of the S3 bucket for webapp hosting"
  value       = module.s3_webapp.bucket_arn
}

output "webapp_s3_website_endpoint" {
  description = "S3 website endpoint for the webapp"
  value       = module.s3_webapp.website_endpoint
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.cloudfront.distribution_domain_name
}

output "webapp_url" {
  description = "URL of the deployed webapp"
  value       = module.cloudfront.webapp_url
}

# =============================================================================
# FEATURE ENGINEERING OUTPUTS
# =============================================================================

output "glue_job_name" {
  description = "Name of the Glue job"
  value       = module.glue_job.job_name
}

output "glue_job_arn" {
  description = "ARN of the Glue job"
  value       = module.glue_job.job_arn
}



# =============================================================================
# DYNAMODB OUTPUTS
# =============================================================================

output "products_table_name" {
  description = "Name of the products DynamoDB table"
  value       = module.dynamodb.products_table_name
}

output "products_table_arn" {
  description = "ARN of the products DynamoDB table"
  value       = module.dynamodb.products_table_arn
}

output "user_product_features_table_name" {
  description = "Name of the user_product_features DynamoDB table"
  value       = module.dynamodb.user_product_features_table_name
}

output "user_product_features_table_arn" {
  description = "ARN of the user_product_features DynamoDB table"
  value       = module.dynamodb.user_product_features_table_arn
}

# =============================================================================
# STEP FUNCTIONS OUTPUTS
# =============================================================================

output "step_functions_state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = module.step_functions.state_machine_arn
}

output "step_functions_state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = module.step_functions.state_machine_name
}

output "step_functions_execution_role_arn" {
  description = "ARN of the Step Functions execution role"
  value       = module.step_functions.execution_role_arn
}
