TF_DIR := $(CURDIR)/envs
WORKSPACE ?= dev   # 引数が無ければ dev
AUTOAPPROVE  ?=    # CI で -auto-approve を渡す用
INIT_FLAGS ?=      # 例: "-upgrade -reconfigure"

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
	terraform -chdir=$(ENV_DIR) init $(INIT_FLAGS)

plan: ## terraform plan
	terraform -chdir=$(ENV_DIR) plan

validate: ## terraform validate
	terraform -chdir=$(ENV_DIR) validate

apply: guard-prod ## terraform apply $(AUTOAPPROVE)
	terraform -chdir=$(ENV_DIR) apply $(AUTOAPPROVE)

destroy: guard-prod ## terraform destroy
	terraform -chdir=$(ENV_DIR) destroy

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
