variable "lambda_function_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "firehose_stream_name" {
  type        = string
  description = "Name of the Firehose delivery stream"
}

variable "kinesis_stream_name" {
  type        = string
  description = "Name of the Kinesis Data Stream"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "alarm_actions" {
  type        = list(string)
  description = "List of ARNs for CloudWatch alarm actions (e.g., SNS topics)"
  default     = []
} 
