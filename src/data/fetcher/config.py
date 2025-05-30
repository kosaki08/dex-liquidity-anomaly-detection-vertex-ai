import logging
import os
from pathlib import Path

import yaml

from .types import ProtocolConfigMap

logger = logging.getLogger(__name__)


class ConfigError(Exception):
    """設定ファイル関連のエラー"""

    pass


def _get_search_candidates() -> list[Path]:
    """protocols.yml の探索候補パスのリストを返す"""
    candidates = []

    # 環境変数で明示指定されていれば最優先
    if env_path := os.getenv("PROTOCOL_CFG_PATH"):
        candidates.append(Path(env_path))

    # コンテナ環境の固定パス
    candidates.append(Path("/app/protocols.yml"))

    # ローカル開発用：親ディレクトリを順に探索
    candidates.extend(p / "protocols.yml" for p in Path(__file__).resolve().parents)

    # 重複除去（順序維持）
    return list(dict.fromkeys(candidates))


def locate_cfg() -> Path:
    """protocols.yml のパスを探索して返す"""
    candidates = _get_search_candidates()

    for cand in candidates:
        if cand.exists():
            logger.info(f"Using protocols.yml from: {cand}")
            return cand

    # 探索したパスを表示してデバッグしやすく
    searched = [str(p) for p in candidates]
    raise ConfigError("protocols.yml が見つかりません。\n探索パス:\n" + "\n".join(f"  - {p}" for p in searched))


def load_protocol_config() -> ProtocolConfigMap:
    """
    protocols.yml を読み込み、環境変数を展開して返す
    """
    cfg_path = locate_cfg()

    try:
        raw: ProtocolConfigMap = yaml.safe_load(cfg_path.read_text(encoding="utf-8"))
    except Exception as e:
        raise ConfigError(f"protocols.yml の読み込みに失敗: {e}") from e

    # 環境変数展開
    for proto, conf in raw.items():
        for k, v in conf.items():
            if isinstance(v, str) and v.startswith("${") and v.endswith("}"):
                env_name = v[2:-1]
                env_value = os.getenv(env_name)
                if env_value is None:
                    raise ConfigError(f"必須の環境変数 '{env_name}' が設定されていません (protocols.yml: {proto}.{k})")
                raw[proto][k] = env_value

    return raw
