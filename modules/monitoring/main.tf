# =============================================================================
# Monitoring Module for Kinesis Pipeline
# =============================================================================
# This module creates CloudWatch alarms and logging configurations
# for monitoring the Kinesis data pipeline components.
# 
# Architecture Role: Monitoring and Alerting
# Components: CloudWatch Alarms, Log Groups, Metrics
# =============================================================================

# CloudWatch Log Group for Lambda function logs
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14

  tags = {
    Name        = "${var.lambda_function_name}-logs"
    Environment = var.env
    Purpose     = "Lambda function monitoring"
  }
}

# CloudWatch Log Group for Firehose delivery stream logs
resource "aws_cloudwatch_log_group" "firehose_logs" {
  name              = "/aws/kinesis-firehose/${var.firehose_stream_name}"
  retention_in_days = 14

  tags = {
    Name        = "${var.firehose_stream_name}-logs"
    Environment = var.env
    Purpose     = "Firehose delivery monitoring"
  }
}

# CloudWatch Alarm for Lambda errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.lambda_function_name}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Lambda function error rate"
  alarm_actions       = var.alarm_actions

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = {
    Name        = "${var.lambda_function_name}-errors"
    Environment = var.env
    Purpose     = "Lambda error monitoring"
  }
}

# CloudWatch Alarm for Lambda duration
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${var.lambda_function_name}-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "10000" # 10 seconds
  alarm_description   = "Lambda function execution duration"
  alarm_actions       = var.alarm_actions

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = {
    Name        = "${var.lambda_function_name}-duration"
    Environment = var.env
    Purpose     = "Lambda duration monitoring"
  }
}

# CloudWatch Alarm for Kinesis stream errors
resource "aws_cloudwatch_metric_alarm" "kinesis_errors" {
  alarm_name          = "${var.kinesis_stream_name}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "GetRecords.IteratorAgeMilliseconds"
  namespace           = "AWS/Kinesis"
  period              = "300"
  statistic           = "Average"
  threshold           = "60000" # 60 seconds
  alarm_description   = "Kinesis stream iterator age"
  alarm_actions       = var.alarm_actions

  dimensions = {
    StreamName = var.kinesis_stream_name
  }

  tags = {
    Name        = "${var.kinesis_stream_name}-errors"
    Environment = var.env
    Purpose     = "Kinesis stream monitoring"
  }
}

# CloudWatch Alarm for Firehose delivery errors
resource "aws_cloudwatch_metric_alarm" "firehose_errors" {
  alarm_name          = "${var.firehose_stream_name}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DeliveryToS3.Records"
  namespace           = "AWS/Firehose"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Firehose delivery to S3"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DeliveryStreamName = var.firehose_stream_name
  }

  tags = {
    Name        = "${var.firehose_stream_name}-errors"
    Environment = var.env
    Purpose     = "Firehose delivery monitoring"
  }
} 
