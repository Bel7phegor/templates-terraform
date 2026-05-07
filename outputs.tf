# VPC
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "nat_public_ips" {
  value = var.enable_nat_gateway ? aws_eip.nat[*].public_ip : []
}

# EKS
output "eks_cluster_name" {
  value = var.enable_eks ? aws_eks_cluster.main[0].name : null
}

output "eks_cluster_endpoint" {
  value = var.enable_eks ? aws_eks_cluster.main[0].endpoint : null
}

output "eks_cluster_version" {
  value = var.enable_eks ? aws_eks_cluster.main[0].version : null
}

output "eks_endpoint_access_mode" {
  value = var.enable_eks ? var.eks_endpoint_access : null
}

output "nodegroup_status" {
  value = local.should_create_nodegroup ? aws_eks_node_group.main[0].status : "disabled"
}

# BASTION
output "bastion_private_ip" {
  value = local.should_create_bastion ? aws_instance.bastion[0].private_ip : null
}

output "bastion_eks_access_policy" {
  value = local.should_create_bastion ? var.bastion_eks_access_policy_arn : null
}

output "bastion_role_arn" {
  value = local.should_create_bastion ? data.aws_iam_role.bastion_for_eks[0].arn : null
}