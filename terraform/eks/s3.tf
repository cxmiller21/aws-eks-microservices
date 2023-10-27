#####################################################
# S3 Bucket for Loki Log Storage
#####################################################
resource "aws_s3_bucket" "loki" {
  bucket        = "${local.project_prefix}-loki-bucket"
  force_destroy = true

  tags = {
    Name        = "${local.project_prefix}-loki-bucket"
    Environment = terraform.workspace
  }
}

resource "aws_s3_bucket_ownership_controls" "loki" {
  bucket = aws_s3_bucket.loki.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "loki" {
  bucket = aws_s3_bucket.loki.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "loki" {
  depends_on = [
    aws_s3_bucket_ownership_controls.loki,
    aws_s3_bucket_public_access_block.loki,
  ]

  bucket = aws_s3_bucket.loki.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "loki" {
  bucket = aws_s3_bucket.loki.id
  versioning_configuration {
    status = "Disabled"
  }
}

#####################################################
# S3 Bucket for OpenTelemetry Metrics Storage
#####################################################
resource "aws_s3_bucket" "otel_tempo" {
  bucket        = "${local.project_prefix}-otel-tempo-bucket"
  force_destroy = true

  tags = {
    Name        = "${local.project_prefix}-otel-tempo-bucket"
    Environment = terraform.workspace
  }
}

resource "aws_s3_bucket_ownership_controls" "otel_tempo" {
  bucket = aws_s3_bucket.otel_tempo.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "otel_tempo" {
  bucket = aws_s3_bucket.otel_tempo.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "otel_tempo" {
  depends_on = [
    aws_s3_bucket_ownership_controls.otel_tempo,
    aws_s3_bucket_public_access_block.otel_tempo,
  ]

  bucket = aws_s3_bucket.otel_tempo.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "otel_tempo" {
  bucket = aws_s3_bucket.otel_tempo.id
  versioning_configuration {
    status = "Disabled"
  }
}

#####################################################
# S3 Bucket for Mimir/Prometheus Log Storage
#####################################################
resource "aws_s3_bucket" "mimir" {
  bucket        = "${local.project_prefix}-mimir-bucket"
  force_destroy = true

  tags = {
    Name        = "${local.project_prefix}-mimir-bucket"
    Environment = terraform.workspace
  }
}

resource "aws_s3_bucket_ownership_controls" "mimir" {
  bucket = aws_s3_bucket.mimir.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "mimir" {
  bucket = aws_s3_bucket.mimir.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "mimir" {
  depends_on = [
    aws_s3_bucket_ownership_controls.mimir,
    aws_s3_bucket_public_access_block.mimir,
  ]

  bucket = aws_s3_bucket.mimir.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "mimir" {
  bucket = aws_s3_bucket.mimir.id
  versioning_configuration {
    status = "Disabled"
  }
}
