output "firehose_stream_name" {
  description = "The name of the Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.api_firehose.name
}

output "firehose_stream_arn" {
  description = "The ARN of the Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.api_firehose.arn
}

output "firehose_role_arn" {
  description = "The ARN of the Firehose IAM role"
  value       = aws_iam_role.firehose_role.arn
}

output "firehose_error_log_group_name" {
  description = "The name of the Firehose error log group (created by monitoring module)"
  value       = var.enable_cloudwatch_logging ? "/aws/kinesis-firehose/${var.stream_name}" : null
}
