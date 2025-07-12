"""
AWS Lambda Function for Kinesis Data Pipeline
============================================

This Lambda function processes HTTP requests from API Gateway and forwards
data to Amazon Kinesis Data Streams for real-time processing.

Data Flow:
API Gateway → Lambda → Kinesis → Firehose → S3

Features:
- CORS support for web application requests
- JSON payload validation and processing
- Automatic timestamp addition
- Error handling with detailed responses
- Kinesis record creation with partition key

Environment Variables:
- KINESIS_STREAM: Name of the target Kinesis stream

Author: AWS Kinesis Pipeline Team
"""

import json
import boto3
import os
from datetime import datetime

def lambda_handler(event, context):
    """
    Main Lambda function handler for processing API Gateway requests.
    
    Args:
        event (dict): API Gateway event containing HTTP request data
        context (object): Lambda context object with runtime information
    
    Returns:
        dict: HTTP response with status code, headers, and body
    
    Expected Event Structure:
    {
        "body": "{\"user_id\": 123, \"product_ids\": [\"P1\"], \"event\": \"add_to_cart\"}",
        "httpMethod": "POST",
        "headers": {"Content-Type": "application/json"}
    }
    """
    
    # =============================================================================
    # CORS PREFLIGHT HANDLING
    # =============================================================================
    # Handle OPTIONS requests for CORS preflight from web browsers
    # This allows the web application to make cross-origin requests
    if event.get('httpMethod', event.get('requestContext', {}).get('http', {}).get('method')) == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',           # Allow all origins
                'Access-Control-Allow-Methods': 'OPTIONS,POST', # Allowed HTTP methods
                'Access-Control-Allow-Headers': 'Content-Type', # Allowed headers
            },
            'body': json.dumps({'message': 'CORS preflight'})
        }
    
    try:
        # =============================================================================
        # ENVIRONMENT VARIABLE VALIDATION
        # =============================================================================
        # Get the Kinesis stream name from environment variable
        # This allows the same Lambda function to work with different streams
        stream_name = os.environ['KINESIS_STREAM']
        
        # =============================================================================
        # REQUEST BODY PARSING
        # =============================================================================
        # Parse the request body from API Gateway event
        # API Gateway sends the body as a string, so we need to parse it
        if 'body' in event:
            body = json.loads(event['body'])
        else:
            # Fallback for direct Lambda invocation (testing)
            body = event
        
        # =============================================================================
        # DATA ENRICHMENT
        # =============================================================================
        # Add metadata to the record for tracking and processing
        # - timestamp: When the record was processed
        # - source: Identifies this as coming from API Gateway
        record_data = {
            **body,                                    # Original payload
            'timestamp': datetime.utcnow().isoformat(), # ISO format timestamp
            'source': 'api-gateway'                    # Source identifier
        }
        
        # =============================================================================
        # KINESIS RECORD PREPARATION
        # =============================================================================
        # Convert the enriched data to JSON string for Kinesis
        # Kinesis requires string data, not objects
        record_json = json.dumps(record_data)
        
        # =============================================================================
        # KINESIS CLIENT INITIALIZATION
        # =============================================================================
        # Create boto3 client for Kinesis operations
        # Uses default AWS credentials from Lambda execution role
        kinesis_client = boto3.client('kinesis')
        
        # =============================================================================
        # KINESIS RECORD CREATION
        # =============================================================================
        # Send record to Kinesis Data Stream
        # - StreamName: Target Kinesis stream
        # - Data: JSON string of the record
        # - PartitionKey: Simple hash-based partition key for shard distribution
        response = kinesis_client.put_record(
            StreamName=stream_name,
            Data=record_json,
            PartitionKey=str(hash(record_json) % 1000)  # Simple partition key
        )
        
        # =============================================================================
        # SUCCESS RESPONSE
        # =============================================================================
        # Return success response with Kinesis record details
        # - statusCode: 200 for success
        # - headers: CORS headers for web application
        # - body: JSON response with record details
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',           # CORS: Allow all origins
                'Access-Control-Allow-Methods': 'OPTIONS,POST', # CORS: Allowed methods
                'Access-Control-Allow-Headers': 'Content-Type', # CORS: Allowed headers
            },
            'body': json.dumps({
                'message': 'Data sent to Kinesis successfully',
                'record_id': response['SequenceNumber'],      # Kinesis sequence number
                'shard_id': response['ShardId']              # Kinesis shard ID
            })
        }
        
    except Exception as e:
        # =============================================================================
        # ERROR HANDLING
        # =============================================================================
        # Catch and handle any errors during processing
        # - JSON parsing errors
        # - Kinesis connection errors
        # - Environment variable errors
        # - General runtime errors
        
        # Return error response with details
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',           # CORS headers even for errors
                'Access-Control-Allow-Methods': 'OPTIONS,POST',
                'Access-Control-Allow-Headers': 'Content-Type',
            },
            'body': json.dumps({
                'error': str(e),                             # Error message
                'message': 'Failed to process request'        # User-friendly message
            })
        } 