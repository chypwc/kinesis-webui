# =============================================================================
# Kinesis Firehose Delivery Stream Module
# =============================================================================
# This module creates a Firehose delivery stream that continuously reads
# data from Kinesis and delivers it to S3. Firehose handles batching,
# buffering, and delivery automatically.
# 
# Architecture Role: Data Delivery Service
# Data Flow: Kinesis Stream → Firehose → S3 Bucket
# =============================================================================

# IAM role for Firehose service
# Firehose needs this role to assume permissions for reading from Kinesis
# and writing to S3
resource "aws_iam_role" "firehose_role" {
  name = "${var.stream_name}-firehose-role"

  # Trust policy allowing Firehose service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.stream_name}-firehose-role"
    Environment = var.env
  }
}

# IAM policy granting Firehose permissions to read from Kinesis and write to S3
# This policy allows Firehose to:
# - Read data from the Kinesis stream
# - Write data to the S3 bucket
resource "aws_iam_role_policy" "firehose_policy" {
  name = "${var.stream_name}-firehose-policy"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Permissions to read from Kinesis stream
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeStream",   # Get stream metadata
          "kinesis:GetShardIterator", # Get iterator for reading
          "kinesis:GetRecords"        # Read records from stream
        ]
        Resource = var.kinesis_stream_arn
      },
      # Permissions to write to S3 bucket
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",       # Cancel failed uploads
          "s3:GetBucketLocation",          # Get bucket region
          "s3:GetObject",                  # Read objects (for error handling)
          "s3:ListBucket",                 # List bucket contents
          "s3:ListBucketMultipartUploads", # List multipart uploads
          "s3:PutObject"                   # Write objects to bucket
        ]
        Resource = [
          var.s3_bucket_arn,       # Bucket itself
          "${var.s3_bucket_arn}/*" # All objects in bucket
        ]
      }
    ]
  })
}

# Firehose delivery stream configuration
# This stream continuously reads from Kinesis and delivers to S3
resource "aws_kinesis_firehose_delivery_stream" "api_firehose" {
  name        = var.stream_name
  destination = "extended_s3" # S3 as the delivery destination

  # Source configuration: Read from Kinesis stream
  kinesis_source_configuration {
    role_arn           = aws_iam_role.firehose_role.arn # Role for reading from Kinesis
    kinesis_stream_arn = var.kinesis_stream_arn         # Source Kinesis stream
  }

  # Destination configuration: Write to S3
  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn # Role for writing to S3
    bucket_arn = var.s3_bucket_arn              # Destination S3 bucket

    # Data format configuration
    # Using uncompressed format as specified in pipeline requirements
    # This ensures data is human-readable and easily processable
    compression_format = "UNCOMPRESSED"
  }

  tags = {
    Name        = var.stream_name
    Environment = var.env
    Purpose     = "Kinesis to S3 delivery"
  }
}
