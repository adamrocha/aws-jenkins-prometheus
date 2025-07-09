# Create the S3 bucket
resource "aws_s3_bucket" "project_bucket" {
  bucket        = "project-bucket-1337" # Must be globally unique
  force_destroy = true                  # Optional: allow deletion of non-empty bucket
  tags = {
    Name = "project-bucket-1337"
  }
}

# Optional: Enable encryption, versioning, etc.
resource "aws_s3_bucket_versioning" "project_bucket_versioning" {
  bucket = aws_s3_bucket.project_bucket.id

  versioning_configuration {
    status = "Enabled"
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [versioning_configuration]
  }
}

resource "aws_s3_bucket_versioning" "replication_bucket_versioning" {
  bucket = aws_s3_bucket.replication_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "project_bucket_replication" {
  depends_on = [aws_s3_bucket_versioning.project_bucket_versioning]
  role       = aws_iam_role.s3_replication_role.arn
  bucket     = aws_s3_bucket.project_bucket.id

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.replication_bucket.arn
      storage_class = "STANDARD" # Optional: specify storage class for replicated objects
    }

    filter {
      prefix = "" # Applies to all objects in the bucket
    }

    delete_marker_replication {
      status = "Disabled" # or "Enabled" if your use case supports it
    }
  }
}

resource "aws_s3_bucket_public_access_block" "project_bucket_public_access" {
  bucket = aws_s3_bucket.project_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_notification" "project_bucket_notification" {
  bucket = aws_s3_bucket.project_bucket.id
}

resource "aws_s3_bucket_logging" "project_bucket_logging" {
  bucket        = aws_s3_bucket.project_bucket.id
  target_bucket = aws_s3_bucket.project_bucket.id # Log to the same bucket for simplicity, or a dedicated logging bucket
  target_prefix = "log/"
}


resource "aws_s3_bucket" "replication_bucket" {
  bucket        = "project-replication-bucket-1337" # Must be globally unique
  force_destroy = true                              # Optional: allow deletion of non-empty bucket
  tags = {
    Name = "replication-bucket-1337"
  }
}

resource "aws_s3_bucket_public_access_block" "replication_bucket_public_access" {
  bucket = aws_s3_bucket.replication_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_notification" "replication_bucket_notification" {
  bucket = aws_s3_bucket.replication_bucket.id
}

resource "aws_s3_bucket_logging" "replication_bucket_logging" {
  bucket        = aws_s3_bucket.replication_bucket.id
  target_bucket = aws_s3_bucket.replication_bucket.id # Log to the same bucket for simplicity, or a dedicated logging bucket
  target_prefix = "log/"
}

resource "aws_s3_bucket_lifecycle_configuration" "replication_bucket_lifecycle" {
  bucket = aws_s3_bucket.replication_bucket.id

  rule {
    id     = "expire-old-objects"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "source_bucket_sse" {
  bucket = aws_s3_bucket.project_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.source_key.key_id # Optional: specify KMS key for SSE-KMS
      sse_algorithm     = "aws:kms"                     # Use "AES256" for SSE-S3 or "aws:kms" for SSE-KMS     
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "replication_bucket_sse" {
  bucket = aws_s3_bucket.replication_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "project_bucket_lifecycle" {
  bucket = aws_s3_bucket.project_bucket.id

  rule {
    id     = "expire-old-objects"
    status = "Enabled"

    filter {
      prefix = ""
    } # Applies to all objects in the bucket

    expiration {
      days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

