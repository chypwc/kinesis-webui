output "state_machine_arn" {
  description = "The ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.sagemaker_workflow.arn
}

output "state_machine_name" {
  description = "The name of the Step Functions state machine"
  value       = aws_sfn_state_machine.sagemaker_workflow.name
}

output "execution_role_arn" {
  description = "The ARN of the Step Functions execution role"
  value       = aws_iam_role.sfn_role.arn
}


