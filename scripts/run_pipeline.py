import os
from datetime import datetime, timezone

from google.cloud import aiplatform

PROJECT_ID = os.environ["PROJECT_ID"]
REGION = os.getenv("REGION", "asia-northeast1")
SA_EMAIL = os.environ["PIPELINE_SA_EMAIL"]
PIPELINE_ROOT = os.environ["PIPELINE_ROOT"]  # 例: gs://.../pipelines
PIPELINE_JSON = "dex_liquidity_raw-pipeline.json"


# Vertex AI 初期化
aiplatform.init(
    project=PROJECT_ID,
    location=REGION,
    staging_bucket=PIPELINE_ROOT,
)

# PipelineJob インスタンス作成
job = aiplatform.PipelineJob(
    display_name="dex-liquidity-raw-" + datetime.now(timezone.utc).strftime("%Y%m%d-%H%M"),
    template_path=PIPELINE_JSON,
    pipeline_root=PIPELINE_ROOT,
)

# 実行
job.run(
    service_account=SA_EMAIL,
    sync=True,  # True: 完了までブロック / False: 非同期
)

print("Pipeline Job URL:", job.state.name)
