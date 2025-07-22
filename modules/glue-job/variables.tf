# =============================================================================
# VARIABLES FOR GLUE JOB MODULE
# =============================================================================

variable "job_name" {
  description = "Name of the Glue job"
  type        = string
  default     = "feature-engineering-job"
}

variable "job_description" {
  description = "Description of the Glue job"
  type        = string
  default     = "Feature engineering job for Instacart data analysis"
}

variable "glue_version" {
  description = "Glue version to use"
  type        = string
  default     = "5.0"
}

variable "worker_type" {
  description = "Type of worker to use"
  type        = string
  default     = "G.1X"
}

variable "number_of_workers" {
  description = "Number of workers for the job"
  type        = number
  default     = 2
}

variable "timeout" {
  description = "Job timeout in minutes"
  type        = number
  default     = 60
}

variable "max_retries" {
  description = "Maximum number of retries"
  type        = number
  default     = 0
}


variable "database_name" {
  description = "Name of the Glue database"
  type        = string
  default     = "imba"
}

variable "script_location" {
  description = "S3 location of the Glue script"
  type        = string
  default     = "s3://imba-chien/scripts/features.py"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "glue_script_bucket_arn" {
  description = "ARN of the Glue script"
  type        = string
}

variable "output_bucket_arn" {
  description = "ARN of the output bucket"
  type        = string
}

variable "scripts_bucket_name" {
  description = "Name of the scripts bucket"
  type        = string
}

variable "output_bucket_name" {
  description = "Name of the output bucket"
  type        = string
}

variable "data_bucket_arn" {
  description = "ARN of the data bucket containing CSV files"
  type        = string
}

variable "products_table_arn" {
  description = "ARN of the products DynamoDB table"
  type        = string
}

variable "user_product_features_table_arn" {
  description = "ARN of the user_product_features DynamoDB table"
  type        = string
}

variable "product_features_table_arn" {
  description = "ARN of the product_features DynamoDB table"
  type        = string
}

variable "user_features_table_arn" {
  description = "ARN of the user_features DynamoDB table"
  type        = string
}