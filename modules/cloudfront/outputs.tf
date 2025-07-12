output "distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.webapp_distribution.id
}

output "distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.webapp_distribution.domain_name
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.webapp_distribution.arn
}

output "webapp_url" {
  description = "URL of the deployed webapp"
  value       = "https://${aws_cloudfront_distribution.webapp_distribution.domain_name}"
} 
