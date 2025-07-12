# =============================================================================
# AWS KINESIS DATA PIPELINE - MAIN INFRASTRUCTURE CONFIGURATION
# =============================================================================
# This file defines the complete infrastructure for the data pipeline:
# Web App → API Gateway → Lambda → Kinesis → Firehose → S3
# =============================================================================

# =============================================================================
# PHASE 1: STORAGE LAYER
# =============================================================================

# S3 Bucket for Firehose delivery
# This bucket receives all streamed data from Firehose delivery stream
# - force_destroy = true for easy cleanup during development
# - Versioning enabled for data recovery
# - Public access blocked for security
module "s3" {
  source = "../../modules/s3"

  bucket_name = var.firehose_bucket_name # e.g., "firehose-bucket-chien"
  env         = var.env                  # e.g., "dev"
}

# =============================================================================
# PHASE 1: STREAMING LAYER
# =============================================================================

# Kinesis Data Stream
# Real-time data streaming service that receives records from Lambda
# - 1 shard for development (can scale to multiple shards for production)
# - 24-hour retention period for data replay capabilities
# - Used as source for Firehose delivery stream
module "kinesis" {
  source = "../../modules/kinesis"

  stream_name      = var.kinesis_stream_name # e.g., "api-kinesis-stream"
  env              = var.env                 # e.g., "dev"
  shard_count      = 1                       # Single shard for development
  retention_period = 24                      # 24 hours retention
}

# =============================================================================
# PHASE 1: DELIVERY LAYER
# =============================================================================

# Firehose Delivery Stream (Kinesis → S3)
# Batches data from Kinesis and delivers to S3 bucket
# - Sources data from Kinesis stream
# - Buffers for 60 seconds or 1MB before delivery
# - Uncompressed format for easy processing
# - Creates IAM roles for Kinesis read and S3 write permissions
module "firehose" {
  source = "../../modules/firehose"

  stream_name        = var.firehose_stream_name  # e.g., "api-firehose-stream"
  kinesis_stream_arn = module.kinesis.stream_arn # ARN from Kinesis module
  s3_bucket_arn      = module.s3.bucket_arn      # ARN from S3 module
  env                = var.env                   # e.g., "dev"
  buffer_interval    = 60                        # 60 seconds buffer
  buffer_size        = 1                         # 1MB buffer size
}

# =============================================================================
# PHASE 2: COMPUTATION LAYER
# =============================================================================

# Lambda Function
# Serverless function that processes API Gateway requests and sends to Kinesis
# - Python 3.12 runtime
# - 30-second timeout for processing
# - IAM role with Kinesis write permissions
# - Environment variable for Kinesis stream name
# - Auto-creates deployment package from lambda_function.py
module "lambda" {
  source = "../../modules/lambda"

  function_name       = var.lambda_function_name # e.g., "api-lambda-function"
  env                 = var.env                  # e.g., "dev"
  kinesis_stream_name = var.kinesis_stream_name  # Passed as env var to Lambda
}

# =============================================================================
# PHASE 2: API LAYER
# =============================================================================

# API Gateway
# HTTP API that receives requests from web application
# - HTTP API type (faster than REST API)
# - POST /submit route for data submission
# - Auto-deployed to $default stage
# - Integrated with Lambda using AWS_PROXY mode
# - CORS headers handled by Lambda function
module "api_gateway" {
  source = "../../modules/api-gateway"

  api_name             = var.api_gateway_name        # e.g., "api-gateway"
  env                  = var.env                     # e.g., "dev"
  lambda_invoke_arn    = module.lambda.invoke_arn    # ARN from Lambda module
  lambda_function_name = module.lambda.function_name # Name for permissions
}

# =============================================================================
# DEPENDENCY ORDER:
# 1. S3 bucket (no dependencies)
# 2. Kinesis stream (no dependencies)
# 3. Firehose (depends on S3 and Kinesis)
# 4. Lambda (depends on Kinesis for env var)
# 5. API Gateway (depends on Lambda)
# =============================================================================
