# [WIP] Vertex AI DEX Liquidity Anomaly Detection

分散型取引所（DEX）の流動性データを毎時収集し、Isolation Forest による異常スパイク検知を行うパイプラインです。

- Uniswap V3 / Sushiswap で流動性プールの異常スパイクを検知
- 毎時間ロックされたトークンの時価総額（TVL）と取引量を The Graph API で取得
- Isolation Forest モデルを Vertex AI Endpoint にデプロイし、リアルタイム推論可能
- CI/CD パイプラインによる自動モデルデプロイ（GitHub Actions）

## アーキテクチャ

```
┌───────────────────┐
│   Cloud Scheduler │  (0 * * * *)      # 毎時
└─────────┬─────────┘
          │ HTTP trigger
          ▼
┌───────────────────┐
│   Cloud Run Job   │  fetch_pool_data
│  (Python 3.11)    │
│  ├ The Graph API  │
│  └→ BigQuery RAW  │
└─────────┬─────────┘
          │
          ▼
┌─────────────────────────────────────────┐
│        BigQuery                         │
│  ┌─────┐    ┌─────┐    ┌───────────┐    │
│  │ RAW ├────► STG ├────► Features  │    │
│  └─────┘    └─────┘    └─────┬─────┘    │
└──────────────────────────────┼──────────┘
                               │
                   ┌───────────┴────────────┐
                   │                        │
                   ▼                        ▼
         ┌─────────────────┐      ┌────────────────┐
         │ Scheduled Query │      │ GitHub Actions │
         │ (毎時)           │      │ (CI/CD)        │
         └────────┬────────┘      └───────┬────────┘
                  │ EXPORT                │ push時
                  ▼                       ▼
         ┌─────────────────┐      ┌────────────────┐
         │ GCS (Parquet)   │      │ Model Build &  │
         └────────┬────────┘      │ Upload         │
                  │               └───────┬────────┘
                  ▼                       │
         ┌─────────────────┐              │
         │ Cloud Run Job   │              │
         │ (feature_import)│              │
         └────────┬────────┘              │
                  │                       │
                  ▼                       ▼
         ┌─────────────────┐      ┌────────────────┐
         │ Vertex AI       │      │ Vertex AI      │
         │ Feature Store   │      │ Model Registry │
         └─────────────────┘      └───────┬────────┘
                                          │
                                          ▼
                                  ┌────────────────┐
                                  │ Vertex AI      │
                                  │ Endpoint       │
                                  └───────┬────────┘
                                          │
                                          ▼
                              ┌───────────────────────┐
                              │   gcloud CLI / API    │
                              │   (Direct Access)     │
                              └───────────────────────┘
```

## デモ・API 仕様

### 推論エンドポイント

以下の Vertex AI Endpoint を使用した異常検知 API を提供しています。

### エンドポイント情報

- **プロジェクト ID**: `portfolio-dex-vertex-ai-dev`
- **リージョン**: `asia-northeast1`
- **エンドポイント名**: `dex-prediction-endpoint-dev`

### アクセス方法

```bash
# gcloud CLIを使用した予測リクエスト
gcloud ai endpoints predict dex-prediction-endpoint-dev \
  --region=asia-northeast1 \
  --json-request=@sample_request.json
```

### サンプルリクエスト

```json
{
  "instances": [
    [
      1000000.0, 5000000.0, 5000000.0, 100, 0.1, -0.05, 900000.0, 950000.0,
      50000.0, 0.2, 0.5, 14, 3
    ]
  ]
}
```

### レスポンス形式

```json
[1] // 1: 正常, -1: 異常
```

## 技術スタック

### データパイプライン

| レイヤ                        | 採用サービス                                                | 役割                                                                            |
| ----------------------------- | ----------------------------------------------------------- | ------------------------------------------------------------------------------- |
| **オーケストレーション (EL)** | **Cloud Scheduler + Cloud Run Job**                         | 1 時間ごとに The Graph API から JSONL を取得し BigQuery RAW テーブルへ `INSERT` |
| **データストレージ**          | BigQuery (RAW / STG / MART)<br>Cloud Storage (一時ファイル) | 高速クエリ・ML 向け特徴量供給                                                   |
| **特徴量ストア**              | Vertex AI Feature Store                                     | オンライン / オフライン特徴量管理                                               |
| **ML ワークフロー (ML)**      | Vertex AI Pipelines                                         | Retrain / BatchPredict 実行                                                     |
| **可視化**                    | Looker Studio + BigQuery View                               | 異常率 / KPI のダッシュボード表示                                               |

### 機械学習

- **実験管理**: Vertex AI Experiments + Tensorboard
- **モデル学習**: Vertex AI Training (Custom Container)
- **モデル管理**: Vertex AI Model Registry
- **推論**: Vertex AI Endpoints (Online) + Batch Prediction + Cloud Functions Gateway (CORS / Multi-tenant)

### インフラ・運用

- **IaC**: Terraform
- **CI/CD**: Cloud Build + GitHub Actions
- **モニタリング**: Cloud Monitoring + Vertex AI Model Monitoring
- **アラート**: Cloud Alerting + Slack Integration

### 開発環境

- **Python**: 3.11 (Poetry 管理)
- **ローカル開発**: Dev Container (VS Code)
- **実験環境**: Vertex AI Workbench
- **コンテナレジストリ**: Artifact Registry
- **パッケージ管理**: Poetry (pyproject.toml)

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

## TODO

### MLOps 機能

- [ ] 週次モデル再学習の自動化（Vertex AI Training Jobs）
- [ ] バッチ予測パイプライン（毎時異常スコア計算）

### API・統合

- [ ] Slack アラート通知（異常検知時）
- [ ] Looker Studio ダッシュボード

### 監視・運用

- [ ] Model Monitoring（データドリフト検知）
- [ ] カスタムメトリクス（Cloud Monitoring）

## ライセンス

MIT License
