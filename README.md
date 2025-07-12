# 🚀 AWS Kinesis Data Pipeline with Web Application

A complete serverless data pipeline that captures shopping cart events via a web application and streams them to AWS S3 through Kinesis Data Streams and Firehose.

![](./images/webapp.png)

## 📋 Project Overview

This project implements a real-time data streaming pipeline using AWS services:

```
Web App → API Gateway → Lambda → Kinesis → Firehose → S3
```

### 🏗️ Architecture Components

- **Web Application**: Modern UI for data input
- **API Gateway**: HTTP API endpoint for receiving data
- **Lambda Function**: Processes and forwards data to Kinesis
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

## 🛠️ Development

### Testing

```bash
# Test API Gateway
curl -X POST https://your-api-gateway-url/submit \
  -H "Content-Type: application/json" \
  -d '{"user_id":123,"product_ids":["4321"],"event":"add_to_cart"}'

# Test web application
open http://localhost:3001
```

### Local Development

```bash
cd webapp
npm install
npm start
```
