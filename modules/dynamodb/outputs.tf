# =============================================================================
# OUTPUTS FOR DYNAMODB MODULE
# =============================================================================

output "products_table_name" {
  description = "Name of the products DynamoDB table"
  value       = aws_dynamodb_table.products.name
}

output "products_table_arn" {
  description = "ARN of the products DynamoDB table"
  value       = aws_dynamodb_table.products.arn
}

output "products_table_id" {
  description = "ID of the products DynamoDB table"
  value       = aws_dynamodb_table.products.id
}

output "user_product_features_table_name" {
  description = "Name of the user_product_features DynamoDB table"
  value       = aws_dynamodb_table.user_product_features.name
}

output "user_product_features_table_arn" {
  description = "ARN of the user_product_features DynamoDB table"
  value       = aws_dynamodb_table.user_product_features.arn
}

output "user_product_features_table_id" {
  description = "ID of the user_product_features DynamoDB table"
  value       = aws_dynamodb_table.user_product_features.id
}

output "product_features_table_name" {
  description = "Name of the product_features DynamoDB table"
  value       = aws_dynamodb_table.product_features.name
}

output "product_features_table_arn" {
  description = "ARN of the product_features DynamoDB table"
  value       = aws_dynamodb_table.product_features.arn
}

output "user_features_table_name" {
  description = "Name of the user_features DynamoDB table"
  value       = aws_dynamodb_table.user_features.name
}

output "user_features_table_arn" {
  description = "ARN of the user_features DynamoDB table"
  value       = aws_dynamodb_table.user_features.arn
}