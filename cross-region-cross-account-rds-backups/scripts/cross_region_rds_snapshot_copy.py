import os
import json

import boto3
from botocore.config import Config


def copy_db_snapshot_idempotent(
    client,
    snapshot_name,
    snapshot_arn,
    kms_key_id,
    aws_region,
):
    """
    Esta funcion se encarga de copiar un snapshot de forma idempotente.
    TODO:   Modificar la implementación actual para veríficar que el snapshot existe en la segunda
            cuenta en vez de simplemente tragarse la excepción.
    """
    try:
        response = client.copy_db_snapshot(
            SourceDBSnapshotIdentifier=snapshot_arn,
            TargetDBSnapshotIdentifier=f"copy-{snapshot_name}",
            KmsKeyId=kms_key_id,
            Tags=[
                {"Key": "snapshot_arn", "Value": snapshot_arn},
                {"Key": "snapshot_name", "Value": snapshot_name},
                {"Key": "type", "Value": "cross-region-snapshot"},
                {"Key": "source_aws_region", "Value": aws_region},
            ],
            CopyTags=True,
            SourceRegion=aws_region,
        )
        print("Copia de snapshot finalizada con exito")
        return response
    except client.exceptions.DBSnapshotAlreadyExistsFault:
        print("El snapshot ya existe, no se hace nada")
        return None


def handler(event, _):
    """
    Este lambda se encarga de copiar los snapshots que se crean en la region origen
    a la region destino.
    """
    # Environment variables
    aws_region = os.environ["AWS_REGION"]
    cross_region = os.environ["CROSS_REGION"]
    kms_key_id = os.environ["KMS_KEY_ID"]

    # Boto3 clients
    cross_region_rds_client = boto3.client(
        "rds", config=Config(region_name=cross_region)
    )

    # Responses list
    responses = []

    print("Procesando nuevo evento")

    for snapshot_arn in event["resources"]:
        # Necesitamos extraer el nombre del snapshot del ARN
        print(f"Snapshot ARN: {snapshot_arn}")

        snapshot_name = snapshot_arn.split(":")[-1]
        print(f"Snapshot Name: {snapshot_name}")

        # Copy the snapshot to the destination region
        responses.append(
            copy_db_snapshot_idempotent(
                cross_region_rds_client,
                snapshot_name,
                snapshot_arn,
                kms_key_id,
                aws_region,
            )
        )

    return {
        "statusCode": 200,
        "body": json.dumps(responses, sort_keys=True, default=str),
    }
