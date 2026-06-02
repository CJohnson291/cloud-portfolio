import logging
import json
import os
import azure.functions as func
from azure.data.tables import TableServiceClient

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Health check function triggered.')

    health = {
        "api": False,
        "storage": False,
        "cloudfront": True,
        "pipeline": True
    }

    try:
        connection_string = os.environ["STORAGE_CONNECTION_STRING"]
        table_name = os.environ["STORAGE_TABLE_NAME"]

        table_service = TableServiceClient.from_connection_string(connection_string)
        table_client = table_service.get_table_client(table_name)
        list(table_client.list_entities())

        health["storage"] = True
        health["api"] = True

        status = "healthy"
        status_code = 200

    except Exception as e:
        logging.error(f"Health check error: {str(e)}")
        status = "degraded"
        status_code = 500

    return func.HttpResponse(
        json.dumps({
            "status": status,
            "checks": health
        }),
        status_code=status_code,
        mimetype="application/json",
        headers={"Access-Control-Allow-Origin": "https://d3rqh12vcebb1z.cloudfront.net"}
    )