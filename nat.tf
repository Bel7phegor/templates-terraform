resource "aws_eip" "nat" {
  # single_nat_gateway = true  → 1 EIP
  # single_nat_gateway = false → số EIP = số private subnet
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : 0
  domain = "vpc"

  tags = {
    Name = var.single_nat_gateway
      ? "${var.vpc_name}-eip-nat"
      : "${var.vpc_name}-eip-nat-${var.private_subnets[count.index].name}"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : 0

  allocation_id = aws_eip.nat[count.index].id

  # single = true  → tất cả đặt ở public subnet đầu tiên
  # single = false → mỗi NAT GW đặt ở public subnet tương ứng
  subnet_id = var.single_nat_gateway
    ? aws_subnet.public[0].id
    : aws_subnet.public[count.index].id

  tags = {
    Name = var.single_nat_gateway
      ? "${var.vpc_name}-nat-gw"
      : "${var.vpc_name}-nat-gw-${var.private_subnets[count.index].name}"
  }

  depends_on = [aws_internet_gateway.main]
}