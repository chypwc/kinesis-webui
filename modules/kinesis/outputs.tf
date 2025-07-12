output "stream_name" {
  description = "The name of the Kinesis stream"
  value       = aws_kinesis_stream.api_stream.name
}

output "stream_arn" {
  description = "The ARN of the Kinesis stream"
  value       = aws_kinesis_stream.api_stream.arn
}
