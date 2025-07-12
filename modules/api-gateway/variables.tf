variable "api_name" {
  type        = string
  description = "Name of the API Gateway"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "lambda_invoke_arn" {
  type        = string
  description = "Invocation ARN of the Lambda function"
}

variable "lambda_function_name" {
  type        = string
  description = "Name of the Lambda function"
}
