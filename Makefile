# =============================================================================
# AWS KINESIS PIPELINE - MAKEFILE
# =============================================================================
# This Makefile provides automation for common development tasks
# 
# Available targets:
# - update-api-url: Updates the API Gateway URL in webapp/js/app.js
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
# 1. Runs 'terraform output -raw api_invoke_url' to get the current API Gateway URL
# 2. Escapes special characters for sed replacement
# 3. Updates the API_GATEWAY_URL constant in webapp/js/app.js
# 4. Shows confirmation message with the updated URL
#
# Prerequisites:
# - Terraform must be initialized and applied
# - Must be run from project root directory
# =============================================================================
update-api-url:
	@echo "Updating API Gateway URL from Terraform output..."
	@API_URL=$$(cd environments/dev && terraform output -raw api_invoke_url) && \
	ESCAPED_URL=$$(printf '%s\n' "$$API_URL/submit" | sed 's/[&/]/\\&/g') && \
	sed -i '' "s|const API_GATEWAY_URL = .*;|const API_GATEWAY_URL = '$$ESCAPED_URL';|" webapp/js/app.js && \
	echo "Updated API_GATEWAY_URL to: $$API_URL/submit in webapp/js/app.js" 