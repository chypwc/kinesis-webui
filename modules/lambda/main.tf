# =============================================================================
# Lambda Function Module for API Gateway Integration
# =============================================================================
# This module creates a Lambda function that processes API requests and
# sends data to Kinesis. It serves as the compute layer between API Gateway
# and the streaming pipeline.
# 
# Architecture Role: Serverless Compute Layer
# Data Flow: API Gateway → Lambda → Kinesis Stream
# =============================================================================

# Create deployment package from Python source code
# This zips the Lambda function code for deployment
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"          # Source Python file
  output_path = "${path.module}/lambda_function_payload.zip" # Output ZIP file
}

# IAM role for Lambda function execution
# Lambda needs this role to assume permissions for CloudWatch logging and Kinesis access
resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-lambda-role"

  # Trust policy allowing Lambda service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.function_name}-lambda-role"
    Environment = var.env
  }
}

# Attach basic execution role policy for CloudWatch logging
# This allows Lambda to write logs to CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM policy granting Lambda permissions to write to Kinesis
# This allows the Lambda function to send data to the Kinesis stream
resource "aws_iam_role_policy" "lambda_kinesis" {
  name = "${var.function_name}-kinesis-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:PutRecord", # Send single record to stream
          "kinesis:PutRecords" # Send multiple records to stream (batch)
        ]
        Resource = "*" # Allow access to any Kinesis stream
      }
    ]
  })
}

# IAM policy for enhanced CloudWatch logging
# This allows Lambda to create and write to CloudWatch Logs for better monitoring
resource "aws_iam_role_policy" "lambda_logging" {
  name = "${var.function_name}-logging-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:*:*:log-group:/aws/lambda/${var.function_name}",
          "arn:aws:logs:*:*:log-group:/aws/lambda/${var.function_name}:*"
        ]
      }
    ]
  })
}

# Lambda function configuration
# This creates the actual serverless function that processes API requests
resource "aws_lambda_function" "api_lambda" {
  filename         = data.archive_file.lambda_zip.output_path # Deployment package
  function_name    = var.function_name
  role             = aws_iam_role.lambda_role.arn                     # IAM role for permissions
  handler          = var.handler                                      # Function entry point
  runtime          = var.runtime                                      # Python runtime
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256 # For updates
  timeout          = 30                                               # Function timeout in seconds

  # Environment variables passed to the Lambda function
  # These are accessible within the function code
  environment {
    variables = {
      KINESIS_STREAM = var.kinesis_stream_name # Stream name for data delivery
    }
  }

  tags = {
    Name        = var.function_name
    Environment = var.env
    Purpose     = "API Gateway integration"
  }
}

# Lambda permission for API Gateway invocation
# This allows API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_lambda.function_name
  principal     = "apigateway.amazonaws.com" # API Gateway service principal
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*/*/*"
}

# Data sources for current AWS account and region information
# These are used to construct the source ARN for Lambda permissions
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
