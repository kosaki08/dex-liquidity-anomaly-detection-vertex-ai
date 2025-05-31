import os

import pytest


@pytest.fixture(autouse=True)
def clear_caches():
    """各テスト前後でキャッシュをクリア"""
    # 循環参照を避けるためここでインポート
    from src.features.feature_store_client import _get_client, _get_config
    from src.models.predict import get_model

    # テスト前にクリア
    get_model.cache_clear()
    _get_client.cache_clear()
    _get_config.cache_clear()

    yield

    # テスト後にもクリア
    get_model.cache_clear()
    _get_client.cache_clear()
    _get_config.cache_clear()


@pytest.fixture
def clean_env(monkeypatch):
    """環境変数の安全な設定"""
    return monkeypatch


@pytest.fixture(autouse=True)
def reset_environment():
    """各テスト実行前後で環境をリセット"""
    # 既存の環境変数を保存
    original_env = dict(os.environ)

    yield

    # 環境変数を復元
    os.environ.clear()
    os.environ.update(original_env)
