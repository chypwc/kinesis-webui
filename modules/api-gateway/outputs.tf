output "api_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.api.id
}

output "api_invoke_url" {
  description = "Invoke URL for the API Gateway"
  value       = aws_api_gateway_stage.api.invoke_url
}
