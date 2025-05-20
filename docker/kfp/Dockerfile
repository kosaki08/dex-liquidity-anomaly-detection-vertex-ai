FROM python:3.11-slim

# 依存関係をインストール（The Graph 取得 + GCS への書き込み）
RUN pip install --no-cache-dir \
  requests==2.32.3 \
  google-cloud-storage==2.16.0

# scripts.fetcher をコンポーネントから import できるようコピー
COPY scripts /workspace/scripts

# ワークディレクトリを設定
WORKDIR /workspace

# KFP が `python <module>.py` で呼び出す
ENTRYPOINT ["python"]