import os
import json

import boto3
from botocore.config import Config


def handler(event, _):
    """
    Este lambda se encarga de copiar los snapshots que se crean en la region origen
    a la region destino.
    """
    config = Config(
        region_name=os.environ["AWS_REGION"],
    )
    client = boto3.client("rds", config=config)
    copy_snapshot_response = {}

    print("Procesando nuevo evento")

    for snapshot_arn in event["resources"]:
        # Necesitamos extraer el nombre del snapshot del ARN
        print(f"Snapshot ARN: {snapshot_arn}")

        snapshot_name = snapshot_arn.split(":")[-1]
        print(f"Snapshot Name: {snapshot_name}")

        copy_snapshot_response = client.copy_db_snapshot(
            SourceDBSnapshotIdentifier=snapshot_arn,
            TargetDBSnapshotIdentifier=f"cross-account-copy-{snapshot_name}",
            KmsKeyId=os.environ["KMS_KEY_ID"],
            Tags=[
                {"Key": "source_arn", "Value": snapshot_arn},
                {"Key": "source_name", "Value": snapshot_name},
                {"Key": "primary_account", "Value": os.environ["PRIMARY_ACCOUNT"]},
                {"Key": "copy", "Value": "true"},
                {"Key": "source_region", "Value": os.environ["AWS_REGION"]},
            ],
            CopyTags=True,
            SourceRegion=os.environ["AWS_REGION"],
        )
    print("Copia de snapshot finalizada con exito")
    return {
        "statusCode": 200,
        "body": json.dumps(copy_snapshot_response, sort_keys=True, default=str),
    }
