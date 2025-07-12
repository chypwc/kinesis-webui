output "bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.webapp_bucket.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.webapp_bucket.arn
}

output "website_endpoint" {
  description = "S3 website endpoint"
  value       = aws_s3_bucket_website_configuration.webapp_bucket.website_endpoint
}

output "website_domain" {
  description = "S3 website domain"
  value       = aws_s3_bucket_website_configuration.webapp_bucket.website_domain
} 
