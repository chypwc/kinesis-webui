# =============================================================================
# Kinesis Data Stream Module for Real-time Data Processing
# =============================================================================
# This module creates a Kinesis Data Stream that acts as the central
# streaming buffer in the data pipeline. It receives data from Lambda
# and provides real-time streaming capabilities for downstream processing.
# 
# Architecture Role: Real-time Data Stream Buffer
# Data Flow: Lambda → Kinesis Stream → Firehose
# =============================================================================

# Kinesis Data Stream for real-time data processing
# This stream acts as a buffer between the API (Lambda) and Firehose
# Shards determine the throughput capacity of the stream
resource "aws_kinesis_stream" "api_stream" {
  name             = var.stream_name
  shard_count      = var.shard_count      # Number of shards for parallel processing
  retention_period = var.retention_period # How long data is kept in the stream (hours)

  tags = {
    Name        = var.stream_name
    Environment = var.env
    Purpose     = "API data streaming"
  }
}
