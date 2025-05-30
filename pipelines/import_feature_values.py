from kfp.v2.dsl import component


@component(base_image="google/cloud-sdk:slim", packages_to_install=[])
def import_feature_values(
    featurestore_id: str,
    gcs_uri: str,
    region: str = "asia-northeast1",
):
    """Parquet → Feature Store へのインポート (同期)"""
    from subprocess import check_call

    check_call(
        [
            "gcloud",
            "ai",
            "featurestore",
            "entity-types",
            "import",
            "feature-values",
            "--featurestore",
            featurestore_id,
            "--entity-type",
            "dex_liquidity",
            "--gcs-source-uri",
            gcs_uri,
            "--import-schema-uri",
            "gs://google-cloud-aiplatform/schema/featurestore/import_feature_values_parquet.yaml",
            "--feature-time-field",
            "feature_timestamp",
            "--worker-count",
            "1",
            "--sync",
            "--region",
            region,
        ]
    )
