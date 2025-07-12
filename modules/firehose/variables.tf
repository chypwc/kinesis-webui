variable "stream_name" {
  type        = string
  description = "Name of the Firehose delivery stream"
}

variable "kinesis_stream_arn" {
  type        = string
  description = "ARN of the source Kinesis stream"
}

variable "s3_bucket_arn" {
  type        = string
  description = "ARN of the destination S3 bucket"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "buffer_interval" {
  type        = number
  description = "Buffer interval in seconds"
  default     = 60
}

variable "buffer_size" {
  type        = number
  description = "Buffer size in MB"
  default     = 1
}
