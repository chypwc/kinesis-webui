# =============================================================================
# VARIABLES FOR DYNAMODB MODULE
# =============================================================================

variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "products_table_name" {
  description = "Name of the products table"
  type        = string
  default     = "products"
}

variable "user_product_features_table_name" {
  description = "Name of the user_product_features table"
  type        = string
  default     = "user_product_features"
}

variable "product_features_table_name" {
  description = "Name of the product_features table"
  type        = string
  default     = "product_features"
}

variable "user_features_table_name" {
  description = "Name of the user_features table"
  type        = string
  default     = "user_features"
}

variable "billing_mode" {
  description = "DynamoDB billing mode"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

