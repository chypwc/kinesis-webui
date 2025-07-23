# =============================================================================
# AWS KINESIS PIPELINE - MAKEFILE
# =============================================================================
# This Makefile provides automation for common development tasks
# 
# Available targets:
# - update-api-url: Updates the API Gateway URL in webapp/js/app.js and webapp/server.js
# - deploy-webapp: Deploys webapp files to S3 bucket created by Terraform
# =============================================================================

# =============================================================================
# API GATEWAY URL UPDATE
# =============================================================================
# This target automatically updates the API_GATEWAY_URL in the web application
# by extracting the current URL from Terraform outputs.
#
# Usage: make update-api-url
#
# What it does:
# 1. Gets the API Gateway URL from Terraform output
# 2. Updates the API_GATEWAY_URL constant in webapp/js/app.js
# 3. Updates the API_GATEWAY_URL constant in webapp/server.js
# 4. Shows confirmation message
# =============================================================================
update-api-url:
	@echo "🔄 Updating API Gateway URL..."
	@cd environments/dev && \
	echo "🔍 Running terraform output for API URL..." && \
	if [[ "$$OSTYPE" == "darwin"* ]]; then \
		API_URL=$$(terraform output -raw api_invoke_url); \
	else \
		API_URL=$$(terraform output -raw api_invoke_url | sed 's/::debug::Terraform exited with code 0.//g' | grep -E "^https://" | head -1); \
	fi && \
	echo "🔍 Extracted API_URL: '$$API_URL'" && \
	if [ -z "$$API_URL" ]; then \
		echo "❌ No API URL found in terraform output." && \
		exit 1; \
	fi && \
	FULL_URL="$$API_URL/submit" && \
	cd ../.. && \
	echo "🔍 Updating app.js..." && \
	sed -i.bak "s|const API_GATEWAY_URL = .*|const API_GATEWAY_URL = '$$FULL_URL'|" webapp/js/app.js && \
	echo "🔍 Updating server.js..." && \
	sed -i.bak "s|const API_GATEWAY_URL = .*|const API_GATEWAY_URL = '$$FULL_URL'|" webapp/server.js && \
	echo "✅ Updated API Gateway URL to: $$FULL_URL"

# =============================================================================
# DEPLOY WEBAPP TO S3
# =============================================================================
# This target deploys the webapp files to the S3 bucket created by Terraform
# and shows the CloudFront URL for accessing the webapp.
#
# Usage: make deploy-webapp
#
# What it does:
# 1. Gets S3 bucket name from Terraform output or terraform.tfvars
# 2. Uploads webapp files to S3 bucket
# 3. Gets CloudFront URL from Terraform output
# 4. Shows deployment URLs
#
# Prerequisites:
# - Terraform infrastructure must be deployed
# - AWS CLI configured
# - Must be run from project root
# =============================================================================
deploy-webapp:
	@echo "🚀 Deploying webapp..."
	@echo "🔍 Getting bucket name..."
	@cd environments/dev && \
	BUCKET_NAME=$$(grep "webapp_bucket_name" terraform.tfvars | cut -d'=' -f2 | tr -d ' "') && \
	echo "🔍 Bucket name: $$BUCKET_NAME" && \
	cd ../.. && \
	echo "📤 Syncing webapp files to S3..." && \
	aws s3 sync webapp/ s3://$$BUCKET_NAME \
		--exclude "node_modules/*" \
		--exclude "*.log" \
		--exclude ".git/*" && \
	echo "✅ Webapp files uploaded successfully to s3://$$BUCKET_NAME" && \
	echo "🔄 Invalidating CloudFront cache..." && \
	cd environments/dev && \
	echo "🔍 Getting CloudFront distribution ID..." && \
	if [[ "$$OSTYPE" == "darwin"* ]]; then \
		DISTRIBUTION_ID=$$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo ""); \
	else \
		DISTRIBUTION_ID=$$(terraform output -raw cloudfront_distribution_id 2>/dev/null | sed 's/::debug::Terraform exited with code 0.//g' | grep -E "^[A-Z0-9]+" | head -1 || echo ""); \
	fi && \
	echo "🔍 Distribution ID: '$$DISTRIBUTION_ID'" && \
	cd ../.. && \
	if [ -n "$$DISTRIBUTION_ID" ]; then \
		aws cloudfront create-invalidation --distribution-id $$DISTRIBUTION_ID --paths "/*" && \
		echo "✅ CloudFront cache invalidated for distribution: $$DISTRIBUTION_ID"; \
	else \
		echo "⚠️  No CloudFront distribution ID found. Skipping cache invalidation."; \
	fi && \
	echo "🔍 Running terraform output for web app URL..." && \
	cd environments/dev && \
	if [[ "$$OSTYPE" == "darwin"* ]]; then \
		WEBAPP_URL=$$(terraform output -raw webapp_url); \
	else \
		WEBAPP_URL=$$(terraform output -raw webapp_url | sed 's/::debug::Terraform exited with code 0.//g' | grep -E "^https://" | head -1); \
	fi && \
	echo "🌐 Web App URL: $$WEBAPP_URL" && \
	cd ../.. && \
	echo "✅ Deployment completed successfully."

# ======================================================
# Trigger Step Function and wait for result
# ======================================================
execute-step-function:
	@echo "🗑️ Deleting existing SageMaker resources..."
	-aws sagemaker delete-endpoint --endpoint-name xgboost-endpoint || true
	-aws sagemaker delete-endpoint-config --endpoint-config-name xgboost-endpoint-config || true
	-aws sagemaker delete-model --model-name xgboost-model || true
	@echo "🔄 Starting Step Function execution..."
	@ARN=$$(aws stepfunctions list-state-machines --query "stateMachines[?contains(name, 'sagemaker-workflow')].stateMachineArn" --output text) && \
	echo "Found State Machine ARN: $$ARN" && \
	EXECUTION_ARN=$$(aws stepfunctions start-execution \
		--state-machine-arn "$$ARN" \
		--name "execution-$$(date +%s)" \
		--query 'executionArn' \
		--output text) && \
	echo "Started execution: $$EXECUTION_ARN" && \
	while [ "$$(aws stepfunctions describe-execution --execution-arn "$$EXECUTION_ARN" --query 'status' --output text)" = "RUNNING" ]; do \
		echo "⏳ Running... $$(date)"; \
		sleep 30; \
	done && \
	echo "✅ Execution completed!" && \
	STATUS=$$(aws stepfunctions describe-execution --execution-arn "$$EXECUTION_ARN" --query 'status' --output text) && \
	echo "✅ Execution completed with status: $$STATUS" && \
	if [ "$$STATUS" != "SUCCEEDED" ]; then \
		echo "❌ Execution failed. Getting error details..."; \
		aws stepfunctions describe-execution --execution-arn "$$EXECUTION_ARN"; \
		exit 1; \
	fi