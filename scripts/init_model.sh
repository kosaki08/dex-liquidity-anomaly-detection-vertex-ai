#!/bin/bash

set -euo pipefail

# 設定変数
MODEL_NAME="iforest"
MODEL_VERSION="${MODEL_VERSION:-v0.0.1}" # SemVer / date tag
PROJECT_ID="${1:?project id required}"
ENV_SUFFIX="${2:-dev}"
MODEL_BUCKET="${PROJECT_ID}-models-${ENV_SUFFIX}"

# スクリプトのディレクトリとリポジトリのルートを取得
SCRIPT_DIR="$(
  cd "$(dirname "$0")"
  pwd
)"
REPO_ROOT="$(
  cd "${SCRIPT_DIR}/.."
  pwd
)"

# Python環境の確認
python3 -m pip install --quiet --root .venv scikit-learn==1.4.2 joblib==1.4.2 numpy==1.26.4

# ローカルアーティファクトのビルド
OUT_DIR="vertex_artifact/${MODEL_VERSION}"
python3 "${REPO_ROOT}/scripts/train_iforest.py" --out "$OUT_DIR" --version "$MODEL_VERSION"

echo "Artifact size: $(du -sh $OUT_DIR)"

# 古い latest のバックアップ
if gsutil -q stat "gs://${MODEL_BUCKET}/${MODEL_NAME}/latest/model/model.joblib"; then
  BK="gs://${MODEL_BUCKET}/${MODEL_NAME}/legacy/backup_$(date +%Y%m%d_%H%M%S)/"
  echo "Backup existing model → ${BK}"
  gsutil -m cp -r "gs://${MODEL_BUCKET}/${MODEL_NAME}/latest/" "$BK"
fi

# 新しいバージョンの同期
echo "Sync ${MODEL_VERSION} …"
gsutil -m rsync -r "$OUT_DIR" \
  "gs://${MODEL_BUCKET}/${MODEL_NAME}/${MODEL_VERSION}/"

echo "Promote to latest/ …"
gsutil -m rsync -r -d "$OUT_DIR" \
  "gs://${MODEL_BUCKET}/${MODEL_NAME}/latest/"

echo "GCS layout:"
gsutil ls -r "gs://${MODEL_BUCKET}/${MODEL_NAME}/${MODEL_VERSION}/"

# クリーンアップ
rm -rf vertex_artifact
echo "Model initialization completed"
