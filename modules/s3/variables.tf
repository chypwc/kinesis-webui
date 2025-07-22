variable "firehose_bucket_name" {
  type        = string
  description = "Name of the S3 bucket for Firehose delivery"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "output_bucket_name" {
  description = "S3 bucket for output data"
  type        = string
}

variable "scripts_bucket_name" {
  description = "Name of the S3 bucket for Glue scripts"
  type        = string
}
