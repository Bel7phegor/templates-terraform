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
    max_unavailable = (
      var.nodegroup_max_unavailable_type == "number"
        ? var.nodegroup_max_unavailable_value
        : null
    )
    max_unavailable_percentage = (
      var.nodegroup_max_unavailable_type == "percentage"
        ? var.nodegroup_max_unavailable_value
        : null
    )
  }

  node_repair_config {
    enabled = var.enable_node_auto_repair
  }

  dynamic "remote_access" {
    for_each = var.enable_node_remote_access ? [1] : []
    content {
      ec2_ssh_key               = var.nodegroup_ssh_key_name != "" ? var.nodegroup_ssh_key_name : null
      source_security_group_ids = length(var.nodegroup_remote_access_sg_ids) > 0 ? var.nodegroup_remote_access_sg_ids : null
    }
  }

  tags = merge(local.common_tags, {
    Name           = var.nodegroup_name
    Component      = "eks-nodegroup"
    InstanceTypes  = join(",", var.nodegroup_instance_types)
    Subnets        = "private-only"
    UpdateStrategy = var.nodegroup_update_strategy
    AutoRepair     = tostring(var.enable_node_auto_repair)
    RemoteAccess   = tostring(var.enable_node_remote_access)
  })

  depends_on = [aws_eks_cluster.main]
}