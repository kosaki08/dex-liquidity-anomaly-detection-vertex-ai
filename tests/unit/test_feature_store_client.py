import os
from unittest.mock import MagicMock, Mock, patch

import pytest

from src.features.feature_store_client import FeatureStoreConfig, read_features


@pytest.mark.unit
@patch("src.features.feature_store_client._get_config")
@patch("src.features.feature_store_client._get_client")
def test_read_features_with_mock(mock_client, mock_config):
    """モックを使用した特徴量読み取りテスト"""
    # 設定のモック
    mock_config_instance = MagicMock()
    mock_config_instance.entity_type_path = "projects/test/locations/test/featurestores/test/entityTypes/test"
    mock_config.return_value = mock_config_instance

    # レスポンスのモック
    mock_response = MagicMock()
    mock_response.header.feature_descriptors = [MagicMock(id="volume_usd"), MagicMock(id="tvl_usd")]

    # 値を持つデータオブジェクト
    data1 = MagicMock()
    data1.value.double_value = 1000.0

    data2 = MagicMock()
    data2.value.double_value = 50000.0

    mock_response.entity_view.data = [data1, data2]

    mock_client.return_value.read_feature_values.return_value = mock_response

    result = read_features("test_pool", ["volume_usd", "tvl_usd"])

    assert result["volume_usd"] == 1000.0
    assert result["tvl_usd"] == 50000.0


@pytest.mark.unit
@patch("src.features.feature_store_client._get_config")
@patch("src.features.feature_store_client._get_client")
def test_read_features_with_empty_response(mock_client, mock_config):
    """空のレスポンスでデフォルト値が返されるテスト"""
    # 設定のモック
    mock_config_instance = MagicMock()
    mock_config_instance.entity_type_path = "projects/test/locations/test/featurestores/test/entityTypes/test"
    mock_config.return_value = mock_config_instance

    # 空のレスポンスのモック
    mock_response = MagicMock()
    mock_response.header.feature_descriptors = [MagicMock(id="volume_usd"), MagicMock(id="tvl_usd")]

    # 値を持たないデータオブジェクト
    data1 = MagicMock()
    data1.value = None  # 値がない

    data2 = MagicMock()
    data2.value = None  # 値がない

    mock_response.entity_view.data = [data1, data2]

    mock_client.return_value.read_feature_values.return_value = mock_response

    result = read_features("test_pool", ["volume_usd", "tvl_usd"], default_value=0.0)

    assert result["volume_usd"] == 0.0
    assert result["tvl_usd"] == 0.0


@pytest.mark.unit
@patch("src.features.feature_store_client._get_config")
@patch("src.features.feature_store_client._get_client")
def test_read_features_with_exception(mock_client, mock_config):
    """例外発生時のテスト"""
    # 設定のモック
    mock_config_instance = MagicMock()
    mock_config_instance.entity_type_path = "projects/test/locations/test/featurestores/test/entityTypes/test"
    mock_config.return_value = mock_config_instance

    # 例外を発生させる
    mock_client.return_value.read_feature_values.side_effect = Exception("API Error")

    result = read_features("test_pool", ["volume_usd"], default_value=-1.0)

    assert result["volume_usd"] == -1.0


@pytest.mark.unit
def test_feature_store_config_with_env_vars(clean_env):
    """環境変数が設定されている場合のConfigテスト"""
    clean_env.setenv("PROJECT_ID", "test-project")
    clean_env.setenv("FEATURESTORE_NAME", "test-featurestore")
    clean_env.setenv("REGION", "us-central1")

    config = FeatureStoreConfig()

    assert config.project == "test-project"
    assert config.featurestore_name == "test-featurestore"
    assert config.region == "us-central1"


@pytest.mark.unit
def test_feature_store_config_missing_project_id():
    """PROJECT_IDが未設定の場合のエラーテスト"""
    with patch.dict(os.environ, {"FEATURESTORE_NAME": "test-featurestore"}, clear=True):
        with pytest.raises(ValueError, match="PROJECT_ID environment variable is required"):
            FeatureStoreConfig()


@pytest.mark.unit
def test_feature_store_config_missing_featurestore_name():
    """FEATURESTORE_NAMEが未設定の場合のエラーテスト"""
    with patch.dict(os.environ, {"PROJECT_ID": "test-project"}, clear=True):
        with pytest.raises(ValueError, match="FEATURESTORE_NAME environment variable is required"):
            FeatureStoreConfig()


@pytest.mark.unit
@patch("src.features.feature_store_client._get_config")
@patch("src.features.feature_store_client._get_client")
def test_read_features_int64_values(mock_client, mock_config):
    """int64型の値を正しく処理できることを確認"""
    # 設定のモック
    mock_config_instance = MagicMock()
    mock_config_instance.entity_type_path = "projects/test/locations/test/featurestores/test/entityTypes/test"
    mock_config.return_value = mock_config_instance

    # レスポンスのモック（int64_valueを返す）
    mock_response = MagicMock()
    mock_response.header.feature_descriptors = [MagicMock(id="tx_count")]

    # int64_valueのみを持つvalueオブジェクトをシミュレート
    data = MagicMock()
    value = Mock(spec=["int64_value"])  # int64_valueのみを持つ
    value.int64_value = 42

    data.value = value
    mock_response.entity_view.data = [data]

    mock_client.return_value.read_feature_values.return_value = mock_response

    result = read_features("test_pool", ["tx_count"])
    assert result["tx_count"] == 42.0  # floatに変換されることを確認


@pytest.mark.unit
@patch("src.features.feature_store_client._get_config")
@patch("src.features.feature_store_client._get_client")
def test_read_features_without_default_value(mock_client, mock_config):
    """default_value=Noneの場合の動作テスト"""
    # 設定のモック
    mock_config_instance = MagicMock()
    mock_config_instance.entity_type_path = "projects/test/locations/test/featurestores/test/entityTypes/test"
    mock_config.return_value = mock_config_instance

    # 空のレスポンス
    mock_response = MagicMock()
    mock_response.header.feature_descriptors = [MagicMock(id="volume_usd")]
    mock_response.entity_view.data = [MagicMock(value=None)]

    mock_client.return_value.read_feature_values.return_value = mock_response

    # default_valueを指定しない
    result = read_features("test_pool", ["volume_usd"])
    assert "volume_usd" not in result  # キーが存在しないことを確認
