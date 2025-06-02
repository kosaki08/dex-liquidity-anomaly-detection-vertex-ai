FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1

# 依存ファイルをコピー
COPY jobs/feature_import/requirements.txt /tmp/requirements.txt
RUN pip install --upgrade pip && pip install -r /tmp/requirements.txt

# コピーして実行権限を付与
COPY jobs/feature_import/import.sh /usr/local/bin/import.sh
COPY jobs/feature_import/feature_import.py /usr/local/bin/feature_import.py
RUN chmod +x /usr/local/bin/import.sh /usr/local/bin/feature_import.py

# エントリーポイントを設定
ENTRYPOINT ["/usr/local/bin/import.sh"]
