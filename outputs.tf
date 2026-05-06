output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "igw_id" {
  value = var.enable_igw ? aws_internet_gateway.main[0].id : null
}

output "nat_gateway_ids" {
  value = var.enable_nat_gateway ? aws_nat_gateway.main[*].id : []
}

output "nat_public_ips" {
  value = var.enable_nat_gateway ? aws_eip.nat[*].public_ip : []
}