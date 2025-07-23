# =============================================================================
# GLUE JOB MODULE - FEATURE ENGINEERING
# =============================================================================

# Data source for current region
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}



# =============================================================================
# IAM ROLE FOR GLUE JOB
# =============================================================================

resource "aws_iam_role" "glue_job_role" {
  name = "glue-job-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "glue-job-role-${var.env}"
    Environment = var.env
  }
}

# Attach AWS managed policy for Glue service role
resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_job_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Custom policy for S3 access
resource "aws_iam_role_policy" "glue_s3_policy" {
  name = "glue-s3-policy-${var.env}"
  role = aws_iam_role.glue_job_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.glue_script_bucket_arn,
          "${var.glue_script_bucket_arn}/*",
          var.output_bucket_arn,
          "${var.output_bucket_arn}/*",
          var.data_bucket_arn,
          "${var.data_bucket_arn}/*",
          "arn:aws:s3:::source-bucket-chien",
          "arn:aws:s3:::source-bucket-chien/*"
        ]
      }
    ]
  })
}

# Custom policy for DynamoDB access
resource "aws_iam_role_policy" "glue_dynamodb_policy" {
  name = "glue-dynamodb-policy-${var.env}"
  role = aws_iam_role.glue_job_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:DescribeTable",
          "dynamodb:ListTables",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:DescribeContinuousBackups"
        ]
        Resource = [
          var.products_table_arn,
          var.user_product_features_table_arn,
          var.product_features_table_arn,
          var.user_features_table_arn
        ]
      }
    ]
  })
}

# Custom policy for Glue Catalog access
resource "aws_iam_role_policy" "glue_catalog_policy" {
  name = "glue-catalog-policy-${var.env}"
  role = aws_iam_role.glue_job_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:BatchGetPartition"
        ]
        Resource = [
          "arn:aws:glue:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:database/${var.database_name}",
          "arn:aws:glue:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:table/${var.database_name}/*"
        ]
      }
    ]
  })
}

# =============================================================================
# PROCESS AND UPLOAD GLUE SCRIPT
# =============================================================================

# Upload the processed script to S3
resource "aws_s3_object" "glue_script" {
  bucket = var.scripts_bucket_name
  key    = "features.py"
  content = templatefile("${path.module}/features.py", {
    database      = var.database_name
    output_bucket = var.output_bucket_name
  })

  depends_on = [var.glue_script_bucket_arn]
}

# Upload the wheel to S3
resource "aws_s3_object" "joblib_wheel" {
  bucket = var.scripts_bucket_name
  key    = "wheels/joblib-1.5.1-py3-none-any.whl"
  source = "${path.module}/wheels/joblib-1.5.1-py3-none-any.whl"
  etag   = filemd5("${path.module}/wheels/joblib-1.5.1-py3-none-any.whl")

  depends_on = [var.glue_script_bucket_arn]
}

resource "aws_s3_object" "sklearn_wheel" {
  count  = var.sklearn_wheel_filename != null ? 1 : 0
  bucket = var.scripts_bucket_name
  key    = "wheels/${var.sklearn_wheel_filename}"
  source = "${path.module}/wheels/${var.sklearn_wheel_filename}"
  etag   = filemd5("${path.module}/wheels/${var.sklearn_wheel_filename}")
}

# =============================================================================
# GLUE JOB
# =============================================================================

resource "aws_glue_job" "feature_engineering" {
  name        = "${var.job_name}-${var.env}"
  role_arn    = aws_iam_role.glue_job_role.arn
  description = var.job_description

  glue_version = var.glue_version

  worker_type       = var.worker_type
  number_of_workers = var.number_of_workers

  timeout     = var.timeout
  max_retries = var.max_retries

  command {
    script_location = var.script_location
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"                   = "true"
    "--extra-py-files" = join(",", [
      "s3://${aws_s3_object.joblib_wheel.bucket}/${aws_s3_object.joblib_wheel.key}",
      "s3://${aws_s3_object.sklearn_wheel.bucket}/${aws_s3_object.sklearn_wheel.key}"
    ])
  }

  depends_on = [aws_s3_object.glue_script]

  execution_property {
    max_concurrent_runs = 1
  }

  tags = {
    Name        = "${var.job_name}-${var.env}"
    Environment = var.env
  }
}

resource "aws_glue_connection" "vpc_connection" {
  name = "glue-vpc-connection-${var.env}"

  connection_type = "NETWORK"

  physical_connection_requirements {
    subnet_id              = var.private_subnet_ids[0]
    security_group_id_list = [var.glue_sagemaker_lambda_security_group_id]
    availability_zone      = data.aws_subnet.glue_subnet.availability_zone
  }

  tags = {
    Name        = "glue-vpc-connection-${var.env}"
    Environment = var.env
  }
}

data "aws_subnet" "glue_subnet" {
  id = var.private_subnet_ids[0]
}


