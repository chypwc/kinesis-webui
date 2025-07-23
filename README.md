# 🚀 AWS Real-Time Product Recommendation Pipeline

![](./images/webapp.png)

## 📋 Project Overview

This project implements a comprehensive serverless real-time product recommendation system using AWS services. The system combines streaming data processing with machine learning to provide personalized product recommendations to users in real-time.

### Key Capabilities

- **Real-Time Recommendations**: Generate personalized product suggestions using ML models
- **Streaming Data Pipeline**: Process user interactions in real-time via Kinesis
- **Serverless Architecture**: Fully managed AWS services with auto-scaling
- **Modern Web Interface**: Responsive web application for user interactions
- **ML Pipeline Automation**: Automated feature engineering and model training

## 🏗️ Architecture

The system implements a modern serverless architecture combining real-time data processing with machine learning inference:

### Core Components

- **Web Application**: Modern responsive UI for user interaction and product recommendations
- **API Gateway**: RESTful endpoints for receiving user data and serving recommendations
- **Lambda Functions**: 
  - **Inference Lambda**: Fetches user features from DynamoDB and generates recommendations via SageMaker
  - **Data Processing**: Handles user data and forwards to Kinesis for analytics
- **SageMaker Endpoint**: Real-time XGBoost model inference for product recommendations
- **Kinesis Data Stream**: Real-time streaming of user interaction data
- **Firehose**: Batch delivery of stream data to S3 for analytics
- **DynamoDB**: Fast access to pre-computed user and product features
- **S3 Buckets**: Storage for raw data, processed features, and model artifacts
- **Step Functions**: Orchestrates the complete ML pipeline workflow
- **CloudFront**: Global content delivery network for the web application

### ML Pipeline Components

- **AWS Glue**: Automated feature engineering and data processing
- **SageMaker Training**: XGBoost model training with historical data
- **Model Registry**: Versioned model artifacts in S3
- **Feature Store**: DynamoDB tables with pre-computed user/product features

## 🎯 Data Flow

### Real-Time Recommendation Flow

1. **User Interaction**: User submits data via the web application
2. **API Gateway**: Receives POST request and triggers inference Lambda
3. **Feature Retrieval**: Lambda fetches user features from DynamoDB
4. **ML Inference**: SageMaker endpoint generates probability scores for products
5. **Product Metadata**: Lambda enriches recommendations with product details
6. **Response**: Personalized recommendations returned to user (< 500ms)
7. **Analytics**: User data simultaneously streamed to Kinesis for analytics

### ML Pipeline Flow

1. **Data Ingestion**: Raw user interaction data stored in S3
2. **Feature Engineering**: Glue job processes data and creates user/product features
3. **Feature Storage**: Processed features stored in DynamoDB for real-time access
4. **Model Training**: SageMaker trains XGBoost model on engineered features
5. **Model Deployment**: Trained model deployed to SageMaker endpoint
6. **Pipeline Orchestration**: Step Functions coordinates the entire workflow

![](./images/stepfunctions.png)

## 🤖 Machine Learning Model

### Model Architecture

- **Algorithm**: XGBoost Classifier for binary prediction (will user buy this product?)
- **Features**: User behavior patterns, product popularity metrics, interaction history
- **Training Data**: Historical shopping cart and order data
- **Prediction**: Probability scores for user-product combinations

### Feature Engineering

The system generates rich features including:
- **User Features**: Order frequency, product diversity, reorder patterns, time since last order
- **Product Features**: Popularity metrics, reorder rates, department/aisle information
- **Interaction Features**: User-product historical interactions and preferences

### Real-Time Inference

- **Sub-second Response**: < 500ms end-to-end recommendation generation
- **Scalable**: Auto-scaling SageMaker endpoints handle variable load
- **Personalized**: Individual recommendations based on user behavior patterns
- **Fallback**: Graceful handling when features or models are unavailable

## 🎯 Features

### Web Application
- ✅ **Modern Responsive UI**: Clean, mobile-friendly interface
- ✅ **Real-Time Recommendations**: Instant product suggestions
- ✅ **Form Validation**: Client-side input validation
- ✅ **Error Handling**: Graceful error states and retry logic
- ✅ **Cross-Browser Support**: Works across modern browsers

### Infrastructure
- ✅ **Serverless Architecture**: No server management required
- ✅ **Auto-Scaling**: Handles traffic spikes automatically
- ✅ **Security**: IAM roles with least-privilege access
- ✅ **Monitoring**: CloudWatch logs and metrics
- ✅ **Global CDN**: CloudFront for worldwide performance

### ML Pipeline
- ✅ **Automated Training**: Scheduled model retraining
- ✅ **Feature Engineering**: Automated data processing with Glue
- ✅ **Model Versioning**: Tracked model artifacts in S3
- ✅ **A/B Testing Ready**: Infrastructure supports model experimentation
- ✅ **Monitoring**: Model performance tracking and alerts

## 📁 Project Structure

```
kinesis/
├── environments/dev/          # Terraform environment configuration
│   ├── main.tf               # Main infrastructure definition
│   ├── variables.tf          # Environment variables
│   └── terraform.tfvars      # Environment-specific values
├── modules/                   # Reusable Terraform modules
│   ├── api-gateway/          # API Gateway configuration
│   ├── lambda/               # Lambda functions (inference + processing)
│   ├── sagemaker/           # ML training and endpoints
│   ├── step-functions/       # ML pipeline orchestration
│   ├── glue-job/            # Feature engineering
│   ├── dynamodb/            # Feature storage
│   ├── kinesis/             # Data streaming
│   ├── firehose/            # Data delivery
│   ├── s3/                  # Data storage
│   ├── s3-webapp/           # Web app hosting
│   ├── cloudfront/          # CDN configuration
│   └── vpc/                 # Network infrastructure
├── webapp/                   # Web application
│   ├── index.html           # Main application
│   ├── js/app.js            # Application logic
│   ├── css/styles.css       # Styling
│   └── server.js            # Local development server
├── other_scripts/           # Utility scripts
├── Makefile                 # Build and deployment automation
├── pipeline.md              # Technical pipeline documentation
└── README.md                # This file
```

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Node.js (for local web app development)
- Make utility

