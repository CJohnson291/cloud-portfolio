import logging
import json
import os
import platform
import time
import azure.functions as func

start_time = time.time()

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('System check function triggered.')

    try:
        uptime_seconds = int(time.time() - start_time)
        uptime_minutes = round(uptime_seconds / 60, 2)

        system_info = {
            "status": "operational",
            "region": os.environ.get("REGION_NAME", "West Europe"),
            "runtime": f"Python {platform.python_version()}",
            "uptime_minutes": uptime_minutes,
            "function_app": "cloud-portfolio-api-cj",
            "storage_account": os.environ.get("STORAGE_ACCOUNT_NAME", "cloudportfoliostcj"),
            "timestamp": int(time.time())
        }

        return func.HttpResponse(
            json.dumps(system_info),
            status_code=200,
            mimetype="application/json",
            headers={"Access-Control-Allow-Origin": "https://d3rqh12vcebb1z.cloudfront.net"}
        )

    except Exception as e:
        logging.error(f"System check error: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Internal server error"}),
            status_code=500,
            mimetype="application/json"
        )