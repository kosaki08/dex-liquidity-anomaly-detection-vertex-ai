FROM mcr.microsoft.com/devcontainers/python:1-3.12

# ---------- OS レイヤ ----------
USER root
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  build-essential curl && \
  rm -rf /var/lib/apt/lists/*

# ---------- Python パッケージ ----------
RUN pip install --no-cache-dir poetry

# プロジェクトルートに移動し、先に lock／toml をコピー
WORKDIR /workspaces/${localWorkspaceFolderBasename}
COPY pyproject.toml poetry.lock ./

# 仮想環境は作らずコンテナ全体にインストール
RUN poetry config virtualenvs.create false \
  && poetry install --no-root --no-interaction --no-ansi

# ---------- vscode ユーザーに切り替え ----------
USER vscode