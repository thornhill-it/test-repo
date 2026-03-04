resource "aws_iam_role" "lambda_janitor_role" {
  name = "${var.project_name}-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "janitor_policy" {
  name = "${var.project_name}-policy"
  role = aws_iam_role.lambda_janitor_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:PutBucketPublicAccessBlock", # Fixed: Matches the required API action
          "s3:GetBucketPublicAccessBlock", # Best practice for "Read-Before-Write" verification
          "sns:Publish",
          "logs:CreateLogGroup", 
          "logs:CreateLogStream", 
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}