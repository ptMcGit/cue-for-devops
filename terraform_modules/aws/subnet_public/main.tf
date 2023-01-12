data "aws_internet_gateway" "this" {
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_route_table" "this" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.this.id
  }
}

resource "aws_main_route_table_association" "this" {
  vpc_id         = var.vpc_id
  route_table_id = aws_route_table.this.id
}

resource "aws_subnet" "this" {
  vpc_id     = var.vpc_id
  cidr_block = var.cidr_block
  availability_zone = var.availability_zone
}

resource "aws_route_table_association" "this" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_route_table.this.id
}
