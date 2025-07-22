variable "model_bucket" {
  type        = string
  description = "Name of the S3 bucket for model data"
  default     = "imba-chien-data-features-dev"
}

variable "training_job_name" {
  type        = string
  description = "Name of the model"
  default     = "xgboost-training-job"
}

variable "endpoint_config_name" {
  type        = string
  description = "Name of the endpoint configuration"
}