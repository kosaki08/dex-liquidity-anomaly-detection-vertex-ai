TF_DIR      := $(CURDIR)/envs
# 引数が無ければ dev
WORKSPACE ?= dev
# CI で -auto-approve を渡す用
AUTOAPPROVE ?=
# 例: "-upgrade -reconfigure"
INIT_FLAGS  ?=
# バックエンド設定ファイル
BACKEND_CFG := -backend-config=envs/$(WORKSPACE)/backend.conf
# 変数ファイル
VAR_FILE := envs/$(WORKSPACE)/terraform.tfvars

.PHONY: local-dev

# ---------- モジュール単体テスト ----------
test-modules: ## terraform/modules/* の test.sh をすべて実行
	for dir in terraform/modules/*; do \
	  if [ -x $$dir/test.sh ]; then \
	    echo "▶ Testing $$dir"; \
	    (cd $$dir && ./test.sh); \
	  fi \
	done
	

## ---------- ローカル開発 ----------
local-dev:  ## ローカル開発環境での認証設定: ADC (Application Default Credentials) でのimpersonation設定
	gcloud auth application-default login --impersonate-service-account=tf-apply-dev@$(PROJECT_ID).iam.gserviceaccount.com

# ---------- 一般コマンド ----------
init:  ## terraform init $(INIT_FLAGS)
	terraform init $(BACKEND_CFG) $(INIT_FLAGS)
	terraform workspace select $(WORKSPACE) || terraform workspace new $(WORKSPACE)

plan: ## terraform plan
	terraform plan -var-file="$(VAR_FILE)"

validate: ## terraform validate
	terraform validate

apply: guard-prod ## terraform apply $(AUTOAPPROVE)
	terraform apply -var-file="$(VAR_FILE)" $(AUTOAPPROVE)

destroy: guard-prod ## terraform destroy
	terraform destroy -var-file="$(VAR_FILE)"

help:  ## ヘルプを表示
	@grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?##"}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

## ---------- 保護ロジック ----------
# prod だけは確認プロンプトを必須に
guard-prod:
ifeq ($(WORKSPACE),prod)
	@read -p "⚠️  本当に PROD に対して操作しますか? (yes/no) " ans; \
	[ "$$ans" = "yes" ] || (echo "中断しました" && exit 1)
endif
