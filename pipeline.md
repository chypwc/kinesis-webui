📡 AWS API Gateway → Kinesis → Firehose → S3 Pipeline

🧱 Overview

This Terraform project provisions a serverless streaming pipeline that captures data from an HTTP API and delivers it to an S3 bucket via Kinesis Data Streams and Firehose. It uses a direct API Gateway-to-Kinesis integration to minimize latency.

⸻

🔗 Architecture

Client (HTTP POST)
│
▼
API Gateway (REST API)
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

1. API Gateway (REST API)
   • POST /submit endpoint with full CORS support
   • Integrated directly with Kinesis PutRecord action
   • Deployed to a stage named after the environment (e.g., 'dev')

2. IAM Roles
   • API Gateway execution role:
     • Permission to kinesis:PutRecord
     • Permission to push logs to CloudWatch
   • Firehose role:
     • Permissions to read from Kinesis
     • Permissions to write to S3

3. Kinesis Data Stream
   • Name: api-kinesis-stream-${env}
   • Shard count: 1
   • Retention: 24 hours

4. Kinesis Firehose Delivery Stream
   • Source: Kinesis stream
   • Destination: S3 bucket
   • Buffer interval: 60 seconds
   • Format: Uncompressed

5. S3 Bucket
   • Name: api-kinesis-firehose-bucket-${env}
   • Receives and stores all streamed data records

⸻

🧪 Testing

✅ CURL Example

curl -X POST https://<api-id>.execute-api.<region>.amazonaws.com/dev/submit \
 -H "Content-Type: application/json" \
 -d '{"event": "signup", "user_id": 123}'

✅ Postman
• Method: POST
• URL: https://<api-id>.execute-api.<region>.amazonaws.com/dev/submit
• Headers: Content-Type: application/json
• Body:

{
"event": "signup",
"user_id": 123
}

⸻

📁 Project Files
• environments/dev/main.tf: Deploys the full pipeline for the dev environment.
• modules/*: Reusable Terraform modules for each AWS service.
• webapp/: A simple static web application for testing the pipeline.

⸻

📌 Notes
• API Gateway uses a stage per environment (e.g., /dev)
• No authentication is applied (public endpoint) — consider adding IAM, Cognito, or JWT authorizers for production
• API Gateway execution and access logs are available in CloudWatch
• Firehose buffers and delivers records in batch mode (60s or 1MB)