### Deployment Steps

1. **Initialize Terraform**
   ```bash
   cd environments/dev
   terraform init
   ```

2. **Deploy Core Infrastructure**
   ```bash
   terraform apply -target=module.s3 -target=module.dynamodb -target=module.glue_job
   ```

3. **Run ML Pipeline**
   ```bash
   terraform apply -target=module.step_functions
   make execute-step-function
   ```
   
   This automatically:
   - Processes data and engineers features
   - Trains the XGBoost recommendation model
   - Deploys the SageMaker inference endpoint

4. **Deploy Application Services**
   ```bash
   cd modules/lambda && ./create_package.sh
   cd ../../environments/dev
   terraform apply -target=module.lambda -target=module.api_gateway
   ```

5. **Deploy Web Application**
   ```bash
   terraform apply -target=module.kinesis -target=module.firehose -target=module.s3_webapp -target=module.cloudfront
   make update-api-url
   make deploy-webapp
   ```

### Access Your Application

After deployment, access your application via:
- **CloudFront URL**: `https://your-cloudfront-domain.cloudfront.net`
- **API Gateway**: Check Terraform outputs for the API endpoint

## 🧪 Testing

### Test Recommendations

```bash
curl -X POST https://your-api-gateway-url/submit \
  -H "Content-Type: application/json" \
  -d '{"user_id": "123", "event": "get_recommendations"}'
```

### Expected Response

```json
{
  "message": "Recommendations generated successfully",
  "recommendations": [
    {
      "product_id": "123",
      "probability": 0.85,
      "product_name": "Organic Bananas",
      "department": "produce",
      "aisle": "fresh fruits"
    }
  ]
}
```

## 🔧 Configuration

### Environment Variables

Key environment variables in `terraform.tfvars`:

```hcl
# Infrastructure
aws_region = "ap-southeast-2"
environment = "dev"

# ML Configuration  
sagemaker_instance_type = "ml.t2.medium"
model_name = "xgboost-recommender"

# Application
cors_allowed_origins = ["*"]
```

## 📊 Monitoring

### CloudWatch Dashboards

- **Lambda Performance**: Function duration, errors, invocations
- **SageMaker Metrics**: Endpoint utilization, inference latency
- **Kinesis Metrics**: Stream throughput, shard utilization
- **API Gateway**: Request rates, latency, error rates

### Logging

- **Lambda Logs**: `/aws/lambda/{function-name}`
- **SageMaker Logs**: `/aws/sagemaker/TrainingJobs`
- **Step Functions**: Execution history and state transitions
- **API Gateway**: Request/response logging (configurable)

## 🛠️ Development

### Local Development

1. **Run Web App Locally**
   ```bash
   cd webapp
   npm install
   node server.js
   ```

2. **Test Lambda Functions**
   ```bash
   cd modules/lambda
   python -m pytest tests/
   ```

3. **Validate Terraform**
   ```bash
   terraform validate
   terraform plan
   ```

### Code Organization

- **Infrastructure as Code**: All AWS resources defined in Terraform
- **Modular Design**: Reusable Terraform modules for each service
- **Environment Separation**: Dev/staging/prod configurations
- **Version Control**: Git-based workflow with feature branches

## 🚨 Troubleshooting

### Common Issues

1. **SageMaker Endpoint Not Ready**
   - Check Step Functions execution status
   - Verify endpoint is "InService" in SageMaker console

2. **DynamoDB Empty Features**
   - Ensure Glue job completed successfully
   - Check CloudWatch logs for processing errors

3. **Lambda Timeout**
   - Increase timeout in Terraform configuration
   - Optimize feature queries and model inference

4. **API Gateway CORS Issues**
   - Verify CORS headers in Lambda response
   - Check browser developer console for specific errors

### Performance Optimization

- **DynamoDB**: Use composite keys for efficient queries
- **Lambda**: Optimize memory allocation based on usage patterns
- **SageMaker**: Choose appropriate instance types for load
- **CloudFront**: Configure caching for static assets

## 🔐 Security

### Best Practices Implemented

- ✅ **IAM Least Privilege**: Minimal required permissions per service
- ✅ **VPC Security Groups**: Network-level access controls
- ✅ **Encryption**: Data encrypted at rest and in transit
- ✅ **API Authentication**: Ready for OAuth/JWT integration
- ✅ **Resource Isolation**: Environment-specific resource naming

### Security Considerations

- API Gateway endpoints are currently public (add authentication for production)
- Consider VPC endpoints for enhanced security
- Enable AWS CloudTrail for audit logging
- Implement API rate limiting for production workloads

## 📈 Cost Optimization

### Cost-Saving Features

- **Serverless**: Pay only for actual usage
- **Auto-Scaling**: Resources scale down during low usage
- **Spot Instances**: Optional for batch training jobs
- **Data Lifecycle**: Automated S3 lifecycle policies

### Estimated Monthly Costs (Light Usage)

- Lambda: $5-15
- SageMaker Endpoint: $30-50
- DynamoDB: $5-10
- Kinesis: $10-20
- S3 + CloudFront: $5-15
- **Total**: ~$55-110/month

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License. See `LICENSE` file for details.

## 🙏 Acknowledgments

- AWS for providing the serverless infrastructure platform
- XGBoost team for the machine learning algorithm
- Terraform for infrastructure as code capabilities
