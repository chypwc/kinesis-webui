# =============================================================================
# VARIABLES FOR DEV ENVIRONMENT
# =============================================================================

# Environment
variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# Region
variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

# S3 Bucket for Firehose
variable "firehose_bucket_name" {
  description = "Name of the S3 bucket for Firehose delivery"
  type        = string
  default     = "kinesis-firehose-bucket"
}

# Kinesis Stream
variable "kinesis_stream_name" {
  description = "Name of the Kinesis Data Stream"
  type        = string
  default     = "api-kinesis-stream"
}

variable "kinesis_shard_count" {
  description = "Number of shards for Kinesis stream"
  type        = number
  default     = 1
}

variable "kinesis_retention_period" {
  description = "Retention period for Kinesis stream (hours)"
  type        = number
  default     = 24
}

# Firehose Stream
variable "firehose_stream_name" {
  description = "Name of the Firehose delivery stream"
  type        = string
  default     = "api-firehose-stream"
}

# Lambda Function
variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "api-lambda-function"
}

variable "lambda_handler" {
  description = "Lambda function handler"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "lambda_runtime" {
  description = "Lambda function runtime"
  type        = string
  default     = "python3.12"
}

# API Gateway
variable "api_gateway_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "api-gateway"
}

# Webapp Hosting
variable "webapp_bucket_name" {
  description = "Name of the S3 bucket for webapp hosting"
  type        = string
  default     = "kinesis-webapp-bucket"
}

variable "cloudfront_distribution_name" {
  description = "Name of the CloudFront distribution"
  type        = string
  default     = "kinesis-webapp-distribution"
}
