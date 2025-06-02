import logging
import shutil
import sys
import tempfile
from pathlib import Path

from kfp.v2.dsl import Dataset, Output, component

proj_root = Path(__file__).resolve().parents[2]
if str(proj_root) not in sys.path:
    sys.path.append(str(proj_root))

from src.data.fetcher.run_fetch import fetch_pool_data  # noqa: E402

logger = logging.getLogger(__name__)


@component(
    base_image="python:3.11-slim",
    packages_to_install=["requests==2.32.3", "google-cloud-storage==3.1.0"],
)
def fetch_jsonl(
    protocol: str,
    interval_end_iso: str,  # 例: "2025-05-20T09:00:00Z"
    raw_jsonl: Output[Dataset],
):
    """
    The Graph から直近 1h を取得し JSONL を raw_jsonl に出力
    """
    # 一時ファイルに保存してから OutputPath へコピー
    with tempfile.TemporaryDirectory() as tmp:
        local_path = Path(tmp) / f"{protocol}_{interval_end_iso}_pool.jsonl"
        fetch_pool_data(
            protocol=protocol,
            output_path=raw_jsonl.path,  # コンポーネントの出力を Dataset 化
            data_interval_end=interval_end_iso,
        )

        # kfp が用意した output(=directory) へコピー
        shutil.copy(str(local_path), raw_jsonl)

    logger.info(f"saved {protocol} JSONL → {raw_jsonl}")
