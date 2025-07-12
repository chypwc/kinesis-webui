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
	echo "🔍 Checking terraform state..." && \
	terraform state list 2>/dev/null | head -5 || echo "❌ No terraform state found" && \
	echo "🔍 Running terraform output..." && \
	terraform output -raw api_invoke_url > /tmp/api_url.txt 2>&1; EXIT_CODE=$$? && \
	echo "🔍 Terraform output command completed with exit code: $$EXIT_CODE" && \
	echo "🔍 Exit code: $$EXIT_CODE" && \
	if [ $$EXIT_CODE -ne 0 ]; then \
		echo "❌ Failed to get terraform output (exit code: $$EXIT_CODE)" && \
		echo "💡 Please run 'terraform apply' first to create the infrastructure" && \
		exit 1; \
	fi && \
	echo "🔍 Raw output:" && \
	cat /tmp/api_url.txt && \
	API_URL=$$(cat /tmp/api_url.txt | grep "https://" | cut -d':' -f1-3 | sed 's/:$$//' | head -1) && \
	echo "🔍 Extracted API_URL: '$$API_URL'" && \
	if [ -z "$$API_URL" ]; then \
		echo "❌ No API URL found in terraform output." && \
		exit 1; \
	fi && \
	FULL_URL="$$API_URL/submit" && \
	cd ../.. && \
	perl -pi -e "s|const API_GATEWAY_URL = .*;|const API_GATEWAY_URL = '$$FULL_URL';|" webapp/js/app.js && \
	perl -pi -e "s|const API_GATEWAY_URL = .*;|const API_GATEWAY_URL = '$$FULL_URL';|" webapp/server.js && \
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
# 1. Gets S3 bucket name from Terraform output
# 2. Syncs webapp files to S3 bucket
# 3. Gets CloudFront URL from Terraform output
# 4. Shows deployment URLs
#
# Prerequisites:
# - Terraform infrastructure must be deployed
# - AWS CLI configured
# - Must be run from project root
# =============================================================================
deploy-webapp:
	@echo "🚀 Deploying webapp to S3..."
	@cd environments/dev && \
	terraform output -raw webapp_bucket_name > /tmp/bucket_name.txt 2>&1 && \
	echo "🔍 Raw bucket output:" && \
	cat /tmp/bucket_name.txt && \
	BUCKET_NAME=$$(cat /tmp/bucket_name.txt | grep -E "^[a-zA-Z0-9\-]+$" | head -1) && \
	echo "🔍 Extracted BUCKET_NAME: '$$BUCKET_NAME'" && \
	if [ -z "$$BUCKET_NAME" ]; then \
		echo "❌ No bucket name found in terraform output." && \
		exit 1; \
	fi && \
	echo "📦 S3 Bucket: $$BUCKET_NAME" && \
	cd ../.. && \
	if [ -z "$$BUCKET_NAME" ]; then \
		echo "❌ Bucket name is empty. Cannot deploy to S3." && \
		exit 1; \
	fi && \
	echo "📤 Uploading webapp files to S3..." && \
	aws s3 sync webapp/ s3://$$BUCKET_NAME \
		--exclude "node_modules/*" \
		--exclude "*.log" \
		--exclude ".git/*" && \
	cd environments/dev && \
	terraform output -raw webapp_url > /tmp/webapp_url.txt 2>&1 && \
	WEBAPP_URL=$$(cat /tmp/webapp_url.txt | grep "https://" | head -1) && \
	cd ../.. && \
	echo "✅ Webapp deployed successfully!" && \
	echo "🌐 CloudFront URL: $$WEBAPP_URL" && \
	echo "📡 S3 Website URL: http://$$BUCKET_NAME.s3-website-ap-southeast-2.amazonaws.com"

 