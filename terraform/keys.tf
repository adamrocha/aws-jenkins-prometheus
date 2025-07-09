data "aws_caller_identity" "current" {}

resource "aws_kms_key" "my_kms_key" {
  description             = "KMS key for encrypting S3 bucket or other resources"
  deletion_window_in_days = 0.25 # Minimum is 6 hours, set to 12 hours for safety
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Enable IAM User Permissions",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "my_kms_key_alias" {
  name          = "alias/my-kms-key"
  target_key_id = aws_kms_key.my_kms_key.key_id
}
