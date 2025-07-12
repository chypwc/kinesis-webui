variable "function_name" {
  type        = string
  description = "Name of the Lambda function"
  default     = "api-lambda-function"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "kinesis_stream_name" {
  type        = string
  description = "Name of the Kinesis stream to send data to"
}

variable "runtime" {
  type        = string
  description = "Lambda runtime"
  default     = "python3.12"
}

variable "handler" {
  type        = string
  description = "Lambda handler"
  default     = "lambda_function.lambda_handler"
}
