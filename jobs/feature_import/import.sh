#!/usr/bin/env bash
set -euo pipefail

# Cloud SDK デフォルトリージョンを設定
gcloud config set ai/region "${REGION}"

# ファイルが1つも無ければ何もせず終了
if ! gsutil -q stat "${GCS_PATH}"; then
  echo "no files to import - exit 0"
  exit 0
fi

# フィールドパスを指定
FIELD_PATH="stats.entityCount"

# インポート前の行数を記録
BEFORE_COUNT=$(gcloud ai featurestore entity-types describe dex_liquidity \
  --featurestore="${FEATURESTORE_ID}" \
  --region="${REGION}" \
  --format="value(${FIELD_PATH})" || echo "0")

# Feature Store へのインポート（非同期に変更）
IMPORT_JOB=$(gcloud ai featurestore entity-types import feature-values \
  --featurestore="${FEATURESTORE_ID}" \
  --entity-type=dex_liquidity \
  --region="${REGION}" \
  --import-schema-uri=gs://google-cloud-aiplatform/schema/featurestore/import_feature_values_parquet.yaml \
  --gcs-source-uri="${GCS_PATH}" \
  --feature-time-field=feature_timestamp \
  --worker-count=1 \
  --format="value(name)")

# ジョブの完了を監視（最大30分）
TIMEOUT=1800
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
  STATUS=$(gcloud ai operations describe "${IMPORT_JOB}" --format="value(done)")

  if [ "$STATUS" = "True" ]; then
    # エラーチェック
    ERROR=$(gcloud ai operations describe "${IMPORT_JOB}" --format="value(error.message)")
    if [ -n "$ERROR" ]; then
      echo "Import failed: $ERROR" >&2
      exit 1
    fi
    break
  fi
  sleep 30
  ELAPSED=$((ELAPSED + 30))
done

# タイムアウトチェック
if [ $ELAPSED -ge $TIMEOUT ]; then
  echo "Import timeout after ${TIMEOUT} seconds" >&2
  exit 1
fi

# entityCountの遅延を考慮して少し待つ
sleep 10

# インポート後の検証
AFTER_COUNT=$(gcloud ai featurestore entity-types describe dex_liquidity \
  --featurestore="${FEATURESTORE_ID}" \
  --region="${REGION}" \
  --format="value(${FIELD_PATH})" || echo "0")

echo "Import complete: before=$BEFORE_COUNT, after=$AFTER_COUNT"
