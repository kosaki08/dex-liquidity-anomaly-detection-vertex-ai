"""
Isolation Forest 推論ロジックのユニットテスト
- Feature Store 依存をモックして純粋にスコア計算を検証
"""

import importlib
from unittest import mock

import numpy as np
import pytest


# モジュールをリロードするためのヘルパ
def _reload_predict():
    return importlib.reload(__import__("scripts.model.predict", fromlist=[""]))


@pytest.fixture(scope="module")
def dummy_features():
    # FEATURE_LIST と同じ 13 要素分のダミー値
    return {f"f{i}": float(i) for i in range(13)}


def test_feature_list_length():
    predict = _reload_predict()
    assert len(predict.FEATURE_LIST) == 13, "FEATURE_LIST は 13 個の特徴量で固定"


def test_predict_from_feature_store(monkeypatch, dummy_features):
    # Feature Store Client.read をモック
    monkeypatch.setitem(
        globals(),
        "src.features.feature_store_client.read",
        mock.Mock(return_value=dummy_features),
    )

    # _MODEL をダミーモデルに差し替え
    predict = _reload_predict()
    from sklearn.ensemble import IsolationForest

    dummy_model = IsolationForest(random_state=42).fit(np.random.randn(20, len(predict.FEATURE_LIST)))
    monkeypatch.setattr(predict, "_MODEL", dummy_model)

    result = predict.predict_from_feature_store("pool_dummy", threshold=0.0)

    # スキーマ検証
    assert set(result.keys()) == {"pool_id", "score", "is_anomaly"}
    assert result["pool_id"] == "pool_dummy"
    # スコアは float
    assert isinstance(result["score"], float)
