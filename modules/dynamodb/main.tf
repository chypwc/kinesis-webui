# =============================================================================
# DYNAMODB MODULE - TABLES FOR FEATURE ENGINEERING
# =============================================================================

# Products table
resource "aws_dynamodb_table" "products" {
  name         = var.products_table_name
  billing_mode = var.billing_mode
  hash_key     = "product_id"

  attribute {
    name = "product_id"
    type = "N"
  }

  tags = merge(var.tags, {
    Name        = "${var.products_table_name}"
    Environment = var.env
  })
}

# User product features table
resource "aws_dynamodb_table" "user_product_features" {
  name         = var.user_product_features_table_name
  billing_mode = var.billing_mode
  hash_key     = "user_id"
  range_key    = "product_id"

  attribute {
    name = "user_id"
    type = "N"
  }

  attribute {
    name = "product_id"
    type = "N"
  }

  tags = merge(var.tags, {
    Name        = "${var.user_product_features_table_name}"
    Environment = var.env
  })
}

# User product features table
resource "aws_dynamodb_table" "product_features" {
  name         = var.product_features_table_name
  billing_mode = var.billing_mode
  hash_key     = "product_id"
  

  attribute {
    name = "product_id"
    type = "N"
  }

  tags = merge(var.tags, {
    Name        = "${var.user_product_features_table_name}"
    Environment = var.env
  })
}

resource "aws_dynamodb_table" "user_features" {
  name         = var.user_features_table_name
  billing_mode = var.billing_mode
  hash_key     = "user_id"

  attribute {
    name = "user_id"
    type = "N"
  }
}