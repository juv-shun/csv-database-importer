import argparse

import boto3
from botocore.config import Config
from db import connection

boto3_config = Config(connect_timeout=10, retries={"max_attempts": 3, "mode": "standard"})

parser = argparse.ArgumentParser()
parser.add_argument("--bucket")
parser.add_argument("--object")

if __name__ == "__main__":
    args = parser.parse_args()

    with connection:
        with connection.cursor() as cursor:
            sql = "SELECT * FROM test_table"
            cursor.execute(sql)
            result = cursor.fetchone()
            print(result)

    s3 = boto3.client("s3", config=boto3_config)
    res = s3.get_object(Bucket=args.bucket, Key=args.object)
    print(res["Body"].read().decode("utf-8"))
