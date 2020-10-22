import os
import boto3
import uuid
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.ERROR)

sfn = boto3.client('stepfunctions')
s3 = boto3.client('s3')

def handler(event, context):
    for record in event['Records']:
        for msg in json.loads(record['body'])['Records']:

            bucket = msg['s3']['bucket']['name']
            key = msg['s3']['object']['key']
            logger.info('bucket=%s key=%s' % (bucket, key))

            manifest = s3.get_object(Bucket=bucket, Key=key)['Body'].read().decode('utf-8')
            logger.info(manifest)

            sfn.start_execution(
                stateMachineArn=os.environ['STATE_MACHINE_ARN'],
                name='faces-%s-%s' % (uuid.uuid4().hex, context.aws_request_id),
                input=manifest,
            )

    return {}
