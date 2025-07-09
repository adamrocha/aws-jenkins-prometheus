resource "aws_iam_role" "ec2_ssm_s3_role" {
  name = "ec2-ssm-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_ssm_s3_inline" {
  name = "ssm-and-s3-access-policy"
  role = aws_iam_role.ec2_ssm_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowSSMAndMessages",
        Effect = "Allow",
        Action = [
          "ssm:*",
          "ssmmessages:*",
          "ec2messages:*"
        ],
        Resource = ["arn:aws:ec2:*:*:instance/*"]
      },
      {
        Sid    = "AllowS3Access",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::project-bucket-1337",
          "arn:aws:s3:::project-bucket-1337/*"
        ]
      },
      {
        Sid    = "AllowCloudWatchLogs",
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["arn:aws:logs:*:*:log-group:/aws/ssm/*"]
      }
    ]
  })
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
          "${aws_s3_bucket.project_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "s3_replication_role" {
  name = "s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "s3.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "s3_replication_policy" {
  name = "s3-replication-policy"
  role = aws_iam_role.s3_replication_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::project-bucket-1337"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ],
        Resource = [
          "arn:aws:s3:::project-bucket-1337/*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = "kms:Decrypt",
        Resource = aws_kms_key.source_key.arn
      },
      {
        Effect   = "Allow",
        Action   = "kms:Encrypt",
        Resource = aws_kms_key.dest_key.arn
      }
    ]
  })
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
      aws_s3_bucket.project_bucket.arn,
    ]
  }
}


resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_ssm_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.ec2_ssm_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  # or use AmazonS3FullAccess or a custom policy
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ssm-s3-profile"
  role = aws_iam_role.ec2_ssm_s3_role.name
}

/*
// Upload a Private Key Pair for SSH Instance Authentication
resource "aws_key_pair" "default" {
  key_name   = "aws-key-pair"
  public_key = file("/opt/keys/aws-kp-ecdsa.pub")
}
*/

/*
data "aws_ami" "ubuntu_noble_24_04_arm64_minimal" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu-minimal/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-minimal-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
*/
// Front end servers running Ubuntu 24.04 ARM micro