##############################################################
# 1. DATA SOURCES
##############################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "remediate_s3.py"
  output_path = "remediate_s3.zip"
}

##############################################################
# 2. TELEMETRY LAYER (THE EYES)
##############################################################

# S3 Bucket to store the CloudTrail logs
resource "aws_s3_bucket" "janitor_trail_logs" {
  bucket        = "${var.project_name}-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true 
}

# Critical Policy: Grants CloudTrail permission to write to the bucket
resource "aws_s3_bucket_policy" "allow_cloudtrail" {
  bucket = aws_s3_bucket.janitor_trail_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.janitor_trail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.janitor_trail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

# The Trail: Configured for "WriteOnly" (Principle of Least Data)
resource "aws_cloudtrail" "main_trail" {
  name                          = "${var.project_name}-management-trail"
  s3_bucket_name                = aws_s3_bucket.janitor_trail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = false
  enable_log_file_validation    = true
  depends_on                    = [aws_s3_bucket_policy.allow_cloudtrail]

  event_selector {
    read_write_type           = "WriteOnly"
    include_management_events = true
  }
}

##############################################################
# 3. REMEDIATION LAYER (THE BRAINS)
##############################################################

resource "aws_lambda_function" "s3_janitor" {
  filename         = "remediate_s3.zip"
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_janitor_role.arn
  handler          = "remediate_s3.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.11"

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.security_alerts.arn
    }
  }
}

##############################################################
# 4. DETECTION LAYER (EVENTBRIDGE)
##############################################################

resource "aws_cloudwatch_event_rule" "s3_event_rule" {
  name        = "${var.project_name}-s3-detection-rule"
  description = "Triggered on S3 Public Access modifications"
  
  event_pattern = jsonencode({
    "source": ["aws.s3"],
    "detail-type": ["AWS API Call via CloudTrail"],
    "detail": {
      "eventSource": ["s3.amazonaws.com"],
      "eventName": ["CreateBucket", "PutBucketPublicAccessBlock", "PutBucketPolicy"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.s3_event_rule.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.s3_janitor.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_janitor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_event_rule.arn
}

##############################################################
# 5. NOTIFICATION LAYER (SNS)
##############################################################

resource "aws_sns_topic" "security_alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_sns_topic_subscription" "email_target" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

##############################################################
# 6. EXTENSIONS (FEATURE TOGGLES)
##############################################################

# # UNCOMMENT EXTENSION B TO ENABLE IAM KEY MONITORING
# # REQUIRES: The Universal Python script must be in remediate_s3.py

# resource "aws_cloudwatch_event_rule" "iam_key_creation" {
#   name        = "${var.project_name}-iam-key-monitor"
#   event_pattern = jsonencode({
#     "source": ["aws.iam"],
#     "detail-type": ["AWS API Call via CloudTrail"],
#     "detail": {
#       "eventSource": ["iam.amazonaws.com"],
#       "eventName": ["CreateAccessKey"]
#     }
#   })
# }

# resource "aws_cloudwatch_event_target" "iam_target" {
#   rule      = aws_cloudwatch_event_rule.iam_key_creation.name
#   target_id = "SendKeyAlertToLambda"
#   arn       = aws_lambda_function.s3_janitor.arn
# }

# resource "aws_lambda_permission" "allow_iam_eventbridge" {
#   statement_id  = "AllowIAMExecutionFromEventBridge"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.s3_janitor.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.iam_key_creation.arn
# }
