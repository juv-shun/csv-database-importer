resource "aws_s3_bucket" "artifact" {
  bucket        = var.s3_bucket
  force_destroy = true
}

resource "aws_s3_bucket_acl" "artifact" {
  bucket = aws_s3_bucket.artifact.id
  acl    = "private"
}

resource "aws_s3_bucket_notification" "artifact" {
  bucket      = aws_s3_bucket.artifact.id
  eventbridge = true
}

resource "aws_s3_bucket_lifecycle_configuration" "artifact" {
  bucket = aws_s3_bucket.artifact.id

  rule {
    id     = "expiration"
    status = "Enabled"
    expiration {
      days = 90
    }
  }
}
