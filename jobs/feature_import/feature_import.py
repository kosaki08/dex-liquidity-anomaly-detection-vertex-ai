import argparse
import logging
import os
import sys
import time

from google.api_core import exceptions
from google.cloud import aiplatform_v1, bigquery, storage

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)


def gcs_has_files(uri: str) -> bool:
    """GCSパスにファイルが存在するかチェック"""
    try:
        # プロジェクトIDを環境変数から取得（優先順位: GOOGLE_CLOUD_PROJECT → PROJECT_ID）
        project_id = os.environ.get("GOOGLE_CLOUD_PROJECT") or os.environ.get("PROJECT_ID")
        if not project_id:
            logger.error("No project ID found in environment variables")
            return False

        # gs://bucket/path/* 形式の処理
        if not uri.startswith("gs://"):
            raise ValueError(f"Invalid GCS URI: {uri}")

        path_without_prefix = uri[5:]  # "gs://" を除去
        parts = path_without_prefix.split("/", 1)

        if len(parts) < 2:
            logger.warning(f"Invalid path format: {uri}")
            return False

        bucket_name = parts[0]
        prefix = parts[1].rstrip("*")

        # プロジェクトIDを明示的に指定してクライアント作成
        client = storage.Client(project=project_id)
        bucket = client.bucket(bucket_name)

        # 最初の1件だけチェック（存在確認のみ）
        blobs = bucket.list_blobs(prefix=prefix, max_results=1)
        return any(True for _ in blobs)

    except Exception as e:
        logger.error(f"Error checking GCS files: {e}")
        return False


def import_feature_values(project_id: str, region: str, featurestore_id: str, gcs_path: str):
    """Feature Storeへのインポート実行"""
    # ファイル存在チェック
    if not gcs_has_files(gcs_path):
        logger.info("no files to import - exit 0")
        return

    dataset = None
    bq_client = None

    try:
        # 一時的なBigQueryテーブルを作成してParquetをロード
        bq_client = bigquery.Client(project=project_id)
        dataset_id = f"temp_feature_import_{int(time.time())}"
        table_id = "feature_values"

        # データセット作成
        dataset = bigquery.Dataset(f"{project_id}.{dataset_id}")
        dataset.location = region
        dataset = bq_client.create_dataset(dataset, exists_ok=True)

        # スキーマを明示的に定義
        schema = [
            bigquery.SchemaField("entity_id", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("feature_timestamp", "TIMESTAMP", mode="REQUIRED"),
            bigquery.SchemaField("volume_usd", "FLOAT64", mode="NULLABLE"),
            bigquery.SchemaField("tvl_usd", "FLOAT64", mode="NULLABLE"),
            bigquery.SchemaField("liquidity", "FLOAT64", mode="NULLABLE"),
            bigquery.SchemaField("tx_count", "INT64", mode="NULLABLE"),
            bigquery.SchemaField("vol_rate_24h", "FLOAT64", mode="NULLABLE"),
            bigquery.SchemaField("tvl_rate_24h", "FLOAT64", mode="NULLABLE"),
            bigquery.SchemaField("vol_ma_6h", "FLOAT64", mode="NULLABLE"),
            bigquery.SchemaField("vol_ma_24h", "FLOAT64", mode="NULLABLE"),
            bigquery.SchemaField("vol_std_24h", "FLOAT64", mode="NULLABLE"),
            bigquery.SchemaField("vol_tvl_ratio", "FLOAT64", mode="NULLABLE"),
            bigquery.SchemaField("volume_zscore", "FLOAT64", mode="NULLABLE"),
            bigquery.SchemaField("hour_of_day", "INT64", mode="NULLABLE"),
            bigquery.SchemaField("day_of_week", "INT64", mode="NULLABLE"),
        ]

        # Parquetファイルをロード
        table_ref = dataset.table(table_id)
        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.PARQUET,
            schema=schema,  # スキーマを明示的に指定
            write_disposition="WRITE_TRUNCATE",
        )

        load_job = bq_client.load_table_from_uri(gcs_path, table_ref, job_config=job_config)
        load_job.result()  # 完了を待つ

        logger.info(f"Loaded {load_job.output_rows} rows into BigQuery")

        # Feature Store クライアントの初期化
        client = aiplatform_v1.FeaturestoreServiceClient(
            client_options={"api_endpoint": f"{region}-aiplatform.googleapis.com"}
        )

        entity_type_path = client.entity_type_path(
            project=project_id,
            location=region,
            featurestore=featurestore_id,
            entity_type="dex_liquidity",
        )

        # 特徴量のリスト定義
        feature_ids = [
            "volume_usd",
            "tvl_usd",
            "liquidity",
            "tx_count",
            "vol_rate_24h",
            "tvl_rate_24h",
            "vol_ma_6h",
            "vol_ma_24h",
            "vol_std_24h",
            "vol_tvl_ratio",
            "volume_zscore",
            "hour_of_day",
            "day_of_week",
        ]

        # BigQueryソースを使用してインポート
        request = aiplatform_v1.ImportFeatureValuesRequest(
            entity_type=entity_type_path,
            feature_time_field="feature_timestamp",
            entity_id_field="entity_id",
            worker_count=1,
            bigquery_source=aiplatform_v1.BigQuerySource(input_uri=f"bq://{project_id}.{dataset_id}.{table_id}"),
            feature_specs=[
                aiplatform_v1.ImportFeatureValuesRequest.FeatureSpec(id=feature_id) for feature_id in feature_ids
            ],
        )

        # インポート実行
        op = client.import_feature_values(request=request)
        logger.info(f"Started import: {op.operation.name}")

        # 完了を待つ
        result = op.result(timeout=1800)

        # インポート結果の詳細をログ出力
        if hasattr(result, "imported_entity_count"):
            logger.info(f"Successfully imported {result.imported_entity_count} entities")
        if hasattr(result, "imported_feature_value_count"):
            logger.info(f"Successfully imported {result.imported_feature_value_count} feature values")

        # クリーンアップ
        logger.info("Cleaning up temporary BigQuery dataset")
        bq_client.delete_dataset(dataset, delete_contents=True)

        logger.info("Import completed successfully")

    except exceptions.DeadlineExceeded:
        logger.error("Import timeout after 1800 seconds")
        if "op" in locals():
            logger.error(f"Operation name: {op.operation.name}")
        # クリーンアップ
        if dataset and bq_client:
            try:
                bq_client.delete_dataset(dataset, delete_contents=True)
            except Exception:
                pass
        sys.exit(1)
    except Exception as e:
        logger.error(f"Import failed: {e}")
        if hasattr(e, "__class__"):
            logger.error(f"Error type: {e.__class__.__name__}")
        if hasattr(e, "details"):
            logger.error(f"Error details: {e.details}")
        # クリーンアップ
        if dataset and bq_client:
            try:
                bq_client.delete_dataset(dataset, delete_contents=True)
            except Exception:
                pass
        sys.exit(1)


