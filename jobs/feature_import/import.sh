#!/usr/bin/env bash
set -euo pipefail

# Cloud SDK デフォルトリージョンを設定
gcloud config set ai/region "${REGION}"

# ファイルが1つも無ければ何もせず終了
if ! gsutil -q stat "${GCS_PATH}"; then
  echo "no files to import - exit 0"
  exit 0
fi

# Feature Store へのインポート
gcloud ai featurestore entity-types import feature-values \
  --featurestore="${FEATURESTORE_ID}" \
  --entity-type=dex_liquidity \
  --import-schema-uri=gs://google-cloud-aiplatform/schema/featurestore/import_feature_values_parquet.yaml \
  --gcs-source-uri="${GCS_PATH}" \
  --feature-time-field=feature_timestamp \
  --worker-count=1 \
  --sync
