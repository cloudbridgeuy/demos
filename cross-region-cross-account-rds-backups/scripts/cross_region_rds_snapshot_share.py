import os
import json

import boto3
from botocore.config import Config


def modify_db_snapshot_attribute_idempotent(
    client,
    snapshot_name,
    cross_account,
):
    """
    Esta funcion se encarga de actualizar los atributos de un snapshot de forma idempotente.
    TODO:   Modificar la implementación actual para veríficar que el snapshot ya tenga esta
            configuración en vez de simplemente tragarse la excepción.
    """
    try:
        response = client.modify_db_snapshot_attribute(
            DBSnapshotIdentifier=snapshot_name,
            AttributeName="restore",
            ValuesToAdd=[cross_account],
        )
        print("Snapshot compartido con la cuenta destino")
        return response
    except client.exceptions.InvalidDBSnapshotStateFault:
        print("El snapshot ya tiene los atributos correctos, no se hace nada")
        return None


def handler(event, _):
    """
    Este lambda se encarga de copiar los snapshots que se crean en la region origen
    a la region destino.
    """
    # Environment variables
    aws_region = os.environ["AWS_REGION"]
    cross_account = os.environ["CROSS_ACCOUNT"]

    # Boto3 clients
    rds_client = boto3.client("rds", config=Config(region_name=aws_region))

    event_client = boto3.client("events", config=Config(region_name=aws_region))

    # Responses list
    responses = []

    print("Procesando nuevo evento")

    for snapshot_arn in event["resources"]:
        # Necesitamos extraer el nombre del snapshot del ARN
        print(f"Snapshot ARN: {snapshot_arn}")

        snapshot_name = snapshot_arn.split(":")[-1]
        print(f"Snapshot Name: {snapshot_name}")

        # Share the snapshot with the destination account
        responses.append(
            modify_db_snapshot_attribute_idempotent(
                rds_client,
                snapshot_name,
                cross_account,
            )
        )

        # Send a custom EventBridge event to the destination account
        responses.append(
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
                                "DestinationAccount": cross_account,
                                "SourceRegion": aws_region,
                            }
                        ),
                    }
                ]
            )
        )

        print("Evento enviado a la cuenta destino")

    return {
        "statusCode": 200,
        "body": json.dumps(responses, sort_keys=True, default=str),
    }
