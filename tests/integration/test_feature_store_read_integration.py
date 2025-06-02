import os

import pytest
from google.api_core import exceptions
from google.cloud import aiplatform_v1


@pytest.mark.integration
@pytest.mark.skipif(
    not os.getenv("ENABLE_INTEGRATION_TESTS"), reason="Integration tests require ENABLE_INTEGRATION_TESTS=true"
)
class TestFeatureStoreReadIntegration:
    """Feature Store読み取りの統合テスト"""

    @pytest.fixture(autouse=True)
    def setup(self):
        """テスト環境のセットアップ"""
        self.project_id = os.getenv("PROJECT_ID", "portfolio-dex-vertex-ai-dev")
        self.region = os.getenv("REGION", "asia-northeast1")
        self.featurestore_id = os.getenv("FEATURESTORE_ID", "dex_anomaly_detection_featurestore_dev")

        # テスト実行前に環境変数を確認
        if not all([self.project_id, self.region, self.featurestore_id]):
            pytest.skip("Required environment variables not set")

    def test_read_features_direct_api(self):
        """Feature Store APIを直接使用した読み取りテスト"""
        client = aiplatform_v1.FeaturestoreOnlineServingServiceClient(
            client_options={"api_endpoint": f"{self.region}-aiplatform.googleapis.com"}
        )

        entity_type_path = client.entity_type_path(
            project=self.project_id,
            location=self.region,
            featurestore=self.featurestore_id,
            entity_type="dex_liquidity",
        )

        # pool_001の特徴量を読み取り
        request = aiplatform_v1.ReadFeatureValuesRequest(
            entity_type=entity_type_path,
            entity_id="pool_001",
            feature_selector=aiplatform_v1.FeatureSelector(
                id_matcher=aiplatform_v1.IdMatcher(ids=["volume_usd", "tvl_usd"])
            ),
        )

        try:
            response = client.read_feature_values(request=request)

            # レスポンスの検証
            assert response.entity_view.entity_id == "pool_001"
            assert len(response.header.feature_descriptors) == 2
            assert len(response.entity_view.data) == 2

            # 値の確認
            for i, feature_data in enumerate(response.entity_view.data):
                feature_name = response.header.feature_descriptors[i].id
                if feature_data and hasattr(feature_data, "value") and feature_data.value:
                    value = feature_data.value
                    if hasattr(value, "double_value"):
                        print(f"{feature_name}: {value.double_value}")
                        assert isinstance(value.double_value, float)

        except exceptions.NotFound:
            pytest.skip("Entity pool_001 not found in Feature Store")
        except Exception as e:
            pytest.fail(f"Unexpected error: {e}")

    def test_read_features_with_client_wrapper(self):
        """クライアントラッパーを使用した読み取りテスト"""
        from src.features.feature_store_client import read_features

        # 環境変数を設定
        os.environ["PROJECT_ID"] = self.project_id
        os.environ["FEATURESTORE_NAME"] = self.featurestore_id
        os.environ["REGION"] = self.region

        features = read_features(pool_id="pool_001", feature_ids=["volume_usd", "tvl_usd"], default_value=0.0)

        assert isinstance(features, dict)
        assert "volume_usd" in features
        assert "tvl_usd" in features
        assert features["volume_usd"] == 1000.0  # テストデータの値
        assert features["tvl_usd"] == 50000.0  # テストデータの値

    def test_read_nonexistent_entity(self):
        """存在しないエンティティの読み取りテスト"""
        from src.features.feature_store_client import read_features

        os.environ["PROJECT_ID"] = self.project_id
        os.environ["FEATURESTORE_NAME"] = self.featurestore_id
        os.environ["REGION"] = self.region

        features = read_features(pool_id="nonexistent_pool", feature_ids=["volume_usd"], default_value=-999.0)

        # 存在しない場合はデフォルト値が返される
        assert features["volume_usd"] == -999.0

    @pytest.mark.parametrize(
        "pool_id,expected_volume",
        [
            ("pool_001", 1000.0),
            ("pool_002", 2000.0),
        ],
    )
    def test_read_multiple_entities(self, pool_id, expected_volume):
        """複数エンティティの読み取りテスト"""
        from src.features.feature_store_client import read_features

        os.environ["PROJECT_ID"] = self.project_id
        os.environ["FEATURESTORE_NAME"] = self.featurestore_id
        os.environ["REGION"] = self.region

        features = read_features(pool_id=pool_id, feature_ids=["volume_usd"], default_value=0.0)

        assert features["volume_usd"] == expected_volume
