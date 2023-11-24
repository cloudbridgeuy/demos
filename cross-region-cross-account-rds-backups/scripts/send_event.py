import sys
import json

import boto3
from botocore.config import Config

if __name__ == "__main__":
    # Get the snapshot ARN from the first argument
    snapshot_arn = sys.argv[1]
    aws_region = "us-east-1"
    cross_account = "794582806340"
    # Get the AWS region from the second argument
    if len(sys.argv) > 2:
        aws_region = sys.argv[2]
    # Get the cross account from the third argument
    if len(sys.argv) > 3:
        cross_account = sys.argv[3]

    if not snapshot_arn:
        print("No snapshot ARN provided")
        sys.exit(1)

    # Necesitamos extraer el nombre del snapshot del ARN
    print(f"Snapshot ARN: {snapshot_arn}")

    snapshot_name = snapshot_arn.split(":")[-1]
    print(f"Snapshot Name: {snapshot_name}")

    event_client = boto3.client("events", config=Config(region_name=aws_region))
    response = event_client.put_events(
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
                        "DestinationAccount": cross_account,
                        "SourceRegion": aws_region,
                    }
                ),
            }
        ]
    )

    print(json.dumps(response, sort_keys=True, indent=4, default=str))
    print(
        json.dumps(
            {
                "Source": "atos.rds",
                "DetailType": "RDS DB Shared Snapshot Event",
                "Resources": [snapshot_arn],
                "Detail": {
                    "SourceType": "SNAPSHOT",
                    "EventID": "CROSS-ACCOUNT-SHARED-SNAPSHOT",
                    "SourceName": snapshot_name,
                    "SourceARN": snapshot_arn,
                    "DestinationAccount": cross_account,
                    "SourceRegion": aws_region,
                },
            },
            sort_keys=True,
            indent=4,
            default=str,
        )
    )
