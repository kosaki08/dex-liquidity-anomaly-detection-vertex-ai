from components.fetch_jsonl import fetch_jsonl
from kfp.dsl import pipeline
from kfp.v2 import compiler


@pipeline(
    name="dex_liquidity_raw",
    pipeline_root="gs://{{ bucket_name }}/pipelines",  # locals.bucket_name を使用
)
def dex_raw_pipeline(interval_end_iso: str = "{{$.pipeline_job.create_time}}"):
    """DEXの流動性データを取得"""
    for proto in ["uniswap", "sushiswap"]:
        fetch_jsonl(protocol=proto, interval_end_iso=interval_end_iso)


if __name__ == "__main__":
    compiler.Compiler().compile(
        pipeline_func=dex_raw_pipeline,
        package_path="out.json",
    )
