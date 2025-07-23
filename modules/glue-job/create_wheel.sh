#!/bin/bash

# Create wheels directory
mkdir -p wheels

# Install specific versions
pip install joblib==1.5.1 scikit-learn==1.7.1

# Create wheels with specific versions
pip wheel --wheel-dir=./wheels joblib==1.5.1 scikit-learn==1.7.1

echo "Created wheels:"
ls -la wheels/