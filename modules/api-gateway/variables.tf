variable "api_name" {
  type        = string
  description = "Name of the API Gateway"
}

variable "env" {
  type        = string
  description = "Environment name"
}

# variable "lambda_invoke_arn" {
#   type        = string
#   description = "Invocation ARN of the Lambda function"
# }

# variable "lambda_function_name" {
#   type        = string
#   description = "Name of the Lambda function"
# }

variable "region" {
  type        = string
  description = "AWS region"
}

variable "kinesis_stream_arn" {
  type        = string
  description = "ARN of the Kinesis stream"
}

variable "kinesis_stream_name" {
  type        = string
  description = "Name of the Kinesis stream"
}
