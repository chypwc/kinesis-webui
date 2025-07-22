output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.firehose_bucket.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.firehose_bucket.arn
}

output "scripts_bucket_name" {
  description = "Name of the S3 bucket for Glue scripts"
  value       = aws_s3_bucket.glue_scripts.bucket
}

output "scripts_bucket_arn" {
  description = "ARN of the S3 bucket for Glue scripts"
  value       = aws_s3_bucket.glue_scripts.arn
}

output "output_bucket_name" {
  description = "Name of the S3 bucket for output data"
  value       = aws_s3_bucket.output_data.bucket
}

output "output_bucket_arn" {
  description = "ARN of the S3 bucket for output data"
  value       = aws_s3_bucket.output_data.arn
}
