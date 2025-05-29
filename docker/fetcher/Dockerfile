FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1
WORKDIR /app

# 依存ファイルをコピー
COPY docker/fetcher/requirements.txt /tmp/requirements.txt
RUN pip install --upgrade pip && pip install -r /tmp/requirements.txt

# アプリケーションコードをコピー
COPY src/ /app/src
COPY protocols.yml /app/src/
ENV PYTHONPATH=/app/src

ENTRYPOINT ["python", "-m", "src.jobs.fetcher.run_fetch_cli"]
