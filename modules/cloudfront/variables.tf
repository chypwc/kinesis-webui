variable "s3_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  type        = string
}

variable "origin_id" {
  description = "Origin ID for the CloudFront distribution"
  type        = string
}

variable "distribution_name" {
  description = "Name of the CloudFront distribution"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
} 
