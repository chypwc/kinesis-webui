output "lambda_log_group_name" {
  description = "Name of the Lambda CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "firehose_log_group_name" {
  description = "Name of the Firehose CloudWatch log group"
  value       = aws_cloudwatch_log_group.firehose_logs.name
}

output "lambda_errors_alarm_arn" {
  description = "ARN of the Lambda errors CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.lambda_errors.arn
}

output "lambda_duration_alarm_arn" {
  description = "ARN of the Lambda duration CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.lambda_duration.arn
}

output "kinesis_errors_alarm_arn" {
  description = "ARN of the Kinesis errors CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.kinesis_errors.arn
}

output "firehose_errors_alarm_arn" {
  description = "ARN of the Firehose errors CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.firehose_errors.arn
} 
