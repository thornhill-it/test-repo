# The Name of the Bucket (Standard for S3 uploads)
output "s3_bucket_name" {
  value       = aws_s3_bucket.janitor_trail_logs.id
  description = "The name of the S3 bucket for the Cloud Janitor logs."
}

# The ARN of the IAM Role (Crucial for application integration)
output "janitor_role_arn" {
  value       = aws_iam_role.lambda_janitor_role.arn
  description = "The ARN of the IAM role that the remediate_s3.py script should assume."
}

# The Region (Helpful for multi-region CLI commands)
output "aws_region" {
  value       = data.aws_region.current.id
  description = "The region where the infrastructure is deployed."
}