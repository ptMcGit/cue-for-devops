
resource "aws_s3_bucket" "this" {
  bucket = "${tags.Name}-backup"

  tags = var.tags
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id = "rule-1"

    # ... other transition/expiration actions ...

    status = "Enabled"
  }
}
