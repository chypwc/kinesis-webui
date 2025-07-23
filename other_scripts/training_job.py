import argparse
import os
import pandas as pd
import numpy as np
import xgboost as xgb

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--max_depth', type=int, default=7)
    parser.add_argument('--eta', type=float, default=0.2)
    parser.add_argument('--eval_metric', type=str, default='logloss,auc')
    parser.add_argument('--num_round', type=int, default=1000)
    parser.add_argument('--early_stopping_rounds', type=int, default=20)
    # Add more hyperparameters as needed
    return parser.parse_args()

def main():
    args = parse_args()

    # SageMaker sets these environment variables
    train_dir = os.environ.get('SM_CHANNEL_TRAIN', '/opt/ml/input/data/train')
    model_dir = os.environ.get('SM_MODEL_DIR', '/opt/ml/model')

    # Read all Parquet files in the input directory
    print(f"Loading training data from: {train_dir}")
    train_df = pd.read_parquet(train_dir)
    print("Loaded data shape:", train_df.shape)

    # Prepare data: label as first column, no header
    X = train_df.drop(columns=["user_id", "product_id", "reordered"])
    y = train_df["reordered"]

    dtrain = xgb.DMatrix(X, label=y)

    # Parse eval_metric (can be comma-separated)
    eval_metrics = args.eval_metric.split(',')

    # Train model
    print("Training XGBoost model...")
    params = {
        "objective": "binary:logistic",
        "max_depth": args.max_depth,
        "eta": args.eta,
        "eval_metric": eval_metrics,
    }
    model = xgb.train(
        params,
        dtrain,
        num_boost_round=args.num_round,
        early_stopping_rounds=args.early_stopping_rounds
    )
    print("Training complete.")

    # Save model artifact
    model_path = os.path.join(model_dir, "xgboost-model")
    model.save_model(model_path)
    print(f"Model saved to: {model_path}")

if __name__ == "__main__":
    main()
