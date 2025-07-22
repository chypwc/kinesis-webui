resource "aws_iam_role" "sfn_role" {
  name = "StepFunctionsExecutionRole-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "states.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "sfn_policy" {
  name        = "StepFunctionsPolicy-${var.env}"
  description = "Policy for Step Functions to execute tasks"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "sagemaker:CreateTrainingJob",
          "sagemaker:DescribeTrainingJob",
          "sagemaker:CreateModel",
          "sagemaker:CreateEndpointConfig",
          "sagemaker:CreateEndpoint",
          "sagemaker:DescribeEndpoint",
          "sagemaker:AddTags",
          "sagemaker:ListTags",
          "sagemaker:StopTrainingJob"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "events:PutTargets",
          "events:PutRule",
          "events:DescribeRule",
          "events:DeleteRule",
          "events:RemoveTargets"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sfn_policy_attach" {
  role       = aws_iam_role.sfn_role.name
  policy_arn = aws_iam_policy.sfn_policy.arn
}

resource "aws_sfn_state_machine" "sagemaker_workflow" {
  name     = "SageMakerWorkflow-${var.env}"
  role_arn = aws_iam_role.sfn_role.arn

  definition = templatefile("${path.module}/state-machine.json", {
    input_bucket                 = var.input_bucket,
    input_key                    = var.input_key,
    glue_job_name                = var.glue_job_name,
    training_job_name            = var.training_job_name,
    endpoint_name                = var.endpoint_name,
    model_name                   = "xgboost-model",
    endpoint_config_name         = var.endpoint_config_name,
    sagemaker_execution_role_arn = aws_iam_role.sagemaker_execution_role.arn
  })
}

resource "aws_iam_role" "sagemaker_execution_role" {
  name = "sagemaker-execution-role-stepfunctions-${var.env}"
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

resource "aws_iam_role_policy_attachment" "sagemaker_execution_policy" {
  role       = aws_iam_role.sagemaker_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# Custom policy for S3 access to data bucket
resource "aws_iam_role_policy" "sagemaker_s3_policy" {
  name = "sagemaker-s3-policy-${var.env}"
  role = aws_iam_role.sagemaker_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.input_bucket}",
          "arn:aws:s3:::${var.input_bucket}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.input_bucket}/*"
        ]
      }
    ]
  })
}
