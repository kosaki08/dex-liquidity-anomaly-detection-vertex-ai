import os

import pytest

from src.features.feature_store_client import read_features


@pytest.mark.integration
@pytest.mark.skipif(
    os.getenv("CI") == "true" and not os.getenv("ENABLE_INTEGRATION_TESTS"), reason="Integration tests disabled in CI"
)
class TestFeatureStoreIntegration:
    """Feature Store統合テスト"""

    @pytest.fixture(autouse=True)
    def setup_env(self, clean_env):
        """環境変数の設定"""
        clean_env.setenv("PROJECT_ID", "portfolio-dex-vertex-ai-dev")
        clean_env.setenv("FEATURESTORE_NAME", "dex_anomaly_detection_featurestore_dev")
        clean_env.setenv("REGION", "asia-northeast1")

    def test_read_features_with_default(self):
        """デフォルト値での特徴量読み取りテスト"""
        features = read_features(pool_id="test_pool_id", feature_ids=["volume_usd", "tvl_usd"], default_value=0.0)

        assert isinstance(features, dict)
        assert "volume_usd" in features
        assert "tvl_usd" in features
        assert features["volume_usd"] == 0.0
        assert features["tvl_usd"] == 0.0
