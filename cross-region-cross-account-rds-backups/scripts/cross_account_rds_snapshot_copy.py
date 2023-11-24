import os
import json

import boto3
from botocore.config import Config


def handler(event, _):
    """
    Este lambda se encarga de copiar los snapshots que se crean en la region origen
    a la region destino.
    """
    kms_key_id = os.environ["KMS_KEY_ID"]
    aws_region = os.environ["AWS_REGION"]
    primary_account = os.environ["PRIMARY_ACCOUNT"]

    client = boto3.client("rds", config=Config(region_name=aws_region))

    responses = []

    print("Procesando nuevo evento")

    for snapshot_arn in event["resources"]:
        # Necesitamos extraer el nombre del snapshot del ARN
        print(f"Snapshot ARN: {snapshot_arn}")

        snapshot_name = snapshot_arn.split(":")[-1]
        print(f"Snapshot Name: {snapshot_name}")

        responses.append(
            client.copy_db_snapshot(
                SourceDBSnapshotIdentifier=snapshot_arn,
                TargetDBSnapshotIdentifier=f"copy-{snapshot_name}",
                KmsKeyId=kms_key_id,
                Tags=[
                    {"Key": "snapshot_arn", "Value": snapshot_arn},
                    {"Key": "snapshot_name", "Value": snapshot_name},
                    {"Key": "type", "Value": "cross-account-snapshot"},
                    {"Key": "primary_account", "Value": primary_account},
                ],
                CopyTags=False,
                SourceRegion=aws_region,
            )
        )
        print("Copia de snapshot finalizada con exito")

    return {
        "statusCode": 200,
        "body": json.dumps(responses, sort_keys=True, default=str),
    }
