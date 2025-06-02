# ---------- 1. builder stage ----------
FROM python:3.11-slim AS builder

# 依存関係のインストール
COPY jobs/feature_import/requirements.txt /tmp/
RUN pip install --user --no-cache-dir -r /tmp/requirements.txt

# ---------- 2. runtime stage ----------
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
  PIP_NO_CACHE_DIR=1 \
  PATH=/root/.local/bin:$PATH

# builderステージから依存関係をコピー
COPY --from=builder /root/.local /root/.local

# スクリプトをコピー
COPY jobs/feature_import/import.sh /usr/local/bin/import.sh
COPY jobs/feature_import/feature_import.py /usr/local/bin/feature_import.py

# 実行権限を付与
RUN chmod +x /usr/local/bin/import.sh /usr/local/bin/feature_import.py

# エントリーポイント
ENTRYPOINT ["/usr/local/bin/import.sh"]