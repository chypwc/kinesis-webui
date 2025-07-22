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
import joblib
from io import BytesIO
import warnings
from io import StringIO
warnings.filterwarnings("ignore", message=".*joblib will operate in serial mode.*")

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
    # Build user-product DataFrame
    df = pd.DataFrame({
        "user_id": [data["user_id"]] * len(data["product_ids"]),
        "product_id": data["product_ids"]
    })
    user_product_features_db = dynamodb.Table('user_product_features')
    user_id = data["user_id"]
    response = user_product_features_db.query(
        KeyConditionExpression=boto3.dynamodb.conditions.Key('user_id').eq(user_id)
    )
    user_product_features = convert_decimals(response['Items'])
    user_product_features = pd.DataFrame(user_product_features)

    if data.get("product_ids"):
        # Get product features
        product_ids = df["product_id"].astype(int).unique().tolist()
        request_keys = [{'product_id': {'N': str(pid)}} for pid in product_ids]
        items = batch_get_items("product_features", request_keys)
        flat_items = [flatten_ddb_item(item) for item in items]
        product_features = pd.DataFrame(flat_items)

        # Get user features
        user_ids = df["user_id"].astype(int).unique().tolist()
        request_keys = [{'user_id': {'N': str(uid)}} for uid in user_ids]
        items = batch_get_items('user_features', request_keys)
        flat_items = [flatten_ddb_item(item) for item in items]
        user_features = pd.DataFrame(flat_items)

        # Merge features
        df['user_id'] = df['user_id'].astype(str)
        df['product_id'] = df['product_id'].astype(str)
        user_features['user_id'] = user_features['user_id'].astype(str)
        product_features['product_id'] = product_features['product_id'].astype(str)
        user_product_features['user_id'] = user_product_features['user_id'].astype(str)
        user_product_features['product_id'] = user_product_features['product_id'].astype(str)

        df_merged = df.merge(user_features, on='user_id', how='left', suffixes=('', '_user'))
        df_merged = df_merged.merge(product_features, on='product_id', how='left', suffixes=('', '_product'))

        features = pd.concat([df_merged, user_product_features], axis=0)
    else:
        features = user_product_features

    # Prepare test features for prediction
    X_test = features.drop(columns=["user_id", "product_id"])
    X_test = X_test[['user_orders', 'user_periods', 'user_mean_days_since_prior',
       'user_products', 'user_distinct_products', 'user_reorder_ratio',
       'prod_orders', 'prod_reorders', 'prod_first_orders',
       'prod_second_orders']]
    print("DEBUG: X_test columns before scaling:", X_test.columns)
    
    try:
        scaler = joblib.load('scaler.pkl')
        X_test = scaler.transform(X_test)
    except Exception as e:
        print(f"Error loading scaler from S3: {e}")
        return []

    
    # Assuming X_test is a NumPy array after scaling
    # X_test_df = pd.DataFrame(X_test, columns=[
    # 'user_orders', 'user_periods',
    # 'user_mean_days_since_prior', 'user_products',
    # 'user_distinct_products', 'user_reorder_ratio',
    # 'prod_orders', 'prod_reorders',
    # 'prod_first_orders', 'prod_second_orders'
    # ])
    # print("DEBUG: X_test_df head:", X_test_df.head())
    # csv_str = X_test_df.to_csv(header=False, index=False)

    # Assuming X_test is your NumPy array
    output = StringIO()
    np.savetxt(output, X_test, delimiter=',', fmt='%f')
    csv_str = output.getvalue()
    output.close()

    
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
        'product_id': features["product_id"].values,
        'probability': probs
    })
    df_pred_sorted = df_pred.sort_values('probability', ascending=False).head(10)

    # Get product metadata
    product_ids = features["product_id"].astype(int).unique().tolist()
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
    # CORS PREFLIGHT HANDLING
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
        # ENVIRONMENT VARIABLE VALIDATION
        stream_name = os.environ['KINESIS_STREAM']

        # REQUEST BODY PARSING
        if 'body' in event:
            body = json.loads(event['body'])
        else:
            body = event

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
        recommendations = get_recommendations(body)

        # SUCCESS RESPONSE
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