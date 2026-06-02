import logging
import json
import os
import azure.functions as func
from azure.data.tables import TableServiceClient
from azure.core.exceptions import ResourceNotFoundError

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Visitor count function triggered.')

    try:
        connection_string = os.environ["STORAGE_CONNECTION_STRING"]
        table_name = os.environ["STORAGE_TABLE_NAME"]

        table_service = TableServiceClient.from_connection_string(connection_string)
        table_client = table_service.get_table_client(table_name)

        partition_key = "visitors"
        row_key = "total"

        try:
            entity = table_client.get_entity(partition_key=partition_key, row_key=row_key)
            count = entity["Count"] + 1
        except ResourceNotFoundError:
            count = 1

        table_client.upsert_entity({
            "PartitionKey": partition_key,
            "RowKey": row_key,
            "Count": count
        })

        return func.HttpResponse(
            json.dumps({"count": count}),
            status_code=200,
            mimetype="application/json",
            headers={"Access-Control-Allow-Origin": "https://d3rqh12vcebb1z.cloudfront.net"}
        )

    except Exception as e:
        logging.error(f"Error: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Internal server error"}),
            status_code=500,
            mimetype="application/json"
        )