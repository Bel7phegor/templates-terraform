resource "aws_internet_gateway" "main" {
  count = var.enable_igw ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name      = "${var.vpc_name}-igw"
    Component = "internet-gateway"
  })
}