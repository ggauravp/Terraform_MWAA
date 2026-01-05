import json
import boto3
import requests
from requests.auth import HTTPBasicAuth

def lambda_handler(event, context):
    # 1. Read S3 event data
    record = event["Records"][0]
    bucket_name = record["s3"]["bucket"]["name"]
    object_key = record["s3"]["object"]["key"]

    print(f"File uploaded: s3://{bucket_name}/{object_key}")

    # 2. MWAA details 
    MWAA_ENV_NAME = "mwaa-dev"
    DAG_ID = "s3_to_processing_dag"
    REGION = "us-east-1"

    # 3. Get MWAA webserver token
    mwaa = boto3.client("mwaa", region_name=REGION)

    token_response = mwaa.create_web_login_token(
        Name=MWAA_ENV_NAME
    )

    webserver_hostname = token_response["WebServerHostname"]
    web_token = token_response["WebToken"]

    # 4. Trigger DAG run
    dag_trigger_url = f"https://{webserver_hostname}/api/v1/dags/{DAG_ID}/dagRuns"

    payload = {
        "conf": {
            "bucket": bucket_name,
            "key": object_key
        }
    }

    response = requests.post(
        dag_trigger_url,
        json=payload,
        auth=HTTPBasicAuth("airflow", web_token),
        headers={"Content-Type": "application/json"}
    )

    print("MWAA response:", response.text)

    return {
        "statusCode": 200,
        "body": json.dumps("DAG triggered successfully")
    }
