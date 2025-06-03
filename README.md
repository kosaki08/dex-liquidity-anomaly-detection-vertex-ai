# [WIP] Vertex AI DEX Liquidity Anomaly Detection

分散型取引所（DEX）の流動性データを毎時収集し、Isolation Forest による異常スパイク検知を行うパイプラインです。

- Uniswap V3 / Sushiswap で流動性プールの異常スパイクを検知
- 毎時間ロックされたトークンの時価総額（TVL）と取引量を The Graph API で取得
- 週次で Isolation Forest モデルを再学習し、MLflow で管理・BentoML 経由で推論 API 化
- 毎時間スコアリング

## ディレクトリ構成

```text
.
├── docker/                   # Docker イメージ定義
│   ├── fetcher/              # GraphQL データ取得用
│   └── kfp/                  # Kubeflow Pipeline コンポーネント実行用
├── functions/
│   └── prediction_gateway/   # Vertex AI エンドポイント呼び出しラッパー
├── jobs/                     # バッチ処理ジョブ
│   └── feature_import/       # Feature Store インポート処理
├── models/                   # SQL モデル定義（dbt風）
│   ├── iforest/              # Isolation Forest モデルアーティファクト
│   ├── mart/                 # 特徴量作成SQL
│   └── staging/              # ステージングビュー
├── pipelines/                # Vertex AI Pipelines 定義
│   ├── components/           # 再利用可能な KFP コンポーネント
│   └── hourly_prediction.py  # 予測パイプライン
├── scripts/                  # 運用スクリプト
│   ├── model/                # モデルトレーニング
│   └── init_model.sh         # モデルアーティファクト初期化と更新
├── src/                      # ライブラリコード
│   ├── data/                 # データ取得（The Graph など）
│   ├── features/             # 特徴量管理（Vertex Feature Store）
│   └── models/               # モデル学習／推論ロジック
├── terraform/                # IaC（dev／prod 環境）
│   ├── modules/              # 再利用可能なモジュール
│   └── envs/                 # 環境固有設定
├── tests/                    # 自動テスト（unit/integration）
├── cloudbuild.yaml           # CI/CD パイプライン
└── pyproject.toml            # Poetry 依存関係
```

## 開発環境

| ツール           | バージョン | 備考                |
| ---------------- | ---------- | ------------------- |
| Python           | 3.11       | Poetry で依存管理   |
| Terraform        | ≥ 1.8      | modules に分割      |
| Google Cloud SDK | 最新       | gcloud コマンド使用 |
| Docker           | 24.x       | コンテナビルド      |

Dev Container を同梱しているため、VS Code + Docker があれば即環境を再現できます。

```bash
# VS Code で "Reopen in Container"
```

## セットアップ手順（概要）

1. **GCP プロジェクト作成 & 認証**

   ```bash
   gcloud init
   gcloud auth application-default login
   ```

2. **Terraform でインフラ構築**

   ```bash
   cd terraform
   make init WORKSPACE=dev INIT_FLAGS=-upgrade
   make apply
   ```

## ライセンス

MIT License
