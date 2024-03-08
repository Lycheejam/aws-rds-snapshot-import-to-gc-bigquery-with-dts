from datetime import datetime
import os
import boto3


IAM_ROLE_ARN = os.environ["IAM_ROLE_ARN"]
S3_BUCKET_NAME = os.environ["S3_BUCKET_NAME"]
KMS_KEY_ARN = os.environ["KMS_KEY_ARN"]
DB_SCHEMA_NAME = os.environ["DB_SCHEMA_NAME"]
client = boto3.client("rds", region_name="ap-northeast-1")


def main(event, context):
    db_instance_identifier = os.environ["DB_INSTANCE_IDENTIFIER"]
    latest_snapshot_arn = fetch_latest_snapshot_arn(db_instance_identifier)
    start_export(db_instance_identifier, latest_snapshot_arn)


def start_export(db_instance_identifier, latest_snapshot_arn):
    timestamp = datetime.now().strftime("%Y-%m-%d")
    export_task_identifier = f"{db_instance_identifier}-{timestamp}"

    client.start_export_task(
        ExportTaskIdentifier=export_task_identifier,
        SourceArn=latest_snapshot_arn,
        S3BucketName=S3_BUCKET_NAME,
        IamRoleArn=IAM_ROLE_ARN,
        KmsKeyId=KMS_KEY_ARN,
        ExportOnly=[DB_SCHEMA_NAME],
    )


def fetch_latest_snapshot_arn(db_instance_identifier):
    snapshots = client.describe_db_snapshots(
        DBInstanceIdentifier=db_instance_identifier, SnapshotType="automated"
    )
    sorted_snapshots = sorted(
        snapshots["DBSnapshots"], key=lambda x: x["SnapshotCreateTime"], reverse=True
    )
    return sorted_snapshots[0]["DBSnapshotArn"]
