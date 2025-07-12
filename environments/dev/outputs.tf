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
