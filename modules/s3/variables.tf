variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket for Firehose delivery"
}

variable "env" {
  type        = string
  description = "Environment name"
}
