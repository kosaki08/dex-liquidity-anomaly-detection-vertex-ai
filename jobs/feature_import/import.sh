#!/usr/bin/env bash
set -euo pipefail

# 環境変数のバリデーション
# PROJECT_ID
if [ -z "${PROJECT_ID:-}" ]; then
  echo "Error: PROJECT_ID is not set" >&2
  exit 1
fi

# FEATURESTORE_ID
if [ -z "${FEATURESTORE_ID:-}" ]; then
  echo "Error: FEATURESTORE_ID is not set" >&2
  exit 1
fi

# GCS_PATH
if [ -z "${GCS_PATH:-}" ]; then
  echo "Error: GCS_PATH is not set" >&2
  exit 1
fi

# REGION
if [ -z "${REGION:-}" ]; then
  echo "Error: REGION is not set" >&2
  exit 1
fi

# PROJECT_ID は環境変数から Python に渡される
# Python スクリプトを実行
exec python /usr/local/bin/feature_import.py \
  --featurestore_id "${FEATURESTORE_ID}" \
  --gcs_path "${GCS_PATH}" \
  --region "${REGION}"
