resource "aws_kinesis_stream" "api_stream" {
  name             = var.stream_name
  shard_count      = var.shard_count
  retention_period = var.retention_period

  tags = {
    Name        = var.stream_name
    Environment = var.env
    Purpose     = "API data streaming"
  }
}
