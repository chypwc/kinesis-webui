# ✅ TODO List: API Gateway → Lambda → Kinesis → Firehose → S3 Pipeline

Organized into three phases:

- **Phase 1: Basic Infrastructure Setup**
- **Phase 2: Data Flow Integration**
- **Phase 3: Testing & Hardening**

---

## 🚀 Phase 1: Basic Infrastructure Setup

> Goal: Stand up foundational AWS resources.

- [x] **Create an S3 bucket for Firehose delivery**  
       ✅ _Acceptance Criteria:_ S3 bucket exists with `force_destroy = true` and appears in the AWS Console.

- [x] **Create Kinesis Data Stream**  
       ✅ _Acceptance Criteria:_ Stream named `api-kinesis-stream` is created with 1 shard and appears in the Kinesis console.

- [x] **Create Firehose delivery stream (Kinesis → S3)**  
       ✅ _Acceptance Criteria:_ Firehose is configured with Kinesis as source and S3 as destination, with proper IAM roles.

- [x] **Create IAM roles for Lambda and Firehose**  
       ✅ _Acceptance Criteria:_ Lambda has basic and Kinesis permissions, Firehose has access to S3 and Kinesis.

---

## ⚙️ Phase 2: Data Flow Integration

> Goal: Wire services to allow full data streaming.

- [x] **Create IAM role for Lambda function**
      ✅ _Acceptance Criteria:_ Lambda has basic and Kinesis permissions
- [x] **Write Lambda function to send to Kinesis**  
       ✅ _Acceptance Criteria:_ Lambda parses JSON and sends to Kinesis via `boto3.put_record`.

- [x] **Deploy Lambda function with environment variable**  
       ✅ _Acceptance Criteria:_ Lambda is created, references the zip, and has `KINESIS_STREAM` env variable. Console test works.

- [x] **Set up API Gateway with route and integration**  
       ✅ _Acceptance Criteria:_ API Gateway `POST /submit` route connects to Lambda in proxy mode and is auto-deployed.

- [x] **Grant API Gateway permission to invoke Lambda**  
       ✅ _Acceptance Criteria:_ Lambda allows `apigateway.amazonaws.com` to invoke it. No 403/permission errors on call.

---

## 🧪 Phase 3: Testing & Hardening

> Goal: Validate and secure the full pipeline.

- [x] **Send test data via `curl` or Postman**  
       ✅ _Acceptance Criteria:_ HTTP 200 from API Gateway, data appears in CloudWatch and S3 within ~1–2 minutes.

- [ ] **Add authentication to API Gateway (Optional)**  
       ✅ _Acceptance Criteria:_ Unauthorized users get 401/403; authorized users succeed.

- [ ] **Add encryption and S3 bucket policy (Optional)**  
       ✅ _Acceptance Criteria:_ S3 uses AES256 or KMS, public access is blocked, and policy denies unknown principals.

- [ ] **Cleanup**  
       ✅ _Acceptance Criteria:_ `terraform destroy` removes all resources cleanly. No lingering costs or resources.
