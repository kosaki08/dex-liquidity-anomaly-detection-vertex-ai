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
def _get_config() -> FeatureStoreConfig:
    """設定のシングルトンインスタンスを返す"""
    return FeatureStoreConfig()


@lru_cache(maxsize=1)
def _get_client() -> FeaturestoreOnlineServingServiceClient:
    """クライアントのシングルトンインスタンスを返す"""
    config = _get_config()
    client_options = {"api_endpoint": f"{config.region}-aiplatform.googleapis.com"}
    return FeaturestoreOnlineServingServiceClient(client_options=client_options)


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

    try:
        response = client.read_feature_values(request=request, retry=gapic_retry)

        features: dict[str, float] = {}

        # header フィールドでエンティティの状態を確認
        if hasattr(response, "header"):
            logger.debug(f"Response header: {response.header}")

        # entity_view を使用
        if hasattr(response, "entity_view"):
            if hasattr(response.entity_view, "data"):
                # dataは配列で、インデックスはheader.feature_descriptorsと対応
                for i, feature_data in enumerate(response.entity_view.data):
                    if i < len(response.header.feature_descriptors):
                        feature_name = response.header.feature_descriptors[i].id

                        # dataオブジェクトから値を取得
                        if feature_data and hasattr(feature_data, "value") and feature_data.value is not None:
                            value = feature_data.value
                            if hasattr(value, "double_value"):
                                features[feature_name] = value.double_value
                            elif hasattr(value, "int64_value"):
                                features[feature_name] = float(value.int64_value)
                        else:
                            # 値が存在しない場合（空のdataオブジェクト）
                            logger.debug(f"No value for feature {feature_name}")

    except Exception as e:
        logger.error(f"Failed to read features for pool_id={masked}: {e}", exc_info=True)
        features = {}

    # デフォルト値補完
    if default_value is not None:
        for fid in feature_ids:
            features.setdefault(fid, default_value)

    if len(features) == 0 or all(v == default_value for v in features.values()):
        logger.info(f"No features returned for pool_id={masked}, using default values")

    return features


def _parse_entity_view(entity_view, header) -> dict[str, float]:
    """ReadFeatureValuesResponse の entity_view を dict に変換"""
    result: dict[str, float] = {}

    for idx, desc in enumerate(header.feature_descriptors):
        fname = desc.id
        if idx < len(entity_view.data):
            val = entity_view.data[idx].value
            if val is not None:
                if hasattr(val, "double_value"):
                    result[fname] = val.double_value
                elif hasattr(val, "int64_value"):
                    result[fname] = float(val.int64_value)
    return result


def read_features_batch(
    pool_ids: list[str],
    feature_ids: list[str],
    batch_size: int = 100,
) -> dict[str, dict[str, float]]:
    """gRPC streamingを使用したバッチ読み取り"""
    config = _get_config()
    client = _get_client()
    results: dict[str, dict[str, float]] = {}

    for i in range(0, len(pool_ids), batch_size):
        batch_pool_ids = pool_ids[i : i + batch_size]

        try:
            stream = client.streaming_read_feature_values(
                entity_type=config.entity_type_path,
                entity_ids=batch_pool_ids,
                feature_selector=fs_types.FeatureSelector(id_matcher=fs_types.IdMatcher(ids=feature_ids)),
            )

            for resp in stream:
                results[resp.entity_id] = _parse_entity_view(resp.entity_view, resp.header)

        except Exception as e:
            logger.error("streaming_read_feature_values failed: %s", e)
            # フォールバックで個別読み取り
            for pid in batch_pool_ids:
                results[pid] = read_features(pid, feature_ids)

    return results
