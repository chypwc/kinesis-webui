from pyspark.sql import functions as F
from pyspark.sql.functions import when, col
from pyspark.sql.window import Window
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from pyspark.context import SparkContext
import os
import sys
from pyspark.ml.feature import VectorAssembler, StandardScaler
from pyspark.ml.functions import vector_to_array
import boto3



class FeatureEngineering:
    def __init__(self, database=None, output_bucket=None):
        """Initialize Spark context and configurations."""
        try:
            print(" Initializing Spark context...")
            self.sc = SparkContext.getOrCreate()
            self.glueContext = GlueContext(self.sc)
            self.spark = self.glueContext.spark_session
            self.job = Job(self.glueContext)
            self.database = database or '${database}'
            self.output_bucket = output_bucket or '${output_bucket}'
            print(f"✅ Spark context initialized. Database: {self.database}, Output: {self.output_bucket}")
        except Exception as e:
            print(f"❌ Error initializing Spark context: {e}")
            sys.exit(1)
        
    def load_data(self):
        """Load all required tables from Glue Catalog."""
        try:
            print("📊 Loading data from Glue Catalog...")
            self.products_df = self._load_table('products')
            print(f"✅ Loaded products: {self.products_df.count()} rows")
            
            self.orders_df = self._load_table('orders')
            print(f"✅ Loaded orders: {self.orders_df.count()} rows")
            
            self.aisles_df = self._load_table('aisles')
            print(f"✅ Loaded aisles: {self.aisles_df.count()} rows")
            
            self.departments_df = self._load_table('departments')
            print(f"✅ Loaded departments: {self.departments_df.count()} rows")
            
            self.order_products_df = self._load_table('order_products')
            print(f"✅ Loaded order_products: {self.order_products_df.count()} rows")
            
            # Clean days_since_prior_order
            self.orders_df = self.orders_df.withColumn(
                "days_since_prior_order",
                when(col("days_since_prior_order").isNull(), 0).otherwise(col("days_since_prior_order"))
            )
            
            # Filter order sets
            self.orders_prior_df = self.orders_df.filter(col("eval_set") == "prior")
            self.train_orders_df = self.orders_df.filter(col("eval_set") == "train").select("user_id", "order_id")
            self.test_orders_df = self.orders_df.filter(col("eval_set") == "test").select("user_id", "order_id")
            
            # Join orders with products
            self.order_products_prior = self.orders_prior_df.join(self.order_products_df, "order_id") \
                                      .select("user_id", "order_id", "order_number", 
                                              "days_since_prior_order", "product_id", 
                                              "add_to_cart_order", "reordered")
            print(f"✅ Created order_products_prior: {self.order_products_prior.count()} rows")
            
        except Exception as e:
            print(f"❌ Error loading data: {e}")
            raise
    
    def _load_table(self, table):
        """Helper to load a table from Glue Catalog."""
        try:
            print(f"📖 Loading table: {table}")
            df = self.glueContext.create_dynamic_frame.from_catalog(
                database=self.database, 
                table_name=table
            ).toDF()
            print(f"✅ Successfully loaded {table}")
            return df
        except Exception as e:
            print(f"❌ Error loading table {table}: {e}")
            raise
    
    def _save_parquet(self, df, path_suffix):
        """Save DataFrame as Parquet."""
        try:
            path = f"s3://{self.output_bucket}/features/{path_suffix}"
            print(f"💾 Saving Parquet: {path}")
            df.write.mode("overwrite").parquet(path)
            print(f"✅ Saved Parquet: {path}")
        except Exception as e:
            print(f"❌ Error saving Parquet {path}: {e}")
            raise

 

    def _save_to_dynamodb(self, df, table_name):
        """Save DataFrame to DynamoDB."""
        try:
            print(f" Saving to DynamoDB: {table_name}")
            dyf = DynamicFrame.fromDF(df, self.glueContext, table_name)
            self.glueContext.write_dynamic_frame.from_options(
                frame=dyf,
                connection_type="dynamodb",
                connection_options={
                    "dynamodb.output.tableName": table_name,
                    "dynamodb.throughput.write.percent": "0.5"
                }
            )
            print(f"✅ Saved to DynamoDB: {table_name}")
        except Exception as e:
            print(f"❌ Error saving to DynamoDB {table_name}: {e}")
            raise
    
    def _apply_standard_scaler(self, df, id_cols):
        """
        Fit a StandardScaler on the given DataFrame (excluding id_cols), 
        and return the scaled DataFrame and the fitted scaler model.
        """
        feature_cols = [col for col in df.columns if col not in id_cols]
        assembler = VectorAssembler(inputCols=feature_cols, outputCol="features_vec")
        df_vec = assembler.transform(df)
        scaler = StandardScaler(inputCol="features_vec", outputCol="features_scaled", withMean=True, withStd=True)
        scaler_model = scaler.fit(df_vec)
        df_scaled = scaler_model.transform(df_vec)
        df_scaled = df_scaled.withColumn("features_array", vector_to_array("features_scaled"))
        for i, col_name in enumerate(feature_cols):
            df_scaled = df_scaled.withColumn(col_name + "_scaled", df_scaled.features_array[i])
        scaled_col_names = [col + "_scaled" for col in feature_cols]
        return df_scaled.select(*id_cols, *scaled_col_names), scaler_model

    def _transform_standard_scaler(self, df, id_cols, scaler_model):
        """
        Transform a DataFrame using a "fitted StandardScaler" model (excluding id_cols).
        """
        feature_cols = [col for col in df.columns if col not in id_cols]
        assembler = VectorAssembler(inputCols=feature_cols, outputCol="features_vec")
        df_vec = assembler.transform(df)
        df_scaled = scaler_model.transform(df_vec)
        df_scaled = df_scaled.withColumn("features_array", vector_to_array("features_scaled"))
        for i, col_name in enumerate(feature_cols):
            df_scaled = df_scaled.withColumn(col_name + "_scaled", df_scaled.features_array[i])
        scaled_col_names = [col + "_scaled" for col in feature_cols]
        return df_scaled.select(*id_cols, *scaled_col_names)

        
    def create_product_metadata(self):
        """Create and save product metadata."""
        try:
            print("🏭 Creating product metadata...")
            products = self.products_df.join(self.aisles_df, "aisle_id") \
                                      .join(self.departments_df, "department_id")                        
            
            self._save_to_dynamodb(products, "products")
            print("✅ Saved product metadata to DynamoDB: products")
            return products
        except Exception as e:
            print(f"❌ Error creating product metadata: {e}")
            raise
    
    def create_user_features(self):
        """Create user-level features."""
        try:
            print("🏭 Creating user features...")
            # User order patterns
            user_features_1 = self.orders_prior_df.groupBy("user_id").agg(
                F.max("order_number").alias("user_orders"),
                F.sum("days_since_prior_order").alias("user_periods"),
                F.mean("days_since_prior_order").alias("user_mean_days_since_prior")
            )
            
            
            # User product patterns
            order_products_prior_flag = self.order_products_prior.withColumn(
                "reordered_flag", when(col("reordered") == 1, 1).otherwise(0)
            ).withColumn(
                "repeat_order_flag", when(col("order_number") > 1, 1).otherwise(None)
            )
            
            user_features_2 = order_products_prior_flag.groupBy("user_id").agg(
                F.count("product_id").alias("user_products"),
                F.countDistinct("product_id").alias("user_distinct_products"),
                (F.sum("reordered_flag") / F.count("repeat_order_flag")).alias("user_reorder_ratio")
            )

            user_features = user_features_1.join(user_features_2, "user_id")

            # self._save_parquet(user_features, "user_features")
            # print("✅ Saved user features to S3: user_features")
            self._save_to_dynamodb(user_features.filter(col("user_id") < 10000), "user_features")
            print("✅ Saved user features to DynamoDB: user_features")
            
            return user_features

        except Exception as e:
            print(f"❌ Error creating user features: {e}")
            raise

    
    def create_user_product_features(self):
        """Create user-product interaction features."""
        try:
            print("🏭 Creating user-product interaction features...")
            # Exclude train orders
            order_products_prior_excl_train = self.order_products_prior.join(
                self.train_orders_df, ["user_id", "order_id"], "left_anti"
            )
            
            up_features = order_products_prior_excl_train.groupBy("user_id", "product_id").agg(
                F.count("*").alias("up_order_count"),
                F.min("order_number").alias("up_first_order_number"),
                F.max("order_number").alias("up_last_order_number"),
                F.avg("add_to_cart_order").alias("up_avg_cart_position")
            )
            self._save_parquet(up_features, "up_features")
            print("✅ Saved user-product interaction features to S3: up_features")
            return up_features
            
        except Exception as e:
            print(f"❌ Error creating user-product interaction features: {e}")
            raise
    
    def create_product_features(self):
        """Create product-level features."""
        try:
            print("🏭 Creating product-level features...")
            product_seq_window = Window.partitionBy("user_id", "product_id").orderBy("order_number")
            product_seq_df = self.order_products_prior.withColumn(
                "product_seq_time", F.row_number().over(product_seq_window)
            )
            
            prd_features = product_seq_df.groupBy("product_id").agg(
                F.count("*").alias("prod_orders"),
                F.sum(when(col("reordered") == 1, 1).otherwise(0)).alias("prod_reorders"),
                F.sum(when(col("product_seq_time") == 1, 1).otherwise(0)).alias("prod_first_orders"),
                F.sum(when(col("product_seq_time") == 2, 1).otherwise(0)).alias("prod_second_orders")
            )
            # self._save_parquet(prd_features, "prd_features")
            # print("✅ Saved product-level features to S3: prd_features")
            self._save_to_dynamodb(prd_features, "product_features")
            print("✅ Saved product-level features to DynamoDB: product_features")

            return prd_features
        except Exception as e:
            print(f"❌ Error creating product-level features: {e}")
            raise

    
    
    def create_training_data(self, user_features, prd_features):
        """Create and save training dataset."""
        try:
            print("📊 Creating training dataset...")
            train_labels = self.order_products_df.join(self.train_orders_df, "order_id") \
                                               .select("user_id", "product_id", "reordered")
            
            train_df = train_labels.join(user_features, "user_id", "left") \
                                     .join(prd_features, "product_id", "left") \
                                     .fillna(0) \
                                     .select('product_id', 'user_id', 'reordered', 'user_orders', 'user_periods',
                                        'user_mean_days_since_prior', 'user_products', 'user_distinct_products',
                                        'user_reorder_ratio', 'prod_orders', 'prod_reorders',
                                        'prod_first_orders', 'prod_second_orders')

            # Fit scaler on train
            # id_cols = ['product_id', 'user_id', 'reordered']
            # train_df_scaled, scaler_model = self._apply_standard_scaler(train_df, id_cols)
            
            # self._save_parquet(train_df_scaled, "train")
            # print("✅ Saved training dataset to S3: train")

            # Save scaler_model for use elsewhere
            # self._scaler_model = scaler_model
            # self._id_cols = id_cols

            self._save_parquet(train_df, "train")
            print("✅ Saved training dataset to S3: train")
            return train_df
        except Exception as e:
            print(f"❌ Error creating training dataset: {e}")
            raise
    
    def create_test_data(self, user_features, prd_features):
        """Create and save test dataset."""
        try:
            print("📊 Creating test dataset...")
            candidates = self.order_products_prior.select("user_id", "product_id").distinct()
            test_candidates = self.test_orders_df.join(candidates, "user_id")
            
            test_features_df = test_candidates.join(user_features, "user_id", "left") \
                                             .join(prd_features, "product_id", "left") \
                                             .fillna(0) \
                                             .select('product_id', 'user_id', 'user_orders', 'user_periods',
                                        'user_mean_days_since_prior', 'user_products', 'user_distinct_products',
                                        'user_reorder_ratio', 'prod_orders', 'prod_reorders',
                                        'prod_first_orders', 'prod_second_orders')
            # Use scaler from train
            # id_cols = ['product_id', 'user_id']
            # test_df_scaled = self._transform_standard_scaler(test_features_df, id_cols, self._scaler_model)

            # self._save_parquet(test_df_scaled, "test")
            # print("✅ Saved test dataset to S3: test")

            self._save_parquet(test_features_df, "test")
            print("✅ Saved test dataset to S3: test")
            return test_features_df
        except Exception as e:
            print(f"❌ Error creating test dataset: {e}")
            raise

    def prepare_dynamodb_feature_table(self, user_features, prd_features):
        """Join user-product pairs with features and store in DynamoDB for real-time inference."""
        try:
            print("️ Creating DynamoDB lookup table...")
            user_product_df = self.order_products_prior.select("user_id", "product_id").distinct()

            # Join features
            feature_df = user_product_df.join(user_features, on="user_id", how="left") \
                                        .join(prd_features, on="product_id", how="left") \
                                        .fillna(0) \
                                        .select('product_id', 'user_id', 'user_orders', 'user_periods',
                                            'user_mean_days_since_prior', 'user_products', 'user_distinct_products',
                                            'user_reorder_ratio', 'prod_orders', 'prod_reorders',
                                            'prod_first_orders', 'prod_second_orders')

            # Use the scaler fitted on training data
            # id_cols = ['user_id', 'product_id']
            # feature_df_scaled = self._transform_standard_scaler(feature_df, id_cols, self._scaler_model)

            
            # self._save_parquet(feature_df_scaled, "user_product_features")
            # print("✅ Saved test dataset to S3: user_product_features")

            # Save to DynamoDB (limit for budget )
            self._save_to_dynamodb(feature_df.filter(col("user_id") < 10000), "user_product_features")
            print("✅ Saved user-product feature table to DynamoDB: user_product_features")

            return feature_df
        except Exception as e:
            print(f"❌ Error preparing DynamoDB lookup table: {e}")
            raise
    
    def run_pipeline(self):
        """Execute the full feature engineering pipeline."""
        try:
            print("🎯 Starting feature engineering pipeline...")
            
            self.load_data()

            # self._save_parquet(self.order_products_prior, "order_products_prior")
            
            print("🏭 Creating features...")
            # Create features
            self.create_product_metadata()
            user_features = self.create_user_features()
            # self.create_user_product_features()
            prd_features = self.create_product_features()
            
            print("📊 Creating datasets...")
            # Create datasets
            # self.create_training_data(user_features, prd_features)
            # self.create_test_data(user_features, prd_features)


            print("️ Creating DynamoDB lookup table...")
            # Create real-time lookup table in DynamoDB
            self.prepare_dynamodb_feature_table(user_features, prd_features)

            print("🎉 Feature engineering pipeline completed successfully!")
            
        except Exception as e:
            print(f"❌ Pipeline failed: {e}")
            raise

if __name__ == "__main__":
    try:
        pipeline = FeatureEngineering()
        pipeline.run_pipeline()
    except Exception as e:
        print(f"❌ Job failed: {e}")
        sys.exit(1)
