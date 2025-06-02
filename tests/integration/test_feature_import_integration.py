import sys
from pathlib import Path
from unittest.mock import Mock, patch

import pytest

# プロジェクトルートをパスに追加
proj_root = Path(__file__).resolve().parents[2]
if str(proj_root) not in sys.path:
    sys.path.append(str(proj_root))

from jobs.feature_import.feature_import import gcs_has_files, import_feature_values  # noqa: E402


@pytest.mark.unit
def test_gcs_has_files_with_files():
    """ファイルが存在する場合のテスト"""
    with patch("jobs.feature_import.feature_import.storage.Client") as mock_client:
        # モックの設定
        mock_bucket = Mock()
        mock_blob = Mock()
        mock_blobs = [mock_blob]  # イテレータをリストで模擬
        mock_bucket.list_blobs.return_value = iter(mock_blobs)
        mock_client.return_value.bucket.return_value = mock_bucket

        result = gcs_has_files("gs://test-bucket/path/to/files/*")
        assert result is True

        # 呼び出しの検証
        mock_bucket.list_blobs.assert_called_once_with(prefix="path/to/files/", max_results=1)


@pytest.mark.unit
def test_gcs_has_files_empty():
    """ファイルが存在しない場合のテスト"""
    with patch("jobs.feature_import.feature_import.storage.Client") as mock_client:
        mock_bucket = Mock()
        mock_bucket.list_blobs.return_value = iter([])  # 空のイテレータ
        mock_client.return_value.bucket.return_value = mock_bucket

        result = gcs_has_files("gs://test-bucket/path/to/files/*")
        assert result is False


@pytest.mark.unit
def test_gcs_has_files_invalid_uri():
    """不正なURIの場合のテスト"""
    with patch("jobs.feature_import.feature_import.storage.Client"):
        result = gcs_has_files("invalid-uri")
        assert result is False


@pytest.mark.unit
def test_gcs_has_files_no_prefix():
    """プレフィックスがないパスの場合のテスト"""
    result = gcs_has_files("gs://bucket")
    assert result is False


@pytest.mark.unit
def test_gcs_has_files_exception():
    """例外が発生した場合のテスト"""
    with patch("jobs.feature_import.feature_import.storage.Client") as mock_client:
        mock_client.side_effect = Exception("Connection error")

        result = gcs_has_files("gs://test-bucket/path/*")
        assert result is False


@pytest.mark.unit
@patch("jobs.feature_import.feature_import.gcs_has_files")
@patch("jobs.feature_import.feature_import.aiplatform_v1.FeaturestoreServiceClient")
def test_import_feature_values_no_files(mock_client_class, mock_gcs_check):
    """ファイルが存在しない場合は何もしない"""
    mock_gcs_check.return_value = False

    # SystemExitが発生しないことを確認
    import_feature_values(
        project_id="test-project",
        region="asia-northeast1",
        featurestore_id="test-fs",
        gcs_path="gs://test-bucket/empty/*",
    )

    # Feature Store クライアントが作成されていないことを確認
    mock_client_class.assert_not_called()


@pytest.mark.unit
@patch("jobs.feature_import.feature_import.gcs_has_files")
@patch("jobs.feature_import.feature_import.aiplatform_v1")
def test_import_feature_values_success(mock_aiplatform_v1, mock_gcs_check):
    """正常なインポートのテスト"""
    # ファイル存在チェックをモック
    mock_gcs_check.return_value = True

    # オペレーションのモック
    mock_operation = Mock()
    mock_operation.operation.name = "projects/test/operations/12345"
    mock_operation.result.return_value = Mock()

    # クライアントのモック
    mock_client = Mock()
    mock_client.import_feature_values.return_value = mock_operation
    mock_client.entity_type_path.return_value = (
        "projects/test/locations/asia-northeast1/featurestores/test-fs/entityTypes/dex_liquidity"
    )

    # FeaturestoreServiceClient のモック
    mock_aiplatform_v1.FeaturestoreServiceClient.return_value = mock_client

    # ImportFeatureValuesRequest と GcsSource のモック
    mock_request = Mock()
    mock_aiplatform_v1.ImportFeatureValuesRequest.return_value = mock_request
    mock_gcs_source = Mock()
    mock_aiplatform_v1.GcsSource.return_value = mock_gcs_source

    # 実行（エラーが発生しないことを確認）
    import_feature_values(
        project_id="test-project",
        region="asia-northeast1",
        featurestore_id="test-fs",
        gcs_path="gs://test-bucket/data/*",
    )

    # 呼び出しの検証
    mock_client.import_feature_values.assert_called_once()
    mock_operation.result.assert_called_once_with(timeout=1800)


