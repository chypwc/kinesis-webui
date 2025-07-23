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

variable "endpoint_name" {
  type        = string
  description = "Name of the SageMaker endpoint"
  default     = "xgboost-endpoint"
}


variable "lambda_bucket" {
  type        = string
  description = "Name of the S3 bucket for Lambda function"
  default     = "imba-chien-data-features-dev"
}

variable "scaler_bucket" {
  type        = string
  description = "Name of the S3 bucket for scaler.pkl"
  default     = "imba-chien-data-features-dev"
}

variable "scaler_key" {
  type        = string
  description = "Key of the scaler.pkl in S3"
  default     = "scale_models/scaler.pkl"
}

variable "lambda_architecture" {
  type        = string
  description = "Lambda architecture"
  default     = "arm64"
}

variable "private_subnet_ids" {
  type        = string
  description = "ID of the VPC"
}

variable "glue_sagemaker_lambda_security_group_id" {
  type        = string
  description = "ID of the glue_sagemaker_lambda security group"
}
