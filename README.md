# 🚀 AWS Kinesis Data Pipeline with Web Application

A complete serverless data pipeline that captures shopping cart events via a web application and streams them to AWS S3 through Kinesis Data Streams and Firehose.

![](./images/webapp.png)

## 🏗️ Architecture

This repository contains two distinct architectural approaches in separate branches:

### `main` Branch (Default Architecture)

The `main` branch uses a standard serverless pattern with an **API Gateway HTTP API** that triggers an **AWS Lambda function**.

```
Web App → API Gateway (HTTP API) → Lambda → Kinesis → Firehose → S3
```

This approach is easy to set up and is ideal for scenarios where you need to perform data validation, enrichment, or transformation logic within the Lambda function before sending the data to Kinesis.

### `direct-apigw-kinesis` Branch (Low-Latency Architecture)

For a lower-latency solution, the `direct-apigw-kinesis` branch removes the Lambda function and uses a direct integration between an **API Gateway REST API** and Kinesis.

```
Web App → API Gateway (REST API) → Kinesis → Firehose → S3
```

This architecture is more cost-effective and performant as it bypasses the Lambda invocation overhead. It is suitable for high-throughput use cases where data can be sent directly to the stream without intermediate processing.

---

## 📋 Project Overview

This project implements a real-time data streaming pipeline using AWS services:

### Architecture Components

- **Web Application**: Modern UI for data input
- **API Gateway**: An HTTP API or REST API endpoint for receiving data
- **Lambda Function** (`main` branch only): Processes and forwards data to Kinesis
- **Kinesis Data Stream**: Real-time data streaming
- **Firehose**: Batch delivery to S3
- **S3 Bucket**: Data storage

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured
- Terraform installed
- Node.js (for web application)

### 1. Deploy Infrastructure

```bash
cd environments/dev
terraform init
terraform apply
```

### 2. Deploy Web Application

```bash
# Update API Gateway URL
make update-api-url

# Deploy to S3 + CloudFront
make deploy-webapp
```

### 3. Access the Web Application

The web UI URL and API Gateway URL can be found after deploying by GitHub Action workflow.

- **CloudFront URL**: `https://your-cloudfront-domain.cloudfront.net`
- **S3 Website URL**: `http://your-bucket-name.s3-website-ap-southeast-2.amazonaws.com`

## 🌐 Web UI Deployment

### Architecture

```
Web App Files → S3 Bucket → CloudFront → Global CDN
```

### Deployment Commands

```bash
# Update API Gateway URL
make update-api-url

# Deploy to S3 + CloudFront
make deploy-webapp
```

### Features

- ✅ **Automatic API URL Updates**: From Terraform outputs
- ✅ **Cross-Platform Support**: macOS and Ubuntu
- ✅ **Cache Invalidation**: Automatic CloudFront cache clearing
- ✅ **Secure Access**: S3 only accessible via CloudFront
- ✅ **HTTPS Support**: SSL certificates via CloudFront
- ✅ **Global CDN**: Fast worldwide access

### Troubleshooting

#### API Gateway URL Issues

1. Check API Gateway is deployed and active
2. Run `make update-api-url` to update the URL
3. Run `make deploy-webapp` to upload updated files

## 📁 Project Structure

```
kinesis/
├── environments/dev/        # Terraform configuration
├── modules/                 # Terraform modules
├── webapp/                  # Web application
├── Makefile                 # Build automation
└── README.md                # This file
```

## 🎯 Features

### Web Application

- ✅ Modern responsive UI
- ✅ Form validation
- ✅ Real-time feedback
- ✅ Multiple event types

### Infrastructure

- ✅ Serverless architecture
- ✅ Auto-scaling
- ✅ Secure IAM roles
- ✅ CloudWatch logging

## 📊 Data Flow

1. **Web Application**: User submits shopping cart data
2. **API Gateway**: Receives HTTP POST requests
3. **Lambda Function**: Processes and forwards to Kinesis
4. **Kinesis Data Stream**: Real-time streaming
5. **Firehose**: Batches and delivers to S3
6. **S3 Storage**: Long-term data storage

## 🧬 Machine Learning Pipeline Components

### AWS Glue Job (Feature Engineering)

- **Location:** `modules/glue-job/`
- **Purpose:** Performs feature engineering and data transformation using PySpark. Reads raw data, creates features, applies scaling, and writes processed features to S3 and DynamoDB for use in real-time recommendations.
- **Deployment:** Managed as a Glue Job via Terraform. Outputs a scaler model to S3 for use in Lambda and SageMaker.

### SageMaker Notebook

- **Location:** `modules/sagemaker/notebook/`
- **Purpose:** Provides a managed Jupyter notebook environment for interactive development, data exploration, and model training.
- **Deployment:**
  - Terraform provisions a notebook instance (`ml.t3.medium`) with a lifecycle configuration that downloads the latest training notebook from S3 on startup.
  - IAM roles grant access to S3 and SageMaker resources.

### SageMaker Endpoint (Model Inference)

- **Location:** `modules/sagemaker/endpoint/`
- **Purpose:** Hosts the trained XGBoost model as a real-time inference endpoint.
- **Deployment:**
  - Terraform creates a SageMaker model resource using the official AWS XGBoost container (`783357654285.dkr.ecr.ap-southeast-2.amazonaws.com/sagemaker-xgboost:1.7-1`).
  - The model artifact is loaded from S3 (output of the training job).
  - An endpoint configuration and endpoint are created for real-time predictions.

**Data Flow:**

- Glue Job → S3/DynamoDB (features, scaler)
- SageMaker Notebook → S3 (training, model artifacts)
- SageMaker Endpoint ← S3 (model) ← Notebook/Glue Job
- Lambda fetches features from DynamoDB, scales input, and invokes the SageMaker endpoint for recommendations.

## 🛠️ Development

### Testing

```

```
