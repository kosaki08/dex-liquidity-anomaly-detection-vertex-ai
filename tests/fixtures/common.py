"""テスト用の共通定義"""

# src/models/predict.py と同じリストを定義
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

# テスト用のデフォルト特徴量値
DEFAULT_FEATURES = {name: float(i) for i, name in enumerate(FEATURE_LIST)}
