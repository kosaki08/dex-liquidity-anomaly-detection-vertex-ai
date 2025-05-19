TF_DIR      := $(CURDIR)/envs
WORKSPACE   ?=    # dev or prod
AUTOAPPROVE ?=    # CI で -auto-approve を渡す用
INIT_FLAGS  ?=    # 例: "-upgrade -reconfigure"
BACKEND_CFG := -backend-config=envs/$(WORKSPACE)/backend.conf


# サブディレクトリを指す
ENV_DIR    := $(TF_DIR)/$(WORKSPACE)

## ---------- モジュール単体テスト ----------
test-modules: ## infra/modules/* の test.sh をすべて実行
	for dir in infra/modules/*; do \
	  if [ -x $$dir/test.sh ]; then \
	    echo "▶ Testing $$dir"; \
	    (cd $$dir && ./test.sh); \
	  fi \
	done

## ---------- 一般コマンド ----------
init:  ## terraform init $(INIT_FLAGS)
	terraform init "$(BACKEND_CFG)" $(INIT_FLAGS)

plan: ## terraform plan
	terraform plan

validate: ## terraform validate
	terraform validate

apply: guard-prod ## terraform apply $(AUTOAPPROVE)
	terraform apply $(AUTOAPPROVE)

destroy: guard-prod ## terraform destroy
	terraform destroy

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
