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
# resource "null_resource" "build_lambda_package" {
#   provisioner "local-exec" {
#     command = <<EOT
#       mkdir -p ${path.module}/package
#       pip install joblib boto3 scikit-learn numpy pandas -t ${path.module}/package
#       cp ${path.module}/lambda_function.py ${path.module}/package/
#       cd ${path.module}/package && zip -r ../lambda_function_payload.zip .
#     EOT
#   }
# }

resource "aws_s3_object" "lambda_zip" {
  bucket = var.lambda_bucket
  key    = "lambda/lambda_function_payload.zip"
  source = "${path.module}/lambda_function_payload.zip"
  etag   = filemd5("${path.module}/lambda_function_payload.zip")
  # depends_on = [null_resource.build_lambda_package]
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

# IAM policy for SageMaker and DynamoDB access
resource "aws_iam_policy" "lambda_sagemaker_dynamodb_policy" {
  name        = "lambda-sagemaker-dynamodb-policy"
  description = "Allow Lambda to invoke SageMaker endpoints and access DynamoDB tables"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sagemaker:InvokeEndpoint"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:BatchGetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:DescribeTable"
        ],
        Resource = [
          "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/user_product_features",
          "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/product_features",
          "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/user_features",
          "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/products"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_vpc" {
  name = "lambda-vpc-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_sagemaker_dynamodb_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_sagemaker_dynamodb_policy.arn
}

# IAM policy for S3 access to scaler.pkl
resource "aws_iam_policy" "lambda_s3_getobject_policy" {
  name        = "lambda-s3-getobject-policy"
  description = "Allow Lambda to get scaler.pkl from S3 bucket for inference."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = "arn:aws:s3:::${var.lambda_bucket}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_getobject_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_getobject_policy.arn
}

# Add a data source for the AWS SDK Pandas layer


# Lambda function configuration
# This creates the actual serverless function that processes API requests
resource "aws_lambda_function" "api_lambda" {
  s3_bucket        = var.lambda_bucket
  s3_key           = "lambda/lambda_function_payload.zip"
  function_name    = var.function_name
  role             = aws_iam_role.lambda_role.arn                                   # IAM role for permissions
  handler          = var.handler                                                    # Function entry point
  runtime          = var.runtime                                                    # Python runtime
  source_code_hash = filebase64sha256("${path.module}/lambda_function_payload.zip") # For updates
  timeout          = 120                                                            # Function timeout in seconds
  architectures    = ["${var.lambda_architecture}"]                                 # x86_64 on GitHub Actions

  # layers = [
  #   "arn:aws:lambda:${data.aws_region.current.name}:336392948345:layer:AWSSDKPandas-Python312:18"
  # ]

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.glue_sagemaker_lambda_security_group_id]
  }

  # Environment variables passed to the Lambda function
  # These are accessible within the function code
  environment {
    variables = {
      KINESIS_STREAM = var.kinesis_stream_name # Stream name for data delivery
      ENDPOINT_NAME  = var.endpoint_name
      # SCALER_BUCKET  = var.scaler_bucket
      # SCALER_KEY     = var.scaler_key
    }
  }

  tags = {
    Name        = var.function_name
    Environment = var.env
    Purpose     = "API Gateway integration"
  }

  depends_on = [aws_s3_object.lambda_zip]
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
