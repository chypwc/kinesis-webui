resource "aws_s3_bucket" "firehose_bucket" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name        = var.bucket_name
    Environment = var.env
    Purpose     = "Firehose delivery bucket"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "firehose_bucket" {
  bucket = aws_s3_bucket.firehose_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket versioning
resource "aws_s3_bucket_versioning" "firehose_bucket" {
  bucket = aws_s3_bucket.firehose_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
