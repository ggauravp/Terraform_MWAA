from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
import boto3
import json

def invoke_second_lambda(**context):
    conf = context["dag_run"].conf
    bucket = conf["bucket"]
    key = conf["key"]

    lambda_client = boto3.client("lambda")

    payload = {
        "bucket": bucket,
        "key": key
    }

    response = lambda_client.invoke(
        FunctionName="second_lambda_function",
        InvocationType="Event",  # async
        Payload=json.dumps(payload)
    )

    print("Second Lambda invoked:", response)

with DAG(
    dag_id="s3_to_processing_dag",
    start_date=datetime(2024, 1, 1),
    schedule_interval=None,
    catchup=False,
) as dag:

    invoke_lambda = PythonOperator(
        task_id="invoke_second_lambda",
        python_callable=invoke_second_lambda,
        provide_context=True,
    )
