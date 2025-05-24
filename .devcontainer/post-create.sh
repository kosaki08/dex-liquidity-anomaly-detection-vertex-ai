#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Vertex AIパイプライン開発環境のセットアップを開始します..."

# 1. Poetry依存関係のインストール
echo "📦 Poetryを使用してPython依存関係をインストールしています..."
poetry install --no-root --no-interaction
echo "✅ Poetry依存関係のインストールが完了しました"

# 2. gcloud CLI初期化（非対話モード）
echo "🔧 gcloud CLIを設定しています..."
gcloud config set disable_usage_reporting true
gcloud config set component_manager/disable_update_check true

# 3. プロジェクト設定
echo "🔍 プロジェクト設定を確認しています..."

# 現在のgcloudプロジェクトを取得
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")

if [ -n "${GOOGLE_CLOUD_PROJECT:-}" ]; then
  echo "環境変数からプロジェクトを設定: $GOOGLE_CLOUD_PROJECT"
  gcloud config set project "$GOOGLE_CLOUD_PROJECT"
elif [ -n "$CURRENT_PROJECT" ]; then
  echo "既存のgcloudプロジェクトを使用: $CURRENT_PROJECT"
  export GOOGLE_CLOUD_PROJECT="$CURRENT_PROJECT"
else
  echo "⚠️  プロジェクトが設定されていません。gcloud auth loginを実行してください"
  exit 1
fi

# 4. 最終メッセージ
echo "✅ 使用するプロジェクト: ${GOOGLE_CLOUD_PROJECT}"
echo "🎉 開発環境のセットアップが完了しました"
