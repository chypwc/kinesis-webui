# =============================================================================
# AWS KINESIS PIPELINE - MAKEFILE
# =============================================================================
# This Makefile provides automation for common development tasks
# 
# Available targets:
# - update-api-url: Updates the API Gateway URL in webapp/js/app.js and webapp/server.js
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
	API_URL=$$(terraform output -raw api_invoke_url) && \
	FULL_URL="$$API_URL/submit" && \
	cd ../.. && \
	sed -i '' "s|const API_GATEWAY_URL = .*|const API_GATEWAY_URL = '$$FULL_URL'|" webapp/js/app.js && \
	sed -i '' "s|const API_GATEWAY_URL = .*|const API_GATEWAY_URL = '$$FULL_URL'|" webapp/server.js && \
	echo "✅ Updated API Gateway URL to: $$FULL_URL" 