# =============================================================================
# S3 Webapp Hosting Module
# =============================================================================
# This module creates an S3 bucket configured for static website hosting
# with public access for the webapp deployment.
# 
# Architecture Role: Static Website Hosting
# Purpose: Host the webapp files for public access
# =============================================================================

# S3 bucket for webapp hosting
resource "aws_s3_bucket" "webapp_bucket" {
  bucket        = var.webapp_bucket_name
  force_destroy = true

  tags = {
    Name        = var.webapp_bucket_name
    Environment = var.env
    Purpose     = "Webapp hosting"
  }
}

# Enable website hosting
resource "aws_s3_bucket_website_configuration" "webapp_bucket" {
  bucket = aws_s3_bucket.webapp_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Configure public access for website hosting
resource "aws_s3_bucket_public_access_block" "webapp_bucket" {
  bucket = aws_s3_bucket.webapp_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy to allow public read access
resource "aws_s3_bucket_policy" "webapp_bucket" {
  bucket = aws_s3_bucket.webapp_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.webapp_bucket.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.webapp_bucket]
}
