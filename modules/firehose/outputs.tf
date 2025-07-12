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
