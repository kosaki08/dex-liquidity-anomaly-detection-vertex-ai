import json
import logging
import os

import functions_framework
from google.cloud.aiplatform_v1 import PredictionServiceClient

logger = logging.getLogger(__name__)

PROJECT_ID = os.environ["PROJECT_ID"]
ENDPOINT_ID = os.environ["ENDPOINT_ID"]
LOCATION = os.environ.get("REGION", "asia-northeast1")
ALLOWED_ORIGINS = [origin.strip() for origin in os.getenv("ALLOWED_ORIGINS", "").split(",") if origin.strip()]


def _cors_headers(origin: str) -> dict[str, str]:
    """許可されたオリジンだけ Access-Control-Allow-Origin を返す"""
    if any(origin.startswith(o) for o in ALLOWED_ORIGINS):
        return {
            "Access-Control-Allow-Origin": origin,
            "Access-Control-Allow-Methods": "POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
        }
    # 想定外オリジンは null を返してブラウザ側でブロック
    return {"Access-Control-Allow-Origin": "null"}


@functions_framework.http
def predict(request):
    """Vertex AI Endpointを呼び出すゲートウェイ関数"""
    origin = request.headers.get("Origin", "")

    if request.method == "OPTIONS":
        return ("", 204, _cors_headers(origin))

    try:
        payload = request.get_json()
        if not payload:
            return (json.dumps({"error": "Request body is required"}), 400, _cors_headers(origin))

        # 予測リクエストを整形
        pool_ids = payload.get("pool_ids", [])
        instances = [{"pool_id": pid} for pid in pool_ids]

        # 予測リクエストを送信
        client = PredictionServiceClient(client_options={"api_endpoint": f"{LOCATION}-aiplatform.googleapis.com"})
        endpoint_path = client.endpoint_path(project=PROJECT_ID, location=LOCATION, endpoint=ENDPOINT_ID)
        response = client.predict(endpoint=endpoint_path, instances=instances)

        # 予測結果を整形
        predictions = [
            {
                "pool_id": pool_ids[i],
                "anomaly_score": p.get("anomaly_score", 0),
                "is_anomaly": p.get("is_anomaly", False),
            }
            for i, p in enumerate(response.predictions)
        ]
        return (json.dumps({"predictions": predictions}), 200, _cors_headers(origin))

    except Exception as exc:
        return (json.dumps({"error": str(exc)}), 500, _cors_headers(origin))
