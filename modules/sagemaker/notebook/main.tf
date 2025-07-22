resource "aws_s3_object" "train_notebook" {
  bucket = var.notebook_bucket
  key    = "notebooks/train.ipynb"
  source = "../../modules/sagemaker/train.ipynb"
  etag   = filemd5("${path.module}/train.ipynb")
}

resource "aws_iam_role" "sagemaker_execution_role" {
  name = "sagemaker-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "sagemaker.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       = aws_iam_role.sagemaker_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy_attachment" "sagemaker_s3_full_access" {
  role       = aws_iam_role.sagemaker_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Downloads notebook from S3 on startup
resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "copy_notebook" {
  name = "copy-train-notebook"

  on_create = base64encode(<<SCRIPT
#!/bin/bash
set -e
aws s3 cp s3://${aws_s3_object.train_notebook.bucket}/${aws_s3_object.train_notebook.key} /home/ec2-user/SageMaker/train.ipynb
chown ec2-user:ec2-user /home/ec2-user/SageMaker/train.ipynb
SCRIPT
  )
}

# Creates the notebook instance
resource "aws_sagemaker_notebook_instance" "train_notebook" {
  name                 = "train-notebook"
  instance_type        = "ml.t3.medium"
  role_arn             = aws_iam_role.sagemaker_execution_role.arn
  lifecycle_config_name = aws_sagemaker_notebook_instance_lifecycle_configuration.copy_notebook.name
}