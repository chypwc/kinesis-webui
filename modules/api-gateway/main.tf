# =============================================================================
# API Gateway Module
# =============================================================================
# This module creates an AWS API Gateway REST API that integrates directly with
# an AWS Kinesis Data Stream. It configures a /submit endpoint to receive POST
# requests and forwards them to Kinesis. It also includes a full CORS
# configuration to allow requests from a web application.
# =============================================================================

# =============================================================================
# CORE API GATEWAY RESOURCES
# =============================================================================
resource "aws_api_gateway_rest_api" "api" {
  name        = var.api_name
  description = "REST API for direct Kinesis integration"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = {
    Name        = var.api_name
    Environment = var.env
    Purpose     = "API Gateway for Kinesis integration"
  }
}

resource "aws_api_gateway_resource" "submit" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "submit"
}

# =============================================================================
# KINESIS INTEGRATION (POST METHOD)
# =============================================================================
resource "aws_api_gateway_method" "post_submit" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.submit.id
  http_method   = "POST"
  authorization = "NONE"
}

# =============================================================================
# CORS CONFIGURATION (OPTIONS METHOD)
# =============================================================================
resource "aws_api_gateway_method" "options_submit" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.submit.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_submit" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.submit.id
  http_method = aws_api_gateway_method.options_submit.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration" "kinesis" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.submit.id
  http_method             = aws_api_gateway_method.post_submit.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.region}:kinesis:action/PutRecord"
  credentials             = aws_iam_role.apigw_kinesis_role.arn
  request_templates = {
    "application/json" = <<EOF
{
  "StreamName": "${var.kinesis_stream_name}",
  "Data": "$util.base64Encode($input.body)",
  "PartitionKey": "$context.requestId"
}
EOF
  }
  passthrough_behavior = "NEVER"
  content_handling     = "CONVERT_TO_TEXT"
}

# =============================================================================
# API METHOD RESPONSES
# =============================================================================
resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.submit.id
  http_method = aws_api_gateway_method.options_submit.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.submit.id
  http_method = aws_api_gateway_method.options_submit.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code
  response_templates = {
    "application/json" = ""
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [aws_api_gateway_integration.options_submit]
}

resource "aws_api_gateway_method_response" "submit_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.submit.id
  http_method = aws_api_gateway_method.post_submit.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "submit_200" {
  rest_api_id       = aws_api_gateway_rest_api.api.id
  resource_id       = aws_api_gateway_resource.submit.id
  http_method       = aws_api_gateway_method.post_submit.http_method
  status_code       = aws_api_gateway_method_response.submit_200.status_code
  selection_pattern = ""
  response_templates = {
    "application/json" = "{}"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  depends_on = [aws_api_gateway_integration.kinesis]
}

# =============================================================================
# API DEPLOYMENT & STAGE
# =============================================================================
resource "aws_api_gateway_deployment" "api" {
  depends_on = [
    aws_api_gateway_integration.kinesis,
    aws_api_gateway_integration.options_submit
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.submit.path,
      aws_api_gateway_method.post_submit.http_method,
      aws_api_gateway_integration.kinesis.uri,
      aws_api_gateway_method.options_submit.http_method,
      aws_api_gateway_integration.options_submit.type,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# LOGGING & MONITORING
# =============================================================================
resource "aws_cloudwatch_log_group" "api_gw_logs" {
  name              = "/aws/api-gateway/${var.api_name}-${var.env}"
  retention_in_days = 14
}

# Only include this in one environment!
resource "aws_api_gateway_account" "api" {
  cloudwatch_role_arn = aws_iam_role.apigw_logs_role.arn
}

resource "aws_api_gateway_stage" "api" {
  depends_on = [aws_api_gateway_account.api]

  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.env
  deployment_id = aws_api_gateway_deployment.api.id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_logs.arn
    format          = "{\"requestId\":\"$context.requestId\",\"ip\":\"$context.identity.sourceIp\",\"caller\":\"$context.identity.caller\",\"user\":\"$context.identity.user\",\"requestTime\":\"$context.requestTime\",\"httpMethod\":\"$context.httpMethod\",\"resourcePath\":\"$context.resourcePath\",\"status\":\"$context.status\",\"protocol\":\"$context.protocol\",\"responseLength\":\"$context.responseLength\"}"
  }

  xray_tracing_enabled = false
  variables            = {}
  tags = {
    Name        = var.api_name
    Environment = var.env
  }
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.api.stage_name
  method_path = "*/*"
  settings {
    logging_level      = "INFO"
    metrics_enabled    = true
    data_trace_enabled = true
  }
}

# =============================================================================
# IAM ROLES & POLICIES
# =============================================================================
resource "aws_iam_role" "apigw_kinesis_role" {
  name = "apigw-kinesis-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "apigw_kinesis_policy" {
  name = "apigw-kinesis-policy-${var.env}"
  role = aws_iam_role.apigw_kinesis_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "kinesis:PutRecord"
      ]
      Resource = var.kinesis_stream_arn
    }]
  })
}

resource "aws_iam_role" "apigw_logs_role" {
  name = "apigw-logs-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "apigateway.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apigw_logs_policy" {
  role       = aws_iam_role.apigw_logs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}
