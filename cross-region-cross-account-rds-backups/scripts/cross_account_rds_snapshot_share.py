import os
import json

import boto3
from botocore.config import Config


def handler(event, _):
    """
    Este lambda se encarga de compartir un snapshot con otra cuenta.
    """
    destination_account = os.environ["DESTINATION_ACCOUNT"]
    config = Config(
        region_name=os.environ["SOURCE_REGION"],
    )

    # Create an rds boto3 client
    rds_client = boto3.client("rds", config=config)

    # Create an eventbridge boto3 client
    event_client = boto3.client("events", config=config)

    response = {}

    print("Procesando nuevo evento")

    for snapshot_arn in event["resources"]:
        # Necesitamos extraer el nombre del snapshot del ARN
        print(f"Snapshot ARN: {snapshot_arn}")

        snapshot_name = snapshot_arn.split(":")[-1]
        print(f"Snapshot Name: {snapshot_name}")

        response = rds_client.modify_db_snapshot_attribute(
            DBSnapshotIdentifier=snapshot_arn,
            AttributeName="restore",
            ValuesToAdd=[destination_account],
        )

        # Send a custom EventBridge event
        event_client.put_events(
            Entries=[
                {
                    "Source": "atos.rds",
                    "DetailType": "RDS DB Shared Snapshot Event",
                    "Resources": [snapshot_arn],
                    "Detail": json.dumps(
                        {
                            "SourceType": "SNAPSHOT",
                            "EventID": "CROSS-ACCOUNT-SHARED-SNAPSHOT",
                            "SourceName": snapshot_name,
                            "SourceARN": snapshot_arn,
                            "DestinationAccount": destination_account,
                            "SourceRegion": os.environ["SOURCE_REGION"],
                        }
                    ),
                }
            ]
        )

        print(f"Snapshot {snapshot_name} compartido con cuenta {destination_account}")

    return {
        "statusCode": 200,
        "body": json.dumps(response, sort_keys=True, default=str),
    }
