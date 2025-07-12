# =============================================================================
# AWS KINESIS PIPELINE - DEV ENVIRONMENT
# =============================================================================
# This configuration deploys the complete data pipeline infrastructure
# including the webapp hosting with S3 and CloudFront.
# 
# Architecture:
# API Gateway → Lambda → Kinesis → Firehose → S3 (Data)
# Webapp: S3 (Hosting) → CloudFront (CDN)
# =============================================================================

# =============================================================================
# DATA PIPELINE INFRASTRUCTURE
# =============================================================================

# S3 bucket for Firehose data delivery
module "s3" {
  source = "../../modules/s3"

  bucket_name = var.firehose_bucket_name
  env         = var.env
}

# Kinesis Data Stream
module "kinesis" {
  source = "../../modules/kinesis"

  stream_name      = var.kinesis_stream_name
  shard_count      = var.kinesis_shard_count
  retention_period = var.kinesis_retention_period
  env              = var.env
}

# Firehose delivery stream
module "firehose" {
  source = "../../modules/firehose"

  stream_name        = var.firehose_stream_name
  kinesis_stream_arn = module.kinesis.stream_arn
  s3_bucket_arn      = module.s3.bucket_arn
  env                = var.env
}

# Lambda function
module "lambda" {
  source = "../../modules/lambda"

  function_name       = var.lambda_function_name
  handler             = var.lambda_handler
  runtime             = var.lambda_runtime
  kinesis_stream_name = module.kinesis.stream_name
  env                 = var.env
}

# API Gateway
module "api_gateway" {
  source = "../../modules/api-gateway"

  api_name             = var.api_gateway_name
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
  env                  = var.env
}

# =============================================================================
# WEBAPP HOSTING INFRASTRUCTURE
# =============================================================================

# S3 bucket for webapp hosting
module "s3_webapp" {
  source = "../../modules/s3-webapp"

  webapp_bucket_name = var.webapp_bucket_name
  cloudfront_oai_id  = module.cloudfront.cloudfront_oai_iam_arn
  env                = var.env
}

# CloudFront distribution for webapp
module "cloudfront" {
  source = "../../modules/cloudfront"

  s3_bucket_regional_domain_name = "${module.s3_webapp.bucket_id}.s3.${data.aws_region.current.name}.amazonaws.com"
  origin_id                      = "S3-${module.s3_webapp.bucket_id}"
  distribution_name              = var.cloudfront_distribution_name
  env                            = var.env
}

# Data source for current region
data "aws_region" "current" {}
