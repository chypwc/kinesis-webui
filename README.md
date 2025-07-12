# 🚀 AWS Kinesis Data Pipeline with Web Application

A complete serverless data pipeline that captures shopping cart events via a web application and streams them to AWS S3 through Kinesis Data Streams and Firehose.

## 📋 Project Overview

This project implements a real-time data streaming pipeline using AWS services:

```
Web App → API Gateway → Lambda → Kinesis → Firehose → S3
```

### 🏗️ Architecture Components

- **Web Application**: Modern React-like UI for data input
- **API Gateway**: HTTP API endpoint for receiving data
- **Lambda Function**: Processes and forwards data to Kinesis
- **Kinesis Data Stream**: Real-time data streaming
- **Firehose**: Batch delivery to S3
- **S3 Bucket**: Data storage with versioning

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured
- Terraform installed
- Node.js (for web application)

### 1. Deploy Infrastructure

```bash
# Navigate to dev environment
cd environments/dev

# Initialize Terraform
terraform init

# Deploy infrastructure
terraform apply
```

### 2. Start Web Application

```bash
# Navigate to webapp directory
cd webapp

# Install dependencies
npm install

# Start development server
npm start
```

### 3. Update API Gateway URL

```bash
# From project root
make update-api-url
```

## 📁 Project Structure

```
kinesis/
├── environments/
│   └── dev/                 # Terraform configuration
│       ├── main.tf         # Infrastructure resources
│       ├── variables.tf    # Input variables
│       ├── outputs.tf      # Output values
│       └── terraform.tfvars # Variable values
├── modules/
│   ├── api-gateway/        # API Gateway module
│   ├── firehose/          # Firehose delivery stream
│   ├── kinesis/           # Kinesis data stream
│   ├── lambda/            # Lambda function
│   └── s3/               # S3 bucket
├── webapp/               # Web application
│   ├── index.html        # Main HTML file
│   ├── css/styles.css    # Styling
│   ├── js/app.js        # JavaScript logic
│   ├── server.js        # Node.js server
│   └── package.json     # Dependencies
├── Makefile             # Build automation
├── TODO.md             # Project tasks
└── pipeline.md         # Architecture documentation
```

## 🎯 Features

### Web Application

- ✅ **Modern UI**: Responsive design with gradients and animations
- ✅ **Form Validation**: Real-time validation for inputs
- ✅ **Optional Product IDs**: Can submit data without products
- ✅ **Real-time Feedback**: Live status updates and response logging
- ✅ **Multiple Event Types**: Add, remove, update, checkout events

### Infrastructure

- ✅ **Serverless**: No servers to manage
- ✅ **Scalable**: Auto-scaling based on demand
- ✅ **Secure**: IAM roles and policies
- ✅ **Monitored**: CloudWatch logging

## 📊 Data Flow

### 1. Web Application Input

```json
{
  "user_id": 12345,
  "product_ids": ["PROD001", "PROD002"],
  "event": "add_to_cart"
}
```

### 2. API Gateway Processing

- Receives HTTP POST requests
- Validates input data
- Forwards to Lambda function

### 3. Lambda Function

- Processes JSON payload
- Adds timestamp and metadata
- Sends to Kinesis stream

### 4. Kinesis Data Stream

- Real-time data streaming
- 1 shard configuration
- 24-hour retention

### 5. Firehose Delivery

- Batches data every 60 seconds
- Delivers to S3 bucket
- Uncompressed format

### 6. S3 Storage

- Versioned bucket
- Organized by date/time
- Long-term storage

## 🛠️ Development

### Adding New Features

1. **Update Lambda Function**:

   ```bash
   # Edit modules/lambda/lambda_function.py
   # Run terraform apply to deploy
   ```

2. **Modify Web Application**:

   ```bash
   # Edit webapp/js/app.js
   # Refresh browser to see changes
   ```

3. **Update Infrastructure**:
   ```bash
   # Edit Terraform files
   # Run terraform plan && terraform apply
   ```

### Testing

```bash
# Test API Gateway directly
curl -X POST https://your-api-gateway-url/submit \
  -H "Content-Type: application/json" \
  -d '{"user_id":123,"product_ids":["P1"],"event":"add_to_cart"}'

# Test web application
open http://localhost:3001
```

## 🔧 Configuration

### Environment Variables

- `AWS_REGION`: AWS region (default: ap-southeast-2)
- `ENVIRONMENT`: Deployment environment (default: dev)

### Terraform Variables

- `firehose_bucket_name`: S3 bucket name
- `kinesis_stream_name`: Kinesis stream name
- `lambda_function_name`: Lambda function name
- `api_gateway_name`: API Gateway name

## 📈 Monitoring

### CloudWatch Logs

- Lambda function logs
- API Gateway access logs
- Firehose delivery logs

### S3 Metrics

- Bucket size and object count
- Request metrics
- Error rates

## 🔒 Security

### IAM Roles

- **Lambda Role**: Basic execution + Kinesis permissions
- **Firehose Role**: S3 write + Kinesis read permissions
- **API Gateway**: Lambda invoke permissions

### Network Security

- API Gateway with CORS headers
- S3 bucket with public access blocked
- VPC isolation (if needed)

## 🚀 Deployment

### Production Deployment

1. **Create Production Environment**:

   ```bash
   cp -r environments/dev environments/prod
   ```

2. **Update Variables**:

   ```bash
   # Edit environments/prod/terraform.tfvars
   env = "prod"
   ```

3. **Deploy**:
   ```bash
   cd environments/prod
   terraform apply
   ```

### CI/CD Pipeline

```yaml
# Example GitHub Actions workflow
name: Deploy Pipeline
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: hashicorp/setup-terraform@v1
      - run: |
          cd environments/dev
          terraform init
          terraform apply -auto-approve
```

## 🧹 Cleanup

### Remove All Resources

```bash
cd environments/dev
terraform destroy
```

### Clean Local Files

```bash
# Remove Terraform state
rm -rf .terraform/

# Remove webapp dependencies
rm -rf webapp/node_modules/
```

## 📚 Documentation

- [pipeline.md](pipeline.md): Detailed architecture documentation
- [TODO.md](TODO.md): Project tasks and progress
- [webapp/README.md](webapp/README.md): Web application guide

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.

## 🆘 Support

For issues and questions:

1. Check the documentation
2. Review CloudWatch logs
3. Test with curl commands
4. Create an issue in the repository

---

**Built with ❤️ using AWS, Terraform, and Node.js**
