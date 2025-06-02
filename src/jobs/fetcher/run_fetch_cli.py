"""
Cloud Run Job から環境変数で渡されたパラメータを読み取り、fetch → GCS → BigQuery を実行します
"""

import logging
import os
import tempfile
from datetime import datetime, timezone
from uuid import uuid4

from google.api_core.exceptions import PreconditionFailed
from google.cloud import bigquery, storage
from google.cloud.bigquery import SchemaField

from src.data.fetcher.run_fetch import fetch_pool_data  # noqa: E402

logger = logging.getLogger(__name__)


def main() -> None:
    project_id = os.environ["PROJECT_ID"]
    env_suffix = os.environ["ENV_SUFFIX"]
    protocol = os.environ["PROTOCOL"]  # "uniswap" | "sushiswap"
    bucket = os.environ["RAW_BUCKET"]
    interval_iso = (
        os.getenv("INTERVAL_END_ISO")
        or datetime.now(timezone.utc).replace(minute=0, second=0, microsecond=0).isoformat()
    )
    dataset_prefix = os.getenv("DATASET_PREFIX", "dex")

    logger.info("job started: protocol=%s", protocol)
    # fetch → tmp JSONL
    with tempfile.TemporaryDirectory() as tmp:
        local_file = f"{tmp}/{protocol}_{interval_iso}.jsonl"
        fetch_pool_data(protocol, local_file, interval_iso)

        unique_id = uuid4().hex  # 32 桁
        gcs_path = (
            f"raw/{protocol}/{interval_iso[:10]}/{os.path.splitext(os.path.basename(local_file))[0]}_{unique_id}.jsonl"
        )
        blob = storage.Client(project=project_id).bucket(bucket).blob(gcs_path)
        try:
            blob.upload_from_filename(local_file, if_generation_match=0)
            logger.info("uploaded gs://%s/%s", bucket, gcs_path)
        except PreconditionFailed:
            logger.info("%s already exists - skipped", gcs_path)
            return

    # BigQuery RAW dataset にロード
    bq = bigquery.Client(project=project_id)
    ds = f"{dataset_prefix}_raw_{env_suffix}"
    tbl = f"{project_id}.{ds}.pool_hourly_{protocol}_v3"

    # BigQuery に既存テーブル (dex_raw_*) があるため
    # 自動検出ではなく raw(JSON) 1 カラムに固定してロード
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
        schema=[
            SchemaField("raw", "JSON", mode="REQUIRED"),
            SchemaField("pool_id", "STRING", mode="REQUIRED"),
            SchemaField("dex_protocol", "STRING", mode="REQUIRED"),
            SchemaField("hour_ts", "TIMESTAMP", mode="REQUIRED"),
            SchemaField("load_ts", "TIMESTAMP", mode="REQUIRED"),  # defaultValueExpression が補完
        ],
        write_disposition="WRITE_APPEND",
        ignore_unknown_values=True,  # 将来の余分カラム無視
    )

    job = bq.load_table_from_uri(f"gs://{bucket}/{gcs_path}", tbl, job_config=job_config)
    job.result()
    logger.info("loaded %s rows into %s", job.output_rows, tbl)


if __name__ == "__main__":
    main()
