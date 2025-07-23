# =============================================================================
# VARIABLES FOR DEV ENVIRONMENT
# =============================================================================

# Environment
variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

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
}

variable "cloudfront_distribution_name" {
  description = "Name of the CloudFront distribution"
  type        = string
  default     = "kinesis-webapp-distribution"
}

variable "scripts_bucket_name" {
  description = "Name of the S3 bucket for Glue scripts"
  type        = string
  default     = "imba-chien-glue-scripts"
}

variable "training_job_name" {
  description = "Name of the SageMaker training job"
  type        = string
  default     = "xgboost-training-job"
}

variable "endpoint_name" {
  description = "Name of the SageMaker endpoint"
  type        = string
  default     = "xgboost-endpoint"
}

variable "endpoint_config_name" {
  description = "Name of the SageMaker endpoint configuration"
  type        = string
  default     = "xgboost-endpoint-config"
}

variable "lambda_architecture" {
  description = "Lambda architecture"
  type        = string
}

variable "sklearn_wheel_filename" {
  description = "The filename of the scikit-learn wheel"
  type        = string
}
