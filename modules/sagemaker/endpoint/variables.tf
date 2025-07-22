variable "model_bucket" {
  type        = string
  description = "Name of the S3 bucket for model data"
  default     = "imba-chien-data-features-dev"
}

variable "training_job_name" {
  type        = string
  description = "Name of the model"
  default     = "sagemaker-xgboost-2025-07-21-15-58-52-772"
}