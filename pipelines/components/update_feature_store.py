from kfp.v2.dsl import component


@component(base_image="google/cloud-sdk:slim", packages_to_install=["google-cloud-aiplatform"])
def update_feature_store(gcs_uri: str, featurestore_id: str, region: str):
    from subprocess import check_call, run

    # gsutil stat で空チェック
    if run(["gsutil", "-q", "stat", gcs_uri]).returncode != 0:
        print("no parquet to import")
        return

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
