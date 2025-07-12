variable "env" {
  type        = string
  description = "Environment"
}

variable "region" {
  type        = string
  description = "Region"
}


variable "firehose_bucket_name" {
  type        = string
  description = "Bucket Name"
}

variable "kinesis_stream_name" {
  type        = string
  description = "Kinesis Stream Name"
}

variable "firehose_stream_name" {
  type        = string
  description = "Firehose Stream Name"
}

variable "lambda_function_name" {
  type        = string
  description = "Lambda Function Name"
}

variable "api_gateway_name" {
  type        = string
  description = "API Gateway Name"
}
