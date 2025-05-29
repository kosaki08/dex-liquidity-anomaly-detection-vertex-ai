FROM google/cloud-sdk:alpine

# 必要なパッケージをインストール
RUN apk add --no-cache bash

# コピーして実行権限を付与
COPY import.sh /usr/local/bin/import.sh
RUN chmod +x /usr/local/bin/import.sh 

# エントリーポイントを設定
ENTRYPOINT ["/usr/local/bin/import.sh"]
