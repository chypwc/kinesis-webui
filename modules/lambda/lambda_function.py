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
import pandas as pd
import numpy as np
from decimal import Decimal
import os
from datetime import datetime

dynamodb = boto3.resource('dynamodb', region_name='ap-southeast-2')
dynamodb_client = boto3.client('dynamodb', region_name='ap-southeast-2')
runtime = boto3.client('runtime.sagemaker')

ENDPOINT_NAME = os.environ['ENDPOINT_NAME']

# def load_scaler_from_s3(bucket, key, local_path='scaler.pkl'):
#     s3 = boto3.client('s3')
#     obj = s3.get_object(Bucket=bucket, Key=key)
#     scaler = joblib.load(BytesIO(obj['Body'].read()))
#     return scaler
    
def convert_decimals(obj):
    if isinstance(obj, list):
        return [convert_decimals(i) for i in obj]
    elif isinstance(obj, dict):
        return {k: convert_decimals(v) for k, v in obj.items()}
    elif isinstance(obj, Decimal):
        return int(obj) if obj % 1 == 0 else float(obj)
    else:
        return obj

def flatten_ddb_item(item):
    return {k: list(v.values())[0] for k, v in item.items()}

def batch_get_items(table_name, keys):
    results = []
    keys_to_get = list(keys)
    while keys_to_get:
        batch = keys_to_get[:100]
        request = {table_name: {'Keys': batch}}
        response = dynamodb_client.batch_get_item(RequestItems=request)
        results.extend(response['Responses'].get(table_name, []))
        unprocessed = response.get('UnprocessedKeys', {}).get(table_name, {}).get('Keys', [])
        keys_to_get = unprocessed + keys_to_get[100:]
    return results

def get_recommendations(data):
    print(f"🎯 get_recommendations called with data: {json.dumps(data) if isinstance(data, dict) else str(data)}")
    
    try:
        # Validate input data
        if not isinstance(data, dict):
            raise ValueError(f"Expected dict, got {type(data)}")
        
        if "user_id" not in data:
            raise ValueError("Missing 'user_id' in request data")
        
        user_id = data["user_id"]
        product_ids = data["product_ids"]
        print(f"👤 Processing user_id: {user_id}, product_ids: {product_ids}")
        
        # # Build user-product DataFrame
        # df = pd.DataFrame({
        #     "user_id": [user_id] * len(product_ids),
        #     "product_id": product_ids
        # })
        # print(f"📊 Created DataFrame with shape: {df.shape}")
        
        # Query DynamoDB for user features
        print("🔍 Querying DynamoDB for user features...")
        user_product_features_db = dynamodb.Table('user_product_features')
        response = user_product_features_db.query(
            KeyConditionExpression=boto3.dynamodb.conditions.Key('user_id').eq(user_id)
        )
        print(f"📥 DynamoDB response: {len(response['Items'])} items found")
        
        if not response['Items']:
            print(f"⚠️ No features found for user_id {user_id}")
            return []
        
        user_product_features = convert_decimals(response['Items'])
        user_product_features = pd.DataFrame(user_product_features)
        print(f"📊 Features DataFrame shape: {user_product_features.shape}, columns: {list(user_product_features.columns)}")
    
    except Exception as e:
        print(f"❌ Error in get_recommendations setup: {str(e)}")
        raise


    # Prepare test features for prediction
    X_test = user_product_features.drop(columns=["user_id", "product_id"])
    X_test = X_test[['user_orders_scaled', 'user_periods_scaled', 'user_mean_days_since_prior_scaled', 
                    'user_products_scaled', 'user_distinct_products_scaled', 'user_reorder_ratio_scaled', 
                    'prod_orders_scaled', 'prod_reorders_scaled', 'prod_first_orders_scaled', 'prod_second_orders_scaled']]
    print("DEBUG: X_test columns before scaling:", X_test.columns)
    
    # Convert DataFrame to CSV string for SageMaker endpoint
    csv_rows = []
    for _, row in X_test.iterrows():
        csv_rows.append(','.join(str(x) for x in row.values))
    csv_str = '\n'.join(csv_rows)
    
    print("DEBUG: CSV string for SageMaker endpoint (first 200 chars):", csv_str[:200])

    try:
        # Predict using boto3 SageMaker runtime
        response = runtime.invoke_endpoint(
            EndpointName=ENDPOINT_NAME,
            ContentType='text/csv',
            Body=csv_str
        )
        response_body = response['Body'].read().decode('utf-8')
    except Exception as e:
        print(f"Error invoking SageMaker endpoint: {e}")
        return []

    # Parse predictions
    probs = np.array([float(x) for x in response_body.strip().split('\n') if x])
    df_pred = pd.DataFrame({
        'product_id': user_product_features["product_id"].values,
        'probability': probs
    })
    df_pred_sorted = df_pred.sort_values('probability', ascending=False).head(10)

    # Get product metadata
    product_ids = user_product_features["product_id"].astype(int).unique().tolist()
    request_keys = [{'product_id': {'N': str(pid)}} for pid in product_ids]
    items = batch_get_items("products", request_keys)
    flat_items = [flatten_ddb_item(item) for item in items]
    products_df = pd.DataFrame(flat_items)

    df_pred_sorted['product_id'] = df_pred_sorted['product_id'].astype(str)
    products_df['product_id'] = products_df['product_id'].astype(str)

    df_recommend = pd.merge(
        df_pred_sorted,
        products_df[['product_id', 'product_name', 'department', 'aisle']],
        on='product_id',
        how='left'
    )

    df_recommend = df_recommend[['product_id', 'probability', 'product_name', 'department', 'aisle']]

    # Return as a list of dicts
    return df_recommend.to_dict(orient='records')



