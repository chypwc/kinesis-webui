# =============================================================================
# S3 Bucket Module for Firehose Data Delivery
# =============================================================================
# This module creates an S3 bucket that serves as the final destination for
# the data pipeline. Firehose will deliver streaming data from Kinesis to
# this bucket in uncompressed format.
# 
# Architecture Role: Data Lake Storage (Final Destination)
# Data Flow: Kinesis → Firehose → S3 Bucket
# =============================================================================

# Main S3 bucket for storing Firehose-delivered data
# This bucket will receive streaming data from Kinesis via Firehose
resource "aws_s3_bucket" "firehose_bucket" {
  bucket        = var.bucket_name
  force_destroy = true # Allows Terraform to delete bucket even if not empty

  tags = {
    Name        = var.bucket_name
    Environment = var.env
    Purpose     = "Firehose delivery bucket"
  }
}

# Security: Block all public access to the S3 bucket
# This is a critical security measure to prevent unauthorized access to data
resource "aws_s3_bucket_public_access_block" "firehose_bucket" {
  bucket = aws_s3_bucket.firehose_bucket.id

  block_public_acls       = true # Block public ACLs
  block_public_policy     = true # Block public bucket policies
  ignore_public_acls      = true # Ignore public ACLs
  restrict_public_buckets = true # Restrict public bucket access
}

# Enable versioning for data protection and compliance
# Allows recovery of previous versions of files if needed
resource "aws_s3_bucket_versioning" "firehose_bucket" {
  bucket = aws_s3_bucket.firehose_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
