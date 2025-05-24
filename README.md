# [WIP] Vertex AI DEX Liquidity Anomaly Detection

分散型取引所（DEX）の流動性データを毎時収集し、Isolation Forest による異常スパイク検知を行うパイプラインです。

- Uniswap V3 / Sushiswap で流動性プールの異常スパイクを検知
- 毎時間ロックされたトークンの時価総額（TVL）と取引量を The Graph API で取得
- 週次で Isolation Forest モデルを再学習し、MLflow で管理・BentoML 経由で推論 API 化
- 毎時間スコアリング

## ディレクトリ構成

```text
.
├── app/                 # Streamlit ダッシュボード
├── containers/          # 本番用 Dockerfile 群
│   ├── base/
│   ├── training/
│   └── serving/
├── notebooks/           # EDA・実験用 Notebook
├── pipelines/           # Vertex AI Pipelines 定義
│   ├── components/      # 再利用可能な KFP コンポーネント
│   ├── weekly_retrain.py
│   └── hourly_prediction.py
├── src/                 # ライブラリコード
│   ├── data/            # データ取得（The Graph など）
│   ├── features/        # 特徴量生成
│   ├── models/          # モデル学習／推論ロジック
│   └── utils/           # 監視ユーティリティ
├── terraform/           # IaC（dev／prod ワークスペース）
│   ├── modules/
│   └── environments/
├── tests/               # unit / integration / e2e
├── .github/workflows/   # CI（Test → Build → Deploy）
├── cloudbuild.yaml      # Cloud Build パイプライン
└── pyproject.toml       # Poetry 設定
```

## 開発環境

| ツール              | バージョン | 備考            |
| ---------------- | ----- | ------------- |
| Python           | 3.11  | Poetry で依存管理  |
| Terraform        | ≥ 1.8 | modules に分割   |
| Google Cloud SDK | 最新    | gcloud コマンド使用 |
| Docker           | 24.x  | コンテナビルド       |

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
