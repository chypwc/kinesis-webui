#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e


echo "--- Cleaning up old build artifacts ---"
rm lambda_function_payload.zip
# rm -rf package lambda_function_payload.zip
# mkdir -p package

# echo "--- Building deployment package  ---"
# pip install \
#   --platform manylinux2014_aarch64 \
#   --target=./package \
#   --implementation cp \
#   --python-version 3.12 \
#   --only-binary=:all: --upgrade \
#   numpy pandas joblib scikit-learn 

# cd package/sklearn
# # Remove all test, doc, and dev files from all packages
# find . -type d -name 'tests' -exec rm -rf {} + || true
# find . -type d -name 'testing' -exec rm -rf {} + || true
# find . -type d -name 'test' -exec rm -rf {} + || true
# find . -type d -name 'doc' -exec rm -rf {} + || true
# find . -type d -name 'docs' -exec rm -rf {} + || true
# find . -type d -name '__pycache__' -exec rm -rf {} + || true
# find . -type d -name '_examples' -exec rm -rf {} + || true
# find . -type d -name '_pyinstaller' -exec rm -rf {} + || true
# # find . -type d -name 'src' -exec rm -rf {} + || true  # Do NOT remove src globally; needed for joblib/_multiprocessing_helpers.py
# find . -type d -name 'benchmarks' -exec rm -rf {} + || true
# find . -type d -name 'examples' -exec rm -rf {} + || true
# find . -type d -name 'demo' -exec rm -rf {} + || true
# find . -type d -name 'performance' -exec rm -rf {} + || true
# find . -type d -name 'build' -exec rm -rf {} + || true
# find . -type d -name 'dist' -exec rm -rf {} + || true
# find . -name '*.pyc' -delete
# find . -name '*.pyo' -delete
# rm -f numpy/conftest.py
# cd ..
# cd numpy 
# find . -type d -name 'doc' -exec rm -rf {} + || true
# find . -type d -name 'docs' -exec rm -rf {} + || true
# find . -type d -name '__pycache__' -exec rm -rf {} + || true
# find . -type d -name '_examples' -exec rm -rf {} + || true
# find . -type d -name '_pyinstaller' -exec rm -rf {} + || true
# # find . -type d -name 'src' -exec rm -rf {} + || true  
# find . -type d -name 'benchmarks' -exec rm -rf {} + || true
# find . -type d -name 'examples' -exec rm -rf {} + || true
# find . -type d -name 'demo' -exec rm -rf {} + || true
# find . -type d -name 'performance' -exec rm -rf {} + || true
# find . -type d -name 'build' -exec rm -rf {} + || true
# find . -type d -name 'dist' -exec rm -rf {} + || true
# find . -name '*.pyc' -delete
# find . -name '*.pyo' -delete
# rm -f numpy/conftest.py
# cd ..
# cd pandas
# find . -type d -name 'tests' -exec rm -rf {} + || true
# find . -type d -name 'testing' -exec rm -rf {} + || true
# find . -type d -name 'test' -exec rm -rf {} + || true
# find . -type d -name 'doc' -exec rm -rf {} + || true
# find . -type d -name 'docs' -exec rm -rf {} + || true
# find . -type d -name '__pycache__' -exec rm -rf {} + || true
# find . -type d -name '_examples' -exec rm -rf {} + || true
# find . -type d -name '_pyinstaller' -exec rm -rf {} + || true
# # find . -type d -name 'src' -exec rm -rf {} + || true  # Do NOT remove src globally; needed for joblib/_multiprocessing_helpers.py
# find . -type d -name 'benchmarks' -exec rm -rf {} + || true
# find . -type d -name 'examples' -exec rm -rf {} + || true
# find . -type d -name 'demo' -exec rm -rf {} + || true
# find . -type d -name 'performance' -exec rm -rf {} + || true
# find . -type d -name 'build' -exec rm -rf {} + || true
# find . -type d -name 'dist' -exec rm -rf {} + || true
# find . -name '*.pyc' -delete
# find . -name '*.pyo' -delete
# cd ../..

# Add scaler.pkl to the package
cp scaler.pkl package/

cd package
zip -r9 ../lambda_function_payload.zip .
cd ..

# Add your handler and scaler to the root of the zip
zip -g lambda_function_payload.zip lambda_function.py
zip -g lambda_function_payload.zip scaler.pkl


# 5. Verify the contents
echo "--- Verifying zip contents (should show lambda_function.py at the root) ---"
unzip -l lambda_function_payload.zip | grep lambda_function.py
unzip -l lambda_function_payload.zip | grep scaler.pkl
unzip -l lambda_function_payload.zip | grep numpy | head -n 10