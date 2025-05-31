import logging
import os
from functools import lru_cache

import joblib
import numpy as np

from src.features.feature_store_client import read_features

FEATURE_LIST = [
    "volume_usd",
    "tvl_usd",
    "liquidity",
    "tx_count",
    "vol_rate_24h",
    "tvl_rate_24h",
    "vol_ma_6h",
    "vol_ma_24h",
    "vol_std_24h",
    "vol_tvl_ratio",
    "volume_zscore",
    "hour_of_day",
    "day_of_week",
]

logger = logging.getLogger(__name__)


@lru_cache(maxsize=1)
def get_model():
    """モデルの遅延ロードとキャッシュ"""
    model_path = os.getenv("MODEL_PATH", "/model/iforest.joblib")
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Model file not found: {model_path}")

    logger.info(f"Loading model from: {model_path}")
    return joblib.load(model_path)


def predict_from_feature_store(
    pool_id: str,
    threshold: float = 3.0,  # score_samples の Z-score 目安
    default_feature_value: float = 0.0,
) -> dict:
    """
    Feature Storeから特徴量を取得して異常スコアを予測

    Args:
        pool_id: プールID
        threshold: 異常判定の閾値
        default_feature_value: 特徴量が取得できない場合のデフォルト値

    Returns:
        予測結果のディクショナリ
    """
    try:
        # Feature Storeから特徴量取得
        features = read_features(pool_id, FEATURE_LIST, default_value=default_feature_value)

        # 特徴量ベクトルを構築（順序を保証）
        feature_vector = np.array([features.get(fname, default_feature_value) for fname in FEATURE_LIST]).reshape(1, -1)

        # モデル取得と予測
        model = get_model()

        # Isolation Forestの場合、score_samples()が異常スコアを返す
        # 負の値が返されるので、正に変換（大きいほど異常）
        score = float(-model.score_samples(feature_vector)[0])  # 高いほど異常
        is_anomaly = score >= threshold

        result = {
            "pool_id": pool_id,
            "score": score,
            "is_anomaly": is_anomaly,
            "threshold": threshold,
            "features_used": len(features),
            "features_missing": len(FEATURE_LIST) - len(features),
        }

        logger.info(f"Prediction for pool_id '{pool_id}': score={score:.4f}, is_anomaly={is_anomaly}")

        return result

    except Exception as e:
        logger.error(f"Prediction failed for pool_id '{pool_id}': {e}")
        # エラー時はデフォルトレスポンスを返す
        return {"pool_id": pool_id, "score": 0.0, "is_anomaly": False, "error": str(e), "threshold": threshold}
