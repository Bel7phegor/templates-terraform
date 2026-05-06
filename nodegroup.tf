resource "aws_eks_node_group" "main" {
  count = local.should_create_nodegroup ? 1 : 0

  cluster_name    = aws_eks_cluster.main[0].name
  node_group_name = var.nodegroup_name
  node_role_arn   = data.aws_iam_role.eks_nodegroup[0].arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = var.nodegroup_instance_types
  disk_size       = var.nodegroup_disk_size

  scaling_config {
    desired_size = var.nodegroup_desired_size
    min_size     = var.nodegroup_min_size
    max_size     = var.nodegroup_max_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = merge(local.common_tags, {
    Name          = var.nodegroup_name
    Component     = "eks-nodegroup"
    InstanceTypes = join(",", var.nodegroup_instance_types)
    Subnets       = "private-only"
  })

  depends_on = [aws_eks_cluster.main]
}