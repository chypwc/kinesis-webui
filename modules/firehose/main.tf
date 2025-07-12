# IAM role for Firehose
resource "aws_iam_role" "firehose_role" {
  name = "${var.stream_name}-firehose-role"

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

# IAM policy for Firehose to read from Kinesis and write to S3
resource "aws_iam_role_policy" "firehose_policy" {
  name = "${var.stream_name}-firehose-policy"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords"
        ]
        Resource = var.kinesis_stream_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Firehose delivery stream
resource "aws_kinesis_firehose_delivery_stream" "api_firehose" {
  name        = var.stream_name
  destination = "extended_s3"

  kinesis_source_configuration {
    role_arn           = aws_iam_role.firehose_role.arn
    kinesis_stream_arn = var.kinesis_stream_arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = var.s3_bucket_arn

    # Uncompressed format as specified in pipeline requirements
    compression_format = "UNCOMPRESSED"
  }

  tags = {
    Name        = var.stream_name
    Environment = var.env
    Purpose     = "Kinesis to S3 delivery"
  }
}
