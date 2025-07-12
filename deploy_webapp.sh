#!/bin/bash

echo "🚀 Deploying webapp to S3..."

# Navigate to the environments/dev directory
cd environments/dev || exit

echo "🔍 Running terraform output..."
terraform output -raw webapp_bucket_name > /tmp/bucket_name.txt 2>&1

echo "🔍 Raw bucket output:"
cat /tmp/bucket_name.txt

echo "🔍 Exit code for terraform output: $?"

# Extract the bucket name by cutting off everything after '::'
BUCKET_NAME=$(grep -E "^[a-zA-Z0-9.-]+::" /tmp/bucket_name.txt | cut -d':' -f1)

echo "🔍 Debug: BUCKET_NAME is '$BUCKET_NAME'"

# Check if the bucket name is valid
if [ -z "$BUCKET_NAME" ]; then
    echo "❌ No valid bucket name found in terraform output."
    exit 1
fi

echo "✅ Deployment script completed without syntax errors." 