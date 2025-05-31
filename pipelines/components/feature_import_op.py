from kfp.v2.dsl import pipeline

from pipelines.components.import_feature_values import import_feature_values_cli


@pipeline(name="feature-store-import")
def feature_store_import_pipeline(
    project: str,
    region: str,
    featurestore_id: str,
    gcs_uri: str,
):
    import_feature_values_cli(
        project=project,
        region=region,
        featurestore=featurestore_id,
        gcs_uri=gcs_uri,
    )
