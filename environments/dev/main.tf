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

  firehose_bucket_name = var.firehose_bucket_name
  output_bucket_name   = "imba-chien-data-features-${var.env}"
  scripts_bucket_name  = var.scripts_bucket_name
  env                  = var.env
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
  lambda_bucket       = module.s3.output_bucket_name
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

# =============================================================================
# FEATURE ENGINEERING INFRASTRUCTURE
# =============================================================================

# DynamoDB tables for feature engineering
module "dynamodb" {
  source = "../../modules/dynamodb"

  env = var.env

  tags = {
    Project     = "kinesis-pipeline"
    Environment = var.env
  }
}

# Glue job for feature engineering
module "glue_job" {
  source = "../../modules/glue-job"

  job_name                        = "feature-engineering"
  job_description                 = "Feature engineering job for Instacart data analysis"
  database_name                   = "imba"
  script_location                 = "s3://${module.s3.scripts_bucket_name}/features.py"
  scripts_bucket_name             = module.s3.scripts_bucket_name
  glue_script_bucket_arn          = module.s3.scripts_bucket_arn
  output_bucket_arn               = module.s3.output_bucket_arn
  output_bucket_name              = module.s3.output_bucket_name
  data_bucket_arn                 = "arn:aws:s3:::imba-chien"
  products_table_arn              = module.dynamodb.products_table_arn
  user_product_features_table_arn = module.dynamodb.user_product_features_table_arn
  product_features_table_arn      = module.dynamodb.product_features_table_arn
  user_features_table_arn         = module.dynamodb.user_features_table_arn
  max_retries                     = 0
  number_of_workers               = 4
  env                             = var.env

}

module "sagemaker_notebook" {
  source = "../../modules/sagemaker/notebook"
  notebook_bucket = module.s3.output_bucket_name
}

# SageMaker training job
module "sagemaker_endpoint" {
  source = "../../modules/sagemaker/endpoint"
  model_bucket = module.s3.output_bucket_name
}

# Data source for current region
data "aws_region" "current" {}
