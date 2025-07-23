#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e


echo "--- Cleaning up old build artifacts ---"
# rm lambda_function_payload.zip
rm -rf package lambda_function_payload.zip
mkdir -p package

echo "--- Building deployment package  ---"


if [[ "$OSTYPE" == "darwin"* ]]; then
  pip install \
    --platform manylinux2014_aarch64 \
    --target=./package \
    --implementation cp \
    --python-version 3.12 \
    --only-binary=:all: --upgrade \
    numpy pandas joblib scikit-learn
else
  pip install \
    --platform manylinux2014_x86_64 \
    --target=./package \
    --implementation cp \
    --python-version 3.12 \
    --only-binary=:all: --upgrade \
    numpy pandas joblib scikit-learn
fi

cd package

# Remove only safe-to-remove directories, preserve package structure
# find . -type d -name 'tests' -exec rm -rf {} + 2>/dev/null || true
find . -type d -name 'test' -exec rm -rf {} + 2>/dev/null || true
find . -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true
find . -name '*.pyc' -delete 2>/dev/null || true
find . -name '*.pyo' -delete 2>/dev/null || true

# Remove documentation (but preserve core package files)
find . -type d -name 'doc' -exec rm -rf {} + 2>/dev/null || true
find . -type d -name 'docs' -exec rm -rf {} + 2>/dev/null || true
find . -type d -name 'examples' -exec rm -rf {} + 2>/dev/null || true

cd ..

# Add your Lambda function and scaler to the package directory (not root)
cp lambda_function.py package/lambda_function.py
# cp scaler.pkl package/scaler.pkl

cd package
zip -r9 ../lambda_function_payload.zip .
cd ..


# 5. Verify the contents
echo "--- Verifying zip contents (should show lambda_function.py at the root) ---"
unzip -l lambda_function_payload.zip | grep lambda_function.py
# unzip -l lambda_function_payload.zip | grep scaler.pkl
unzip -l lambda_function_payload.zip | grep numpy | head -n 10