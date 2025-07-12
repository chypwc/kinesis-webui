update-api-url:
	@echo "Updating API Gateway URL from Terraform output..."
	@API_URL=$$(cd environments/dev && terraform output -raw api_invoke_url) && \
	ESCAPED_URL=$$(printf '%s\n' "$$API_URL/submit" | sed 's/[&/]/\\&/g') && \
	sed -i '' "s|const API_GATEWAY_URL = .*;|const API_GATEWAY_URL = '$$ESCAPED_URL';|" webapp/js/app.js && \
	echo "Updated API_GATEWAY_URL to: $$API_URL/submit in webapp/js/app.js" 