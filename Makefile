.PHONY: test test-unit test-integration test-all

test: test-unit  ## デフォルトはユニットテストのみ

test-unit:  ## ユニットテストを実行
	pytest -v -m unit

test-integration:  ## 統合テストを実行（要GCP認証）
	@echo "Running integration tests..."
	@if [ -z "$$ENABLE_INTEGRATION_TESTS" ]; then \
		echo "Set ENABLE_INTEGRATION_TESTS=true to run integration tests"; \
		exit 1; \
	fi
	pytest -v -m integration

test-all:  ## すべてのテストを実行
	ENABLE_INTEGRATION_TESTS=true pytest -v