## Terraform state のレイアウトとワークスペース運用について

- **GCS バケット** :`gs://terraform-state-portfolio-vertex-ai-dex`

  - dev → `vertex-ai/dev/dev.tfstate`
  - prod → `vertex-ai/prod/prod.tfstate`

- **default ワークスペースは使用しない**
  - `terraform workspace select dev|prod` を実行
  - コンテナ・CI では `TF_WORKSPACE` を設定しない（select で統一）

---

## 初回セットアップ (新規クローン時)

```
# backend を dev に向けて初期化
terraform init -backend-config=envs/dev/backend.conf
terraform workspace select dev || terraform workspace new dev
terraform plan
```

- **prod** 環境を触るときは同じ手順で `envs/prod/backend.conf` と `prod` を指定。
- prod 環境を使う前に bootstrap を prod で apply して SA / Workload Identity を用意しておく

### ワークスペースと SA の対応関係

```
dev   → tf-apply-dev
prod  → tf-apply-prod
```

---

## 既存リソースの取り込みフロー

1. `terraform state list` で存在を確認
2. state に無いものだけ `terraform import …`
3. `terraform plan -refresh-only` が差分ゼロになるまで繰り返し

> BigQuery Dataset、Service Account、Feature Store の import コマンド例を載せておくと実践しやすい。

## トラブルシューティング

- `Error 409 Already Exists`
  → ワークスペース／state ファイル取り違えを疑う
  → `terraform workspace show` と GCS パスを確認
