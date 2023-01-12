resource "aws_subnet" "this" {
  vpc_id     = var.vpc_id
  cidr_block = var.cidr_block
  availability_zone = var.availability_zone
  tags = var.tags
}

# todo -- we must route from the nat gateway to the internet gateway

resource "aws_route_table" "this" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
 gateway_id = aws_nat_gateway.this.id
  }
  tags = var.tags
}

resource "aws_eip" "this" {
  vpc = true
  tags = var.tags
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = aws_subnet.this.id
  connectivity_type = "public"
  tags = var.tags
}

resource "aws_route_table_association" "this" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_route_table.this.id
}
