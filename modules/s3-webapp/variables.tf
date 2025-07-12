variable "webapp_bucket_name" {
  description = "Name of the S3 bucket for webapp hosting"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "cloudfront_oai_id" {
  description = "CloudFront Origin Access Identity ID"
  type        = string
}