def lambda_handler(event, context):
    print(f"🚀 Lambda function started. Event: {json.dumps(event)}")
    print(f"🔍 Context: {context}")
    
    # CORS PREFLIGHT HANDLING
    if event.get('httpMethod', event.get('requestContext', {}).get('http', {}).get('method')) == 'OPTIONS':
        print("✅ CORS preflight request handled")
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
        print("🔧 Starting main processing...")
        
        # ENVIRONMENT VARIABLE VALIDATION
        stream_name = os.environ.get('KINESIS_STREAM')
        endpoint_name = os.environ.get('ENDPOINT_NAME')
        print(f"📋 Environment variables - KINESIS_STREAM: {stream_name}, ENDPOINT_NAME: {endpoint_name}")
        
        if not stream_name:
            raise ValueError("KINESIS_STREAM environment variable not set")
        if not endpoint_name:
            raise ValueError("ENDPOINT_NAME environment variable not set")

        # REQUEST BODY PARSING
        if 'body' in event:
            print("📥 Parsing JSON body from event")
            body = json.loads(event['body'])
        else:
            print("📥 Using event as body directly")
            body = event
            
        print(f"📊 Parsed body: {json.dumps(body)}")

        # DATA ENRICHMENT
        record_data = {
            **body,
            'timestamp': datetime.utcnow().isoformat(),
            'source': 'api-gateway'
        }
        record_json = json.dumps(record_data)

        # KINESIS CLIENT INITIALIZATION
        kinesis_client = boto3.client('kinesis')
        response = kinesis_client.put_record(
            StreamName=stream_name,
            Data=record_json,
            PartitionKey=str(hash(record_json) % 1000)
        )

        # Get recommendations (will return [] if product_ids is missing or empty)
        print("🤖 Starting recommendation generation...")
        try:
            recommendations = get_recommendations(body)
            print(f"✅ Generated {len(recommendations)} recommendations")
        except Exception as rec_error:
            print(f"❌ Error in get_recommendations: {rec_error}")
            print(f"📚 Traceback: {str(rec_error.__class__.__name__)}: {str(rec_error)}")
            recommendations = []  # Return empty recommendations on error

        # SUCCESS RESPONSE
        print("✅ Sending success response")
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
                'shard_id': response['ShardId'],
                'recommendations': recommendations
            })
        }

    except Exception as e:
        print(f"❌ Lambda function error: {str(e)}")
        print(f"📚 Error type: {str(e.__class__.__name__)}")
        import traceback
        print(f"📚 Full traceback: {traceback.format_exc()}")
        
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
                'error_type': str(e.__class__.__name__),
                'message': 'Failed to process request'
            })
        } 