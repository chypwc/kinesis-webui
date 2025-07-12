📡 AWS API Gateway → Lambda → Kinesis → Firehose → S3 Pipeline

🧱 Overview

This Terraform project provisions a serverless streaming pipeline that captures data from an HTTP API and delivers it to an S3 bucket via Kinesis Data Streams and Firehose.

⸻

🔗 Architecture

Client (HTTP POST)
│
▼
API Gateway (HTTP API)
│
▼
Lambda Function (processes payload)
│
▼
Kinesis Data Stream (receives record)
│
▼
Kinesis Firehose Delivery Stream
│
▼
Amazon S3 Bucket (stores raw data)

⸻

🚀 Components

1. API Gateway (HTTP API)
   • POST /submit endpoint
   • Integrated with Lambda using AWS_PROXY mode
   • Auto-deployed stage: $default

2. Lambda Function
   • Runtime: Python 3.9
   • Triggered by API Gateway
   • Uses boto3 to put data into Kinesis
   • Has an environment variable for the stream name

3. IAM Roles
   • Lambda execution role:
   • Basic execution (AWSLambdaBasicExecutionRole)
   • Permission to kinesis:PutRecord
   • Firehose role:
   • Permissions to read from Kinesis
   • Permissions to write to S3

4. Kinesis Data Stream
   • Name: api-kinesis-stream
   • Shard count: 1
   • Retention: 24 hours

5. Kinesis Firehose Delivery Stream
   • Source: Kinesis stream
   • Destination: S3 bucket
   • Buffer interval: 60 seconds
   • Format: Uncompressed

6. S3 Bucket
   • Name: api-kinesis-firehose-bucket
   • Receives and stores all streamed data records

⸻

🧪 Testing

✅ CURL Example

curl -X POST https://<api-id>.execute-api.ap-southeast-2.amazonaws.com/submit \
 -H "Content-Type: application/json" \
 -d '{"event": "signup", "user_id": 123}'

✅ Postman
• Method: POST
• URL: https://<api-id>.execute-api.ap-southeast-2.amazonaws.com/submit
• Headers: Content-Type: application/json
• Body:

{
"event": "signup",
"user_id": 123
}

⸻

📁 Project Files
• main.tf: All infrastructure resources
• lambda_function.py: Lambda code to push records to Kinesis
• lambda_function_payload.zip: Zipped Lambda deployment package

⸻

📌 Notes
• API Gateway uses $default stage and auto-deploy
• No authentication is applied (public endpoint) — consider adding IAM, Cognito, or JWT authorizers for production
• Lambda logs are automatically available in CloudWatch
• Firehose buffers and delivers records in batch mode (60s or 1MB)
