# Create the S3 bucket
resource "aws_s3_bucket" "my_app_bucket" {
  bucket        = "my-app-bucket-1337" # Must be globally unique
  force_destroy = true                 # Optional: allow deletion of non-empty bucket
  tags = {
    Name        = "MyAppBucket-1337"
    Environment = "dev"
  }
}

# Optional: Enable encryption, versioning, etc.
resource "aws_s3_bucket_versioning" "my_app_bucket_versioning" {
  bucket = aws_s3_bucket.my_app_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Grant bucket access to the EC2 role (update inline policy to reference bucket ARN)
data "aws_iam_policy_document" "s3_access_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]

    resources = [
      aws_s3_bucket.my_app_bucket.arn,
      "${aws_s3_bucket.my_app_bucket.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "ec2_ssm_s3_bucket_access" {
  name = "inline-ec2-ssm-s3-policy"
  role = aws_iam_role.ec2_ssm_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowS3AccessForSSM",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        Resource = [
          aws_s3_bucket.my_app_bucket.arn,
          "${aws_s3_bucket.my_app_bucket.arn}/*"
        ]
      }
    ]
  })
}

