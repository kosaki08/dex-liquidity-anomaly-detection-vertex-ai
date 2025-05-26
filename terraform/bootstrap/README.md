### KMS とバケット

Cloud Storage バケットを CMEK で暗号化する場合は `service-<PROJECT_NUMBER>@gs-project-accounts.iam.gserviceaccount.com` に `roles/cloudkms.cryptoKeyEncrypterDecrypter` を付与する。
（dev / prod どちらの bootstrap でも自動付与される実装）

## TODO

- `${project_id}-data-${env_suffix}` バケットは`modules/network` 側で自動作成 & IAM 付与まで完了するため import 不要。
