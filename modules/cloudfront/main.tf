# =============================================================================
# CloudFront Distribution Module
# =============================================================================
# This module creates a CloudFront distribution for serving the webapp
# from S3 with global CDN, HTTPS, and caching capabilities.
# 
# Architecture Role: Content Delivery Network (CDN)
# Purpose: Provide fast, secure global access to the webapp
# =============================================================================

# CloudFront Origin Access Identity for S3 access
resource "aws_cloudfront_origin_access_identity" "webapp_oai" {
  comment = "OAI for accessing the S3 bucket via CloudFront"
}

# CloudFront distribution for webapp
resource "aws_cloudfront_distribution" "webapp_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100" # Use only North America and Europe (budget friendly)

  # Origin configuration (S3 bucket)
  origin {
    domain_name = var.s3_bucket_regional_domain_name
    origin_id   = var.origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.webapp_oai.cloudfront_access_identity_path
    }
  }

  # Default cache behavior
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.origin_id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Custom error response for SPA routing
  custom_error_response {
    error_code         = 404
    response_code      = "200"
    response_page_path = "/index.html"
  }

  # Custom error response for 403 errors
  custom_error_response {
    error_code         = 403
    response_code      = "200"
    response_page_path = "/index.html"
  }

  # Viewer certificate (CloudFront default certificate)
  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  # Restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name        = var.distribution_name
    Environment = var.env
    Purpose     = "Webapp CDN"
  }
}