def load_parquet_to_bigquery(
    bq_client, project_id: str, region: str, gcs_path: str, dataset_id: str, table_id: str
) -> int:
    """ParquetファイルをBigQueryにロードする"""
    # データセット作成
    dataset = bigquery.Dataset(f"{project_id}.{dataset_id}")
    dataset.location = region
    dataset = bq_client.create_dataset(dataset, exists_ok=True)

    # スキーマ定義
    schema = [
        bigquery.SchemaField("entity_id", "STRING", mode="REQUIRED"),
        # ... 他のフィールド
    ]

    # ロード設定
    table_ref = dataset.table(table_id)
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.PARQUET,
        schema=schema,
        write_disposition="WRITE_TRUNCATE",
    )

    # ロード実行
    load_job = bq_client.load_table_from_uri(gcs_path, table_ref, job_config=job_config)
    load_job.result()

    return load_job.output_rows


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--project_id", help="GCP Project ID")
    parser.add_argument("--region", required=True)
    parser.add_argument("--featurestore_id", required=True)
    parser.add_argument("--gcs_path", required=True)
    args = parser.parse_args()

    # project_id は環境変数からも取得可能
    project_id = args.project_id or os.environ.get("PROJECT_ID")
    if not project_id:
        logger.error("Project ID must be provided via --project_id or PROJECT_ID env var")
        sys.exit(1)

    # GCP SDK が期待する環境変数を設定（フォールバック）
    os.environ.setdefault("GOOGLE_CLOUD_PROJECT", project_id)

    import_feature_values(
        project_id=project_id, region=args.region, featurestore_id=args.featurestore_id, gcs_path=args.gcs_path
    )
