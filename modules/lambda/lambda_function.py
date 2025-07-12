import json
import boto3
import os
from datetime import datetime

def lambda_handler(event, context):
    """
    Lambda function to process API Gateway requests and send data to Kinesis
    """
    # Handle CORS preflight (OPTIONS) requests
    if event.get('httpMethod', event.get('requestContext', {}).get('http', {}).get('method')) == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST',
                'Access-Control-Allow-Headers': 'Content-Type',
            },
            'body': json.dumps({'message': 'CORS preflight'})
        }
    try:
        # Get the Kinesis stream name from environment variable
        stream_name = os.environ['KINESIS_STREAM']
        
        # Parse the request body
        if 'body' in event:
            body = json.loads(event['body'])
        else:
            body = event
        
        # Add timestamp to the record
        record_data = {
            **body,
            'timestamp': datetime.utcnow().isoformat(),
            'source': 'api-gateway'
        }
        
        # Convert to JSON string for Kinesis
        record_json = json.dumps(record_data)
        
        # Create Kinesis client
        kinesis_client = boto3.client('kinesis')
        
        # Send record to Kinesis
        response = kinesis_client.put_record(
            StreamName=stream_name,
            Data=record_json,
            PartitionKey=str(hash(record_json) % 1000)  # Simple partition key
        )
        
        # Return success response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST',
                'Access-Control-Allow-Headers': 'Content-Type',
            },
            'body': json.dumps({
                'message': 'Data sent to Kinesis successfully',
                'record_id': response['SequenceNumber'],
                'shard_id': response['ShardId']
            })
        }
        
    except Exception as e:
        # Return error response
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'OPTIONS,POST',
                'Access-Control-Allow-Headers': 'Content-Type',
            },
            'body': json.dumps({
                'error': str(e),
                'message': 'Failed to process request'
            })
        } 