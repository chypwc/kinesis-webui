# =============================================================================
# OUTPUTS FOR GLUE JOB MODULE
# =============================================================================

output "job_name" {
  description = "Name of the Glue job"
  value       = aws_glue_job.feature_engineering.name
}

output "job_arn" {
  description = "ARN of the Glue job"
  value       = aws_glue_job.feature_engineering.arn
}

output "job_role_arn" {
  description = "ARN of the IAM role used by the Glue job"
  value       = aws_iam_role.glue_job_role.arn
}

