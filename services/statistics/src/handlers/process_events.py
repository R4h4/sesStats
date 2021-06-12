from typing import Any, Dict, TypedDict, Literal, List
import os
import logging
import json
import datetime as dt

from aws_lambda_powertools.utilities.typing import LambdaContext
from aws_lambda_powertools.utilities.batch import sqs_batch_processor


logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
# if os.environ['STAGE'] == 'dev':
#     logger.setLevel(logging.DEBUG)
# else:
#     logger.setLevel(logging.INFO)


class Message(TypedDict):
    notificationType: Literal['Delivery', 'Bounce', 'Complaint', 'Send', 'Open', 'Click']


def process_record(record):
    logger.debug(f'Processing record: {record}')
    body = json.loads(record['body'])
    message = json.loads(body['Message'])
    logger.debug(f'Notification type: {message["notificationType"]}')


@sqs_batch_processor(record_handler=process_record)
def handler(event: Dict[str, Any], context: LambdaContext):
    return {"statusCode": 200}
