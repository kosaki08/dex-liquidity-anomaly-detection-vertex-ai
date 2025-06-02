import os
import sys
from pathlib import Path
from unittest.mock import Mock, patch

import pytest

# プロジェクトルートをパスに追加
proj_root = Path(__file__).resolve().parents[2]
if str(proj_root) not in sys.path:
    sys.path.append(str(proj_root))

from jobs.feature_import.feature_import import gcs_has_files, import_feature_values  # noqa: E402


class TestFeatureImport:
    """Feature Import のユニットテスト"""

    def test_gcs_has_files_with_files(self):
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

    def test_gcs_has_files_empty(self):
        """ファイルが存在しない場合のテスト"""
        with patch("jobs.feature_import.feature_import.storage.Client") as mock_client:
            mock_bucket = Mock()
            mock_bucket.list_blobs.return_value = iter([])  # 空のイテレータ
            mock_client.return_value.bucket.return_value = mock_bucket

            result = gcs_has_files("gs://test-bucket/path/to/files/*")
            assert result is False

    def test_gcs_has_files_invalid_uri(self):
        """不正なURIの場合のテスト"""
        with patch("jobs.feature_import.feature_import.storage.Client"):
            result = gcs_has_files("invalid-uri")
            assert result is False

    @patch("jobs.feature_import.feature_import.gcs_has_files")
    @patch("jobs.feature_import.feature_import.aiplatform_v1.FeaturestoreServiceClient")
    def test_import_feature_values_no_files(self, mock_client, mock_gcs_check):
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
        mock_client.assert_not_called()


@patch("jobs.feature_import.feature_import.gcs_has_files")
@patch("jobs.feature_import.feature_import.bigquery.Client")
@patch("jobs.feature_import.feature_import.aiplatform_v1.FeaturestoreServiceClient")
@patch("jobs.feature_import.feature_import.load_parquet_to_bigquery")
def test_import_feature_values_with_separated_bq(
    self, mock_load_parquet, mock_fs_client_class, mock_bq_client_class, mock_gcs_check
):
    """BigQuery処理を分離したテスト"""
    # ファイル存在チェックをモック
    mock_gcs_check.return_value = True

    # BigQueryクライアント
    mock_bq_client = Mock()
    mock_bq_client_class.return_value = mock_bq_client
    mock_bq_client.delete_dataset.return_value = None

    # BigQuery処理のモック（分離した関数）
    mock_load_parquet.return_value = 2  # 2行ロード

    # Feature Storeクライアント
    mock_fs_client = Mock()
    mock_fs_client_class.return_value = mock_fs_client

    # 以下、Feature Store関連の設定...

    # 実行
    import_feature_values(
        project_id="test-project",
        region="asia-northeast1",
        featurestore_id="test-fs",
        gcs_path="gs://test-bucket/data/*",
    )

    # 検証
    mock_load_parquet.assert_called_once()
    mock_fs_client.import_feature_values.assert_called_once()
    mock_bq_client.delete_dataset.assert_called_once()

    @patch("jobs.feature_import.feature_import.gcs_has_files")
    @patch("jobs.feature_import.feature_import.aiplatform_v1.FeaturestoreServiceClient")
    def test_import_feature_values_timeout(self, mock_client_class, mock_gcs_check):
        """タイムアウトエラーのテスト"""
        from google.api_core import exceptions

        # ファイル存在チェックをモック
        mock_gcs_check.return_value = True

        # クライアントとオペレーションのモック
        mock_client = Mock()
        mock_operation = Mock()
        mock_operation.operation.name = "projects/test/operations/12345"
        mock_operation.result.side_effect = exceptions.DeadlineExceeded("Timeout")

        mock_client.import_feature_values.return_value = mock_operation
        mock_client.entity_type_path.return_value = (
            "projects/test/locations/asia-northeast1/featurestores/test-fs/entityTypes/dex_liquidity"
        )
        mock_client_class.return_value = mock_client

        # SystemExit が発生することを確認
        with pytest.raises(SystemExit) as exc_info:
            import_feature_values(
                project_id="test-project",
                region="asia-northeast1",
                featurestore_id="test-fs",
                gcs_path="gs://test-bucket/data/*",
            )

        assert exc_info.value.code == 1

    @patch("jobs.feature_import.feature_import.gcs_has_files")
    @patch("jobs.feature_import.feature_import.aiplatform_v1.FeaturestoreServiceClient")
    def test_import_feature_values_general_error(self, mock_client_class, mock_gcs_check):
        """一般的なエラーのテスト"""
        # ファイル存在チェックをモック
        mock_gcs_check.return_value = True

        # クライアントのモック
        mock_client_class.side_effect = Exception("Connection error")

        # SystemExit が発生することを確認
        with pytest.raises(SystemExit) as exc_info:
            import_feature_values(
                project_id="test-project",
                region="asia-northeast1",
                featurestore_id="test-fs",
                gcs_path="gs://test-bucket/data/*",
            )

        assert exc_info.value.code == 1


class TestGCSPathParsing:
    """GCSパス解析のテストケース"""

    def test_gcs_path_with_wildcard(self):
        """ワイルドカード付きパスの解析"""
        with patch("jobs.feature_import.feature_import.storage.Client") as mock_client:
            mock_bucket = Mock()
            mock_bucket.list_blobs.return_value = iter([Mock()])
            mock_client.return_value.bucket.return_value = mock_bucket

            result = gcs_has_files("gs://bucket/path/to/files/*")
            assert result is True

            # prefix が正しく処理されているか確認
            mock_bucket.list_blobs.assert_called_with(prefix="path/to/files/", max_results=1)

    def test_gcs_path_without_wildcard(self):
        """ワイルドカードなしパスの解析"""
        with patch("jobs.feature_import.feature_import.storage.Client") as mock_client:
            mock_bucket = Mock()
            mock_bucket.list_blobs.return_value = iter([Mock()])
            mock_client.return_value.bucket.return_value = mock_bucket

            result = gcs_has_files("gs://bucket/path/to/files/")
            assert result is True

            mock_bucket.list_blobs.assert_called_with(prefix="path/to/files/", max_results=1)

    def test_gcs_path_root_level(self):
        """ルートレベルのパス"""
        with patch("jobs.feature_import.feature_import.storage.Client") as mock_client:
            mock_bucket = Mock()
            mock_bucket.list_blobs.return_value = iter([Mock()])
            mock_client.return_value.bucket.return_value = mock_bucket

            result = gcs_has_files("gs://bucket/*")
            assert result is True

            mock_bucket.list_blobs.assert_called_with(prefix="", max_results=1)


def test_gcs_has_files_no_project_id():
    """プロジェクトIDが環境変数にない場合のテスト"""
    # 環境変数を一時的にクリア
    with patch.dict(os.environ, {}, clear=True):
        result = gcs_has_files("gs://test-bucket/path/*")
        assert result is False  # エラーにならず False を返すことを確認


def test_gcs_has_files_with_google_cloud_project():
    """GOOGLE_CLOUD_PROJECT環境変数が設定されている場合のテスト"""
    with patch.dict(os.environ, {"GOOGLE_CLOUD_PROJECT": "test-project"}):
        with patch("jobs.feature_import.feature_import.storage.Client") as mock_client:
            mock_bucket = Mock()
            mock_bucket.list_blobs.return_value = iter([Mock()])
            mock_client.return_value.bucket.return_value = mock_bucket

            result = gcs_has_files("gs://test-bucket/path/*")
            assert result is True

            # project引数が正しく渡されているか確認
            mock_client.assert_called_once_with(project="test-project")