@pytest.mark.unit
@patch("jobs.feature_import.feature_import.gcs_has_files")
@patch("jobs.feature_import.feature_import.aiplatform_v1")
def test_import_feature_values_timeout(mock_aiplatform_v1, mock_gcs_check):
    """タイムアウトエラーのテスト"""
    from google.api_core import exceptions

    # ファイル存在チェックをモック
    mock_gcs_check.return_value = True

    # オペレーションのモック
    mock_operation = Mock()
    mock_operation.operation.name = "projects/test/operations/12345"
    mock_operation.result.side_effect = exceptions.DeadlineExceeded("Timeout")

    # クライアントのモック
    mock_client = Mock()
    mock_client.import_feature_values.return_value = mock_operation
    mock_client.entity_type_path.return_value = (
        "projects/test/locations/asia-northeast1/featurestores/test-fs/entityTypes/dex_liquidity"
    )

    # FeaturestoreServiceClient のモック
    mock_aiplatform_v1.FeaturestoreServiceClient.return_value = mock_client

    # ImportFeatureValuesRequest と GcsSource のモック
    mock_request = Mock()
    mock_aiplatform_v1.ImportFeatureValuesRequest.return_value = mock_request
    mock_gcs_source = Mock()
    mock_aiplatform_v1.GcsSource.return_value = mock_gcs_source

    # SystemExit が発生することを確認
    with pytest.raises(SystemExit) as exc_info:
        import_feature_values(
            project_id="test-project",
            region="asia-northeast1",
            featurestore_id="test-fs",
            gcs_path="gs://test-bucket/data/*",
        )

    assert exc_info.value.code == 1


@pytest.mark.unit
@patch("jobs.feature_import.feature_import.gcs_has_files")
@patch("jobs.feature_import.feature_import.aiplatform_v1.FeaturestoreServiceClient")
def test_import_feature_values_init_error(mock_client_class, mock_gcs_check):
    """初期化エラーのテスト"""
    # ファイル存在チェックをモック
    mock_gcs_check.return_value = True

    # クライアント作成でエラー
    mock_client_class.side_effect = Exception("Authentication error")

    # SystemExit が発生することを確認
    with pytest.raises(SystemExit) as exc_info:
        import_feature_values(
            project_id="test-project",
            region="asia-northeast1",
            featurestore_id="test-fs",
            gcs_path="gs://test-bucket/data/*",
        )

    assert exc_info.value.code == 1


@pytest.mark.unit
@patch("jobs.feature_import.feature_import.gcs_has_files")
@patch("jobs.feature_import.feature_import.aiplatform_v1")
def test_import_feature_values_import_error(mock_aiplatform_v1, mock_gcs_check):
    """インポート実行時のエラーのテスト"""
    # ファイル存在チェックをモック
    mock_gcs_check.return_value = True

    # クライアントのモック
    mock_client = Mock()
    mock_client.import_feature_values.side_effect = Exception("Import failed")
    mock_client.entity_type_path.return_value = (
        "projects/test/locations/asia-northeast1/featurestores/test-fs/entityTypes/dex_liquidity"
    )

    # FeaturestoreServiceClient のモック
    mock_aiplatform_v1.FeaturestoreServiceClient.return_value = mock_client

    # ImportFeatureValuesRequest と GcsSource のモック
    mock_request = Mock()
    mock_aiplatform_v1.ImportFeatureValuesRequest.return_value = mock_request
    mock_gcs_source = Mock()
    mock_aiplatform_v1.GcsSource.return_value = mock_gcs_source

    # SystemExit が発生することを確認
    with pytest.raises(SystemExit) as exc_info:
        import_feature_values(
            project_id="test-project",
            region="asia-northeast1",
            featurestore_id="test-fs",
            gcs_path="gs://test-bucket/data/*",
        )

    assert exc_info.value.code == 1


@pytest.mark.unit
def test_gcs_path_parsing_with_wildcard():
    """ワイルドカード付きパスの解析テスト"""
    with patch("jobs.feature_import.feature_import.storage.Client") as mock_client:
        mock_bucket = Mock()
        mock_bucket.list_blobs.return_value = iter([Mock()])
        mock_client.return_value.bucket.return_value = mock_bucket

        result = gcs_has_files("gs://bucket/path/to/files/*")
        assert result is True

        # prefix が正しく処理されているか確認
        mock_bucket.list_blobs.assert_called_with(prefix="path/to/files/", max_results=1)


@pytest.mark.unit
def test_gcs_path_parsing_without_wildcard():
    """ワイルドカードなしパスの解析テスト"""
    with patch("jobs.feature_import.feature_import.storage.Client") as mock_client:
        mock_bucket = Mock()
        mock_bucket.list_blobs.return_value = iter([Mock()])
        mock_client.return_value.bucket.return_value = mock_bucket

        result = gcs_has_files("gs://bucket/path/to/files/")
        assert result is True

        mock_bucket.list_blobs.assert_called_with(prefix="path/to/files/", max_results=1)


@pytest.mark.unit
def test_gcs_path_parsing_root_level():
    """ルートレベルのパスのテスト"""
    with patch("jobs.feature_import.feature_import.storage.Client") as mock_client:
        mock_bucket = Mock()
        mock_bucket.list_blobs.return_value = iter([Mock()])
        mock_client.return_value.bucket.return_value = mock_bucket

        result = gcs_has_files("gs://bucket/*")
        assert result is True

        mock_bucket.list_blobs.assert_called_with(prefix="", max_results=1)
