import boto3
import json
import logging
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')
sns_client = boto3.client('sns')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

def lambda_handler(event, context):
    try:
        event_source = event['detail']['eventSource']
        
        # LOGIC A: S3 Remediation
        if event_source == 's3.amazonaws.com':
            bucket_name = event['detail']['requestParameters']['bucketName']
            logger.info(f"S3 Event Detected. Remediating bucket: {bucket_name}")
            
            s3_client.put_public_access_block(
                Bucket=bucket_name,
                PublicAccessBlockConfiguration={
                    'BlockPublicAcls': True, 'IgnorePublicAcls': True,
                    'BlockPublicPolicy': True, 'RestrictPublicBuckets': True
                }
            )
            message = f"SUCCESS: Blocked public access for {bucket_name}"
            
        # LOGIC B: IAM Monitoring
        elif event_source == 'iam.amazonaws.com':
            user_name = event['detail']['requestParameters']['userName']
            logger.info(f"IAM Event Detected. Access Key created for: {user_name}")
            message = f"SECURITY ALERT: Permanent Access Key created for user: {user_name}. Review immediately."

        # Notify via SNS
        if SNS_TOPIC_ARN:
            sns_client.publish(TopicArn=SNS_TOPIC_ARN, Message=message, Subject="Cloud Janitor Alert")
            
        logger.info(message)
        return {'statusCode': 200, 'body': json.dumps(message)}

    except Exception as e:
        logger.error(f"ERROR: {str(e)}")
        raise e