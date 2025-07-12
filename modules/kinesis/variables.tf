variable "stream_name" {
  type        = string
  description = "Name of the Kinesis Data Stream"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "shard_count" {
  type        = number
  description = "Number of shards for the Kinesis stream"
  default     = 1
}

variable "retention_period" {
  type        = number
  description = "Data retention period in hours"
  default     = 24
}
