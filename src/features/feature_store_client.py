"""
Vertex AI Feature Store からオンラインで特徴量を取得するクライアント
"""

import logging
import os
from functools import lru_cache
from typing import Dict, List, Optional

from google.api_core import exceptions as api_exceptions
from google.api_core import retry
from google.cloud.aiplatform_v1 import FeaturestoreOnlineServingServiceClient
from google.cloud.aiplatform_v1 import types as fs_types

_PROJECT = os.getenv("PROJECT_ID")
_REGION = os.getenv("REGION", "asia-northeast1")
_FS_NAME = os.getenv("FEATURESTORE_NAME")
_ENTITY_TYPE_ID = "dex_liquidity"

logger = logging.getLogger(__name__)


class FeatureStoreConfig:
    """Feature Store設定を管理"""

    def __init__(self):
        self.project = os.getenv("PROJECT_ID")
        self.region = os.getenv("REGION", "asia-northeast1")
        self.featurestore_name = os.getenv("FEATURESTORE_NAME")
        self.entity_type_id = "dex_liquidity"

        # 必須環境変数の検証
        if not self.project:
            raise ValueError("PROJECT_ID environment variable is required")
        if not self.featurestore_name:
            raise ValueError("FEATURESTORE_NAME environment variable is required")

    @property
    def entity_type_path(self) -> str:
        """エンティティタイプのフルパスを返す"""
        return FeaturestoreOnlineServingServiceClient.entity_type_path(
            project=self.project,
            location=self.region,
            featurestore=self.featurestore_name,
            entity_type=self.entity_type_id,
        )


@lru_cache(maxsize=1)
def _get_client() -> FeaturestoreOnlineServingServiceClient:
    """クライアントのシングルトンインスタンスを返す"""
    client_options = {"api_endpoint": f"{os.getenv('REGION', 'asia-northeast1')}-aiplatform.googleapis.com"}
    return FeaturestoreOnlineServingServiceClient(client_options=client_options)


@lru_cache(maxsize=1)
def _get_config() -> FeatureStoreConfig:
    """設定のシングルトンインスタンスを返す"""
    return FeatureStoreConfig()


# entity_type_path を組み立て
def _entity_type_path() -> str:
    return FeaturestoreOnlineServingServiceClient.entity_type_path(
        project=_PROJECT,
        location=_REGION,
        featurestore=_FS_NAME,
        entity_type=_ENTITY_TYPE_ID,
    )


_client = FeaturestoreOnlineServingServiceClient()


def read_features(pool_id: str, feature_ids: List[str], default_value: Optional[float] = None) -> Dict[str, float]:
    """
    pool_id を entity_id として最新値を取得し dict で返す
    """
    config = _get_config()
    client = _get_client()
    masked = pool_id[:6] + "..."

    request = fs_types.ReadFeatureValuesRequest(
        entity_type=config.entity_type_path,
        entity_id=pool_id,
        feature_selector=fs_types.FeatureSelector(id_matcher=fs_types.IdMatcher(ids=feature_ids)),
    )

    # google-api-core の組み込みリトライを使用
    gapic_retry = retry.Retry(
        predicate=retry.if_exception_type(
            api_exceptions.DeadlineExceeded,
            api_exceptions.ServiceUnavailable,
        ),
        deadline=10,  # 秒
        initial=1.0,  # 秒
        maximum=5.0,  # 秒
        multiplier=2.0,
    )

    response = gapic_retry(client.read_feature_values)(request=request)

    features: dict[str, float] = {}
    for fv in response.feature_values:
        fid = fv.name.split("/")[-1]
        val_oneof = fv.value.WhichOneof("value")
        if val_oneof == "double_value":
            features[fid] = fv.value.double_value
        elif val_oneof == "int64_value":
            features[fid] = float(fv.value.int64_value)

    # デフォルト値補完
    if default_value is not None:
        for fid in feature_ids:
            features.setdefault(fid, default_value)

    if not features:
        logger.warning(f"No features returned for pool_id={masked}")

    return features
