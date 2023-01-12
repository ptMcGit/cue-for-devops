resource "aws_security_group_rule" "this" {
  description       = "Allow SSH from any IP"
  type              = "ingress"
  to_port           = 22
  protocol          = "tcp"
  from_port         = 22
  security_group_id = var.aws_security_group.id
  cidr_blocks = ["0.0.0.0/0"]
}
