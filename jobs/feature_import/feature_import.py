import argparse
import logging
import os
import sys

from google.api_core import exceptions
from google.cloud import aiplatform_v1, storage

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)


def gcs_has_files(uri: str) -> bool:
    """GCSパスにファイルが存在するかチェック"""
    try:
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

        client = storage.Client()
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

    try:
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

        # インポートリクエストの作成
        # ParquetファイルはAvroSourceとして扱われる
        request = aiplatform_v1.ImportFeatureValuesRequest(
            entity_type=entity_type_path,
            feature_time_field="feature_timestamp",
            entity_id_field="entity_id",
            worker_count=1,
            avro_source=aiplatform_v1.AvroSource(gcs_source=aiplatform_v1.GcsSource(uris=[gcs_path])),
        )

        # インポート実行
        op = client.import_feature_values(request=request)
        logger.info(f"Started import: {op.operation.name}")

        # 結果を待つ
        result = op.result(timeout=1800)

        # インポート結果の詳細をログ出力
        if hasattr(result, "imported_entity_count"):
            logger.info(f"Successfully imported {result.imported_entity_count} entities")
        if hasattr(result, "imported_feature_value_count"):
            logger.info(f"Successfully imported {result.imported_feature_value_count} feature values")

        logger.info("Import completed successfully")

    except exceptions.DeadlineExceeded:
        logger.error("Import timeout after 1800 seconds")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Import failed: {e}")
        if hasattr(e, "__class__"):
            logger.error(f"Error type: {e.__class__.__name__}")
        if hasattr(e, "details"):
            logger.error(f"Error details: {e.details}")
        sys.exit(1)


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

    import_feature_values(
        project_id=project_id, region=args.region, featurestore_id=args.featurestore_id, gcs_path=args.gcs_path
    )
