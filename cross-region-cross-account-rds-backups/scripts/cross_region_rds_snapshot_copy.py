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
        region_name=os.environ["DESTINATION_REGION"],
    )
    client = boto3.client("rds", config=config)
    copy_snapshot_response = {}

    print("Procesando nuevo evento")

    for snapshot_arn in event["resources"]:
        # Necesitamos extraer el nombre del snapshot del ARN
        arn = snapshot_arn.split(":")
        snapshot_name = arn[7]

        print(f"Snapshot: {snapshot_name}")

        copy_snapshot_response = client.copy_db_snapshot(
            SourceDBSnapshotIdentifier=snapshot_arn,
            TargetDNSnapshotIdentifier=f"copy-{snapshot_name}",
            Tags=[
                {"Key": "source_arn", "Value": snapshot_arn},
                {"Key": "source_name", "Value": snapshot_name},
                {"Key": "copy", "Value": "true"},
                {"Key": "source_region", "Value": os.environ["SOURCE_REGION"]},
            ],
            CopyTags=True,
            SourceRegion=os.environ["SOURCE_REGION"],
        )
    print("Copia de snapshot finalizada con exito")
    return {"statusCode": 200, "body": json.dumps(copy_snapshot_response)}
