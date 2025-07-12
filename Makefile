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
	terraform output -raw api_invoke_url > /tmp/api_url.txt 2>&1 && \
	if [ $$? -ne 0 ]; then \
		echo "❌ Failed to get terraform output. Please run 'terraform apply' first."; \
		exit 1; \
	fi && \
	API_URL=$$(cat /tmp/api_url.txt | grep -v "::debug::" | grep -v "::error::" | grep -v "terraform-bin" | head -1) && \
	if [ -z "$$API_URL" ]; then \
		echo "❌ No API URL found in terraform output."; \
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
	BUCKET_NAME=$$(cat /tmp/bucket_name.txt | grep -v "::debug::" | grep -v "::error::" | grep -v "terraform-bin" | head -1) && \
	echo "📦 S3 Bucket: $$BUCKET_NAME" && \
	cd ../.. && \
	echo "📤 Uploading webapp files to S3..." && \
	aws s3 sync webapp/ s3://$$BUCKET_NAME \
		--exclude "node_modules/*" \
		--exclude "*.log" \
		--exclude ".git/*" && \
	cd environments/dev && \
	terraform output -raw webapp_url > /tmp/webapp_url.txt 2>&1 && \
	WEBAPP_URL=$$(cat /tmp/webapp_url.txt | grep -v "::debug::" | grep -v "::error::" | grep -v "terraform-bin" | head -1) && \
	cd ../.. && \
	echo "✅ Webapp deployed successfully!" && \
	echo "🌐 CloudFront URL: $$WEBAPP_URL" && \
	echo "📡 S3 Website URL: http://$$BUCKET_NAME.s3-website-$$AWS_DEFAULT_REGION.amazonaws.com"

 