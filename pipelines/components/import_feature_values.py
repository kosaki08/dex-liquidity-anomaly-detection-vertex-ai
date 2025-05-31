from kfp.v2.dsl import component


@component(base_image="google/cloud-sdk:slim")
def import_feature_values_cli(
    project: str,
    region: str,
    featurestore: str,
    gcs_uri: str,
) -> str:  # 戻り値：ジョブ名
    import json
    import subprocess

    cmd = [
        "gcloud",
        "ai",
        "featurestore",
        "entity-types",
        "import",
        "feature-values",
        "--project",
        project,
        "--region",
        region,
        "--featurestore",
        featurestore,
        "--entity-type",
        "dex_liquidity",
        "--gcs-source-uri",
        gcs_uri,
        "--import-schema-uri",
        "gs://google-cloud-aiplatform/schema/featurestore/import_feature_values_parquet.yaml",
        "--feature-time-field",
        "feature_timestamp",
        "--sync",
        "--format",
        "json",
    ]
    out = subprocess.check_output(cmd, text=True)
    job_name = json.loads(out)["name"]
    print(f"Import job: {job_name}")
    return job_name
