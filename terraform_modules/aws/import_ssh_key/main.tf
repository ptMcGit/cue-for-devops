resource "aws_key_pair" "this" {
key_name = var.ssh_pub_key_filename
public_key = file(var.ssh_pub_key_filename)
tags = var.tags
}
