from google_cloud_pipeline_components.v1.batch_predict_job import BatchPredictJobRunOp
from google_cloud_pipeline_components.v1.bigquery import BigqueryQueryJobOp
from kfp.v2 import dsl

from pipelines.components.import_feature_values import import_feature_values_cli


@dsl.pipeline(name="hourly-predict")
def hourly_pipeline(
    project: str,
    region: str,
    featurestore_id: str,
    bq_dataset: str,
    model_name: str,
    instances_format: str = "bigquery",
    predictions_format: str = "bigquery",
):
    # BigQueryから特徴量をParquet形式でGCSへエクスポート（ストアドプロシージャ利用）
    export_op = BigqueryQueryJobOp(
        project=project,
        location=region,
        query=f"CALL `{project}.{bq_dataset}.proc_export_hourly`();",
    )

    # GCSからFeature Storeに特徴量をインポート (gcloud CLIコンポーネントをラップ)
    import_op = import_feature_values_cli(
        project=project,
        region=region,
        featurestore=featurestore_id,
        gcs_uri=export_op.outputs["destinationUris"],
    )

    # Vertex AI Batch Prediction を実行（バッチ推論）
    BatchPredictJobRunOp(
        project=project,
        location=region,
        job_display_name="hourly_batch_prediction",
        model=model_name,
        instances_format=instances_format,
        predictions_format=predictions_format,
        bigquery_source_input_uri=f"bq://{project}.{bq_dataset}.prediction_input",
        bigquery_destination_output_uri=f"bq://{project}.{bq_dataset}",
        machine_type="n1-standard-4",
    ).after(import_op)
