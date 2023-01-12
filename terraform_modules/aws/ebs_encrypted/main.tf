module "tags" {
  source          = "../../../modules/aws/tags"
}

resource "aws_kms_key" "this" {
  tags = var.tags
}

resource "aws_ebs_volume" "this" {
  availability_zone = var.availability_zone
  size              = var.size
  type              = "gp2"
  encrypted         = true
  kms_key_id        = aws_kms_key.this.arn
  tags = var.tags
  lifecycle {
    prevent_destroy = true
  }
}