"""
Isolation Forest 推論ロジックのユニットテスト
- Feature Store 依存をモックして純粋にスコア計算を検証
"""

import os
import tempfile
from unittest.mock import patch

import joblib
import numpy as np
import pytest
from sklearn.ensemble import IsolationForest

from tests.fixtures.common import DEFAULT_FEATURES, FEATURE_LIST


@pytest.fixture
def dummy_features():
    """FEATURE_LIST と同じ 13 要素分のダミー値"""
    return DEFAULT_FEATURES.copy()  # 共通定義を使用


@pytest.fixture
def dummy_model():
    """テスト用のダミーモデル"""
    from src.models.predict import FEATURE_LIST

    X_dummy = np.random.randn(100, len(FEATURE_LIST))
    model = IsolationForest(random_state=42, contamination=0.1)
    model.fit(X_dummy)
    return model


@pytest.fixture
def temp_model_file(dummy_model):
    """一時的なモデルファイルを作成"""
    with tempfile.NamedTemporaryFile(suffix=".joblib", delete=False) as f:
        joblib.dump(dummy_model, f.name)
        yield f.name
    # クリーンアップ
    if os.path.exists(f.name):
        os.unlink(f.name)


@pytest.mark.unit
def test_feature_list_length():
    """特徴量リストの長さをテスト"""
    from src.models.predict import FEATURE_LIST as SRC_FEATURE_LIST

    # ソースコードと同じ長さであることを確認
    assert len(FEATURE_LIST) == 13, "FEATURE_LIST は 13 個の特徴量で固定"
    assert FEATURE_LIST == SRC_FEATURE_LIST, "テスト用リストがソースと一致していない"


@pytest.mark.unit
@patch("src.models.predict.read_features")
def test_predict_from_feature_store(mock_read_features, dummy_features, temp_model_file):
    """Feature Storeからの予測テスト"""
    # Feature Store のモック
    mock_read_features.return_value = dummy_features

    # モデルパスを設定
    with patch.dict(os.environ, {"MODEL_PATH": temp_model_file}):
        from src.models.predict import predict_from_feature_store

        result = predict_from_feature_store("pool_dummy", threshold=0.0)

    # スキーマ検証
    assert "pool_id" in result
    assert "score" in result
    assert "is_anomaly" in result
    assert "features_used" in result
    assert "features_missing" in result

    assert result["pool_id"] == "pool_dummy"
    assert isinstance(result["score"], float)
    assert isinstance(result["is_anomaly"], bool)
    assert result["features_used"] == 13
    assert result["features_missing"] == 0


@pytest.mark.unit
@patch("src.models.predict.read_features")
def test_predict_with_missing_features(mock_read_features, temp_model_file):
    """一部の特徴量が欠損している場合のテスト"""
    # 一部の特徴量のみ返す
    mock_read_features.return_value = {"volume_usd": 100.0, "tvl_usd": 5000.0}

    with patch.dict(os.environ, {"MODEL_PATH": temp_model_file}):
        from src.models.predict import predict_from_feature_store

        result = predict_from_feature_store("pool_dummy", threshold=0.0, default_feature_value=0.0)

    assert result["features_used"] == 2
    assert result["features_missing"] == 11


@pytest.mark.unit
@patch("src.models.predict.read_features")
def test_predict_with_exception(mock_read_features):
    """例外発生時のテスト"""
    # Feature Store で例外を発生させる
    mock_read_features.side_effect = Exception("Feature Store Error")

    # モデルファイルが存在しない状態でテスト
    with patch.dict(os.environ, {"MODEL_PATH": "/non/existent/model.joblib"}):
        from src.models.predict import predict_from_feature_store

        result = predict_from_feature_store("pool_dummy", threshold=0.0)

    assert "error" in result
    assert result["score"] == 0.0
    assert result["is_anomaly"] is False


@pytest.mark.unit
def test_get_model_caching(temp_model_file):
    """モデルのキャッシュ機能のテスト"""
    with patch.dict(os.environ, {"MODEL_PATH": temp_model_file}):
        from src.models.predict import get_model

        # キャッシュをクリア
        get_model.cache_clear()

        # 最初の呼び出し
        model1 = get_model()

        # 2回目の呼び出し（キャッシュから取得）
        model2 = get_model()

        # 同じインスタンスであることを確認
        assert model1 is model2

        # キャッシュ情報を確認
        cache_info = get_model.cache_info()
        assert cache_info.hits == 1
        assert cache_info.misses == 1


@pytest.mark.unit
def test_model_file_not_found():
    """モデルファイルが見つからない場合のテスト"""
    with patch.dict(os.environ, {"MODEL_PATH": "/non/existent/model.joblib"}):
        from src.models.predict import get_model

        # キャッシュをクリア
        get_model.cache_clear()

        with pytest.raises(FileNotFoundError, match="Model file not found"):
            get_model()


@pytest.mark.unit
def test_predict_boundary_values(temp_model_file):
    """閾値境界での動作確認"""
    with patch.dict(os.environ, {"MODEL_PATH": temp_model_file}):
        from src.models.predict import predict_from_feature_store

        # モックで境界値のスコアを返すように設定
        with patch("src.models.predict.read_features") as mock_read:
            mock_read.return_value = {fname: 1.0 for fname in FEATURE_LIST}

            # 閾値ちょうどのケース
            with patch("src.models.predict.get_model") as mock_model:
                mock_model.return_value.score_samples.return_value = [-3.0]  # scoreは3.0になる

                result = predict_from_feature_store("test_pool", threshold=3.0)
                assert result["is_anomaly"] is True  # 境界値は異常と判定

                # 境界値より少し下
                mock_model.return_value.score_samples.return_value = [-2.99]
                result = predict_from_feature_store("test_pool", threshold=3.0)
                assert result["is_anomaly"] is False
