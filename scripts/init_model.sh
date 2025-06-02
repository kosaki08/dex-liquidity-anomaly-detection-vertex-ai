#!/bin/bash

set -euo pipefail

# 設定変数
MODEL_NAME="iforest"
MODEL_VERSION="0.0.1-dummy"
FEATURE_LIST_JSON='["volume_usd","tvl_usd","liquidity","tx_count","vol_rate_24h","tvl_rate_24h","vol_ma_6h","vol_ma_24h","vol_std_24h","vol_tvl_ratio","volume_zscore","hour_of_day","day_of_week"]'

# 引数チェック
if [ $# -lt 1 ]; then
  echo "Usage: $0 <PROJECT_ID> [ENV_SUFFIX]"
  echo "Example: $0 my-project-id dev"
  exit 1
fi

PROJECT_ID=$1
ENV_SUFFIX=${2:-dev}
MODEL_BUCKET="${PROJECT_ID}-models"
MODEL_PATH="${MODEL_NAME}/latest/model.joblib"

echo "Initializing model for project: $PROJECT_ID ($ENV_SUFFIX)"
echo "Target: gs://${MODEL_BUCKET}/${MODEL_PATH}"

# Python環境の確認
if ! command -v python3 &>/dev/null; then
  echo "Error: python3 is required"
  exit 1
fi

# gsutil の確認
if ! command -v gsutil &>/dev/null; then
  echo "Error: gsutil is required. Please install Google Cloud SDK"
  exit 1
fi

# 依存ライブラリをインストール
echo "Installing required Python packages..."
python3 -m pip install --quiet --user --only-binary :all: scikit-learn==1.4.2 joblib==1.4.2 numpy==1.26.4

# PYTHONPATH に .local を追加
PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
export PYTHONPATH="$HOME/.local/lib/python${PYTHON_VERSION}/site-packages:${PYTHONPATH:-}"

# バケットの存在確認
echo "Checking if bucket exists..."
if ! gsutil ls "gs://${MODEL_BUCKET}" &>/dev/null; then
  echo "Error: Bucket gs://${MODEL_BUCKET} does not exist"
  echo "Please run Terraform first to create the infrastructure"
  exit 1
fi

# 既存モデルの確認
echo "Checking for existing model..."
if gsutil -q stat "gs://${MODEL_BUCKET}/${MODEL_PATH}" 2>/dev/null; then
  echo "Warning: Model already exists at gs://${MODEL_BUCKET}/${MODEL_PATH}"
  read -p "Do you want to overwrite it? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted"
    exit 0
  fi
fi

# ダミーモデルを作成
echo "Creating dummy IsolationForest model..."
python3 <<EOF
import json
import joblib
import numpy as np
from sklearn.ensemble import IsolationForest

# JSON形式の特徴量リストを読み込み
FEATURE_LIST = json.loads('''${FEATURE_LIST_JSON}''')

# ダミーデータでモデルを作成
print(f"Creating model with {len(FEATURE_LIST)} features...")
print(f"Features: {', '.join(FEATURE_LIST)}")

# より現実的なダミーデータを生成
np.random.seed(42)
n_samples = 1000
X_dummy = np.random.randn(n_samples, len(FEATURE_LIST))

# 一部の特徴量に現実的な範囲を設定
# volume_usd, tvl_usd, liquidity は正の値
X_dummy[:, 0:3] = np.abs(X_dummy[:, 0:3]) * 1000000  # USD values
# tx_count は整数
X_dummy[:, 3] = np.abs(X_dummy[:, 3].astype(int)) * 100
# hour_of_day (0-23)
X_dummy[:, -2] = np.random.randint(0, 24, n_samples)
# day_of_week (0-6)
X_dummy[:, -1] = np.random.randint(0, 7, n_samples)

# モデルを訓練
model = IsolationForest(
    n_estimators=200,
    contamination=0.1,
    random_state=42,
    n_jobs=-1
)
model.fit(X_dummy)

# メタデータを含めて保存（互換性のため辞書形式で保存）
model_data = {
    'model': model,
    'feature_names': FEATURE_LIST,
    'model_type': 'IsolationForest',
    'version': '${MODEL_VERSION}',
    'env': '${ENV_SUFFIX}',
    'training_samples': n_samples
}

# 保存
joblib.dump(model_data, 'dummy_model.joblib')
print("Dummy model created successfully")

# スコアサンプルの表示
sample_scores = model.score_samples(X_dummy[:10])
print(f"Sample anomaly scores: mean={sample_scores.mean():.4f}, std={sample_scores.std():.4f}")
print(f"Model file saved: dummy_model.joblib")
EOF

# Python実行の確認
if [ $? -ne 0 ]; then
  echo "Error: Failed to create dummy model"
  exit 1
fi

# ファイルサイズ確認
echo "Model file size: $(ls -lh dummy_model.joblib | awk '{print $5}')"

# GCS にアップロード
echo "Uploading model to GCS..."
if gsutil cp dummy_model.joblib "gs://${MODEL_BUCKET}/${MODEL_PATH}"; then
  echo "Model successfully uploaded to gs://${MODEL_BUCKET}/${MODEL_PATH}"

  # アップロード確認
  echo "Verifying upload..."
  gsutil ls -l "gs://${MODEL_BUCKET}/${MODEL_NAME}/latest/"
else
  echo "Failed to upload model"
  exit 1
fi

# クリーンアップ
rm -f dummy_model.joblib
echo "Cleanup completed"
echo "Model initialization completed!"
