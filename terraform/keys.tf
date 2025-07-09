data "aws_caller_identity" "current" {}

resource "aws_kms_key" "source_key" {
  description             = "KMS key for source bucket"
  deletion_window_in_days = 7
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

resource "aws_kms_key" "dest_key" {
  description             = "KMS key for destination bucket"
  deletion_window_in_days = 7
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

resource "aws_kms_alias" "source_kms_key_alias" {
  name          = "alias/source-kms-key"
  target_key_id = aws_kms_key.source_key.key_id
}

resource "aws_kms_alias" "dest_kms_key_alias" {
  name          = "alias/dest-kms-key"
  target_key_id = aws_kms_key.dest_key.key_id
}

resource "aws_kms_key" "cloudwatch_logs" {
  description             = "KMS key for CloudWatch Logs"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-cloudwatch-logs",
    Statement = [
      {
        Sid    = "Allow administration of the key",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::802645170184:root" # Replace with your AWS account ID
        },
        Action = [
          "kms:*"
        ],
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs usage",
        Effect = "Allow",
        Principal = {
          Service = "logs.us-east-1.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*",
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:us-east-1:802645170184:log-group:/aws/vpc/flow-logs/*"
          }
        }
      }
    ]
  })
}
