#!/bin/bash

echo "🚀 Deploying webapp to S3..."

# Navigate to the environments/dev directory
cd environments/dev || exit

echo "🔍 Running terraform output for bucket name..."
terraform output -raw webapp_bucket_name > /tmp/bucket_name.txt 2>&1

echo "🔍 Raw bucket output:"
cat /tmp/bucket_name.txt

echo "🔍 Exit code for terraform output: $?"

# Determine the OS and extract the bucket name accordingly
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    BUCKET_NAME=$(grep -E "^[a-zA-Z0-9.-]+" /tmp/bucket_name.txt | cut -d':' -f1)
else
    # Assume Linux (Ubuntu)
    BUCKET_NAME=$(grep -E "^[a-zA-Z0-9.-]+::" /tmp/bucket_name.txt | cut -d':' -f1)
fi

echo "🔍 Debug: BUCKET_NAME is '$BUCKET_NAME'"

# Check if the bucket name is valid
if [ -z "$BUCKET_NAME" ]; then
    echo "❌ No valid bucket name found in terraform output."
    exit 1
fi

# Extract the web app URL
echo "🔍 Running terraform output for web app URL..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    WEBAPP_URL=$(terraform output -raw webapp_url | cut -d':' -f1)
else
    # Assume Linux (Ubuntu)
    WEBAPP_URL=$(terraform output -raw webapp_url | cut -d':' -f1)
fi

echo "🌐 Web App URL: $WEBAPP_URL"

echo "✅ Deployment script completed without syntax errors." 