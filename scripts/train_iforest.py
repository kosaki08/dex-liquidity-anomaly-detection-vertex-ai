import argparse
import json
import logging
from pathlib import Path

import joblib
import numpy as np
from sklearn.ensemble import IsolationForest

FEATURES = [
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


def main(out_dir: Path, version: str):
    """モデルを生成します。"""
    logger.info(f"Generate model → {out_dir}")
    n, d = 1000, len(FEATURES)
    X = np.random.randn(n, d)
    X[:, 0:3] = np.abs(X[:, 0:3]) * 1_000_000
    X[:, 3] = np.abs(X[:, 3]).astype(int) * 100
    X[:, -2] = np.random.randint(0, 24, n)
    X[:, -1] = np.random.randint(0, 7, n)

    model = IsolationForest(n_estimators=200, contamination=0.1, random_state=42)
    model.fit(X)

    model_path = out_dir / "model.joblib"
    model_path.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(model, model_path)

    meta = {"feature_names": FEATURES, "model_type": "IsolationForest", "version": version, "training_samples": n}
    schema = out_dir / "schema"
    schema.mkdir(exist_ok=True)
    (schema / "metadata.json").write_text(json.dumps(meta, indent=2))
    logger.info("Artifact ready")


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--out", required=True, help="output root dir")
    p.add_argument("--version", required=True)
    args = p.parse_args()
    main(Path(args.out), args.version)
