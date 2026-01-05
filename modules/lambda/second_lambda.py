import os
import psycopg2
import json
import boto3

def lambda_handler(event, context):
    """
    This Lambda is triggered by the DAG.
    It receives bucket and key of the uploaded S3 file and writes info into Postgres on EC2.
    """

    # Get bucket and key from event
    bucket = event.get("bucket")
    key = event.get("key")

    if not bucket or not key:
        return {"status": "error", "message": "Missing bucket or key in event"}

    print(f"Processing file: s3://{bucket}/{key}")

    # Get DB credentials from environment variables
    db_host = os.environ.get("DB_HOST")
    db_name = os.environ.get("DB_NAME")
    db_user = os.environ.get("DB_USER")
    db_password = os.environ.get("DB_PASSWORD")
    db_port = os.environ.get("DB_PORT", "5432")  # default 5432

    if not all([db_host, db_name, db_user, db_password]):
        return {"status": "error", "message": "Missing DB credentials in environment variables"}

    #  Connect to Postgres on EC2
    try:
        conn = psycopg2.connect(
            host=db_host,
            database=db_name,
            user=db_user,
            password=db_password,
            port=db_port
        )
        cur = conn.cursor()
    except Exception as e:
        print("Error connecting to database:", e)
        return {"status": "error", "message": str(e)}

    # Insert S3 file info into table
    try:
        insert_query = """
        INSERT INTO files (bucket, key)
        VALUES (%s, %s)
        """
        cur.execute(insert_query, (bucket, key))
        conn.commit()
        print(f"Inserted s3://{bucket}/{key} into database")
    except Exception as e:
        print("Error inserting into DB:", e)
        return {"status": "error", "message": str(e)}
    finally:
        cur.close()
        conn.close()

    return {"status": "success", "bucket": bucket, "key": key}
