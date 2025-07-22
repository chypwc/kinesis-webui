resource "aws_sagemaker_model" "xgb_model" {
  name               = "xgboost-model"
  execution_role_arn = aws_iam_role.sagemaker_execution_role.arn

  # https://docs.aws.amazon.com/sagemaker/latest/dg-ecr-paths/ecr-ap-southeast-2.html#xgboost-ap-southeast-2
  primary_container {
    image          = "783357654285.dkr.ecr.ap-southeast-2.amazonaws.com/sagemaker-xgboost:1.7-1"
    model_data_url = "s3://${var.model_bucket}/xgboost-model/output/${var.training_job_name}/output/model.tar.gz"
  }
}

resource "aws_sagemaker_endpoint_configuration" "xgb_endpoint_config" {
  name = "xgboost-endpoint-config"


  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.xgb_model.name
    initial_instance_count = 1
    instance_type          = "ml.t2.medium"
  }
}

resource "aws_sagemaker_endpoint" "xgb_endpoint" {
  name                 = "xgboost-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.xgb_endpoint_config.name
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