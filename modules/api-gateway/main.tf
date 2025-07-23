# =============================================================================
# API Gateway Module for HTTP API
# =============================================================================
# This module creates an HTTP API Gateway that serves as the entry point
# for the data pipeline. It receives HTTP requests and routes them to Lambda
# for processing.
# 
# Architecture Role: API Entry Point
# Data Flow: HTTP Client → API Gateway → Lambda
# =============================================================================

# HTTP API Gateway for receiving web requests
# This creates a modern HTTP API (v2) that's more cost-effective than REST API
resource "aws_apigatewayv2_api" "api" {
  name          = var.api_name
  protocol_type = "HTTP" # HTTP API type (vs REST API)

  # CORS configuration for web app requests
  cors_configuration {
    allow_credentials = false
    allow_headers     = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods     = ["*"]
    allow_origins     = ["*"]
    expose_headers    = ["date", "keep-alive"]
    max_age           = 86400
  }

  tags = {
    Name        = var.api_name
    Environment = var.env
    Purpose     = "API Gateway for Lambda integration"
  }
}

# API Gateway stage configuration
# Stages represent deployment environments (dev, prod, etc.)
# Auto-deploy enables automatic deployment of API changes
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default" # Default stage name
  auto_deploy = true       # Automatically deploy API changes

  tags = {
    Name        = "${var.api_name}-default-stage"
    Environment = var.env
  }
}

# Lambda integration configuration
# This connects the API Gateway to the Lambda function
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"           # Lambda proxy integration
  integration_uri        = var.lambda_invoke_arn # Lambda function ARN
  integration_method     = "POST"                # HTTP method for Lambda invocation
  payload_format_version = "2.0"                 # API Gateway v2 payload format
}

# POST /submit route configuration
# This route handles POST requests to /submit endpoint
# All requests to this route are forwarded to the Lambda function
resource "aws_apigatewayv2_route" "submit" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /submit"                                           # HTTP method and path
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}" # Lambda integration
}

# Default route for unmatched requests (optional)
# This route handles any requests that don't match other routes
# Useful for testing and providing fallback behavior
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "$default"                                               # Catch-all route
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}" # Lambda integration
}

# Lambda permission for API Gateway invocation
# This allows API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
