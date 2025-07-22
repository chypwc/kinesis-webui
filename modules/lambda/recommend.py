import json
import boto3
import pandas as pd
import numpy as np
from decimal import Decimal
from sagemaker.predictor import Predictor

dynamodb = boto3.resource('dynamodb', region_name='ap-southeast-2')
dynamodb_client = boto3.client('dynamodb', region_name='ap-southeast-2')

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
    for i in range(0, len(keys), 100):
        batch = keys[i:i+100]
        response = dynamodb_client.batch_get_item(
            RequestItems={
                table_name: {
                    'Keys': batch
                }
            }
        )
        results.extend(response['Responses'][table_name])
    return results

def lambda_handler(event, context):
    # Parse input
    if 'body' in event:
        data = json.loads(event['body'])
    else:
        data = event

    # Build user-product DataFrame
    df = pd.DataFrame({
        "user_id": [data["user_id"]] * len(data["product_ids"]),
        "product_id": data["product_ids"]
    })

    # Get user-product features
    user_product_features_db = dynamodb.Table('user_product_features')
    user_id = data["user_id"]
    response = user_product_features_db.query(
        KeyConditionExpression=boto3.dynamodb.conditions.Key('user_id').eq(user_id)
    )
    user_product_features = convert_decimals(response['Items'])
    user_product_features = pd.DataFrame(user_product_features)

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

    # Prepare test features for prediction
    X_test = features.drop(columns=["user_id", "product_id"])
    X_test = X_test[['user_orders_scaled', 'user_periods_scaled',
           'user_mean_days_since_prior_scaled', 'user_products_scaled',
           'user_distinct_products_scaled', 'user_reorder_ratio_scaled',
           'prod_orders_scaled', 'prod_reorders_scaled',
           'prod_first_orders_scaled', 'prod_second_orders_scaled']]

    csv_str = X_test.to_csv(header=False, index=False)

    # Predict
    predictor = Predictor(endpoint_name='xgboost-endpoint')
    response = predictor.predict(csv_str, initial_args={'ContentType': 'text/csv'}).decode('utf-8')

    # Parse predictions
    probs = np.array([float(x) for x in response.strip().split('\n') if x])
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

    # Convert to JSON string (list of dicts)
    json_result = df_recommend.to_json(orient='records')

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json_result
    }