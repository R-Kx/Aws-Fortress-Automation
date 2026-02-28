resource "random_id" "s3_bucket_id" {
    byte_length = 4
}

resource "aws_s3_bucket" "flask_bucket" {
    bucket              = "s3-bucket-${random_id.s3_bucket_id.hex}"
    force_destroy       = true
    #object_lock_enable = true
}

resource "aws_s3_bucket_ownership_controls" "flask_bucket_ownership" {
    bucket = aws_s3_bucket.flask_bucket.id
    rule {
        object_ownership = "BucketOwnerPreferred"
    }
}

resource "aws_s3_bucket_public_access_block" "flask_bucket_access" {
    bucket = aws_s3_bucket.flask_bucket.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "flask_bucket_acl" {
    depends_on = [aws_s3_bucket_ownership_controls.flask_bucket_ownership]
    bucket     = aws_s3_bucket.flask_bucket.id
    acl        = "private"
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
    bucket = aws_s3_bucket.flask_bucket.id
    versioning_configuration {
      status = "Enabled"
    }
}

resource "aws_s3_object" "uploads_folder" {
    depends_on = [aws_s3_bucket_versioning.bucket_versioning]

    bucket        = aws_s3_bucket.flask_bucket.id
    key           = "uploads/"
    content_type  = "application/x-directory"
    force_destroy = true
}

resource "aws_s3_object" "logs_folder" {
    depends_on = [aws_s3_bucket_versioning.bucket_versioning]

    bucket        = aws_s3_bucket.flask_bucket.id
    key           = "logs/"
    content_type  = "application/x-directory"
    force_destroy = true
}
