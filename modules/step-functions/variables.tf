variable "input_bucket" {
  description = "The S3 bucket for input data"
  type        = string
}

variable "input_key" {
  description = "The S3 key for input data"
  type        = string
}

variable "glue_job_name" {
  description = "The name of the Glue job"
  type        = string
}

variable "training_job_name" {
  description = "The name of the SageMaker training job"
  type        = string
}


variable "endpoint_name" {
  description = "The name of the SageMaker endpoint"
  type        = string
}

variable "endpoint_config_name" {
  description = "The name of the SageMaker endpoint configuration"
  type        = string
}

variable "env" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

# variable "sagemaker_execution_role_arn" {
#   description = "The ARN of the SageMaker role"
#   type        = string
# }

variable "private_subnet_ids" {
  description = "The IDs of the private subnets"
  type        = list(string)
}

variable "glue_sagemaker_lambda_security_group_id" {
  description = "The ID of the glue_sagemaker_lambda security group"
  type        = string
}
