# S3 Bucket for Firehose delivery
module "s3" {
  source = "../../modules/s3"

  bucket_name = var.firehose_bucket_name
  env         = var.env
}

# Kinesis Data Stream
module "kinesis" {
  source = "../../modules/kinesis"

  stream_name      = var.kinesis_stream_name
  env              = var.env
  shard_count      = 1
  retention_period = 24
}

# Firehose Delivery Stream (Kinesis → S3)
module "firehose" {
  source = "../../modules/firehose"

  stream_name        = var.firehose_stream_name
  kinesis_stream_arn = module.kinesis.stream_arn
  s3_bucket_arn      = module.s3.bucket_arn
  env                = var.env
  buffer_interval    = 60
  buffer_size        = 1
}

# Lambda Function
module "lambda" {
  source = "../../modules/lambda"

  function_name       = var.lambda_function_name
  env                 = var.env
  kinesis_stream_name = var.kinesis_stream_name
}

# API Gateway
module "api_gateway" {
  source = "../../modules/api-gateway"

  api_name             = var.api_gateway_name
  env                  = var.env
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
}
