resource "aws_eks_node_group" "main" {
  count = local.should_create_nodegroup ? 1 : 0

  cluster_name    = aws_eks_cluster.main[0].name
  node_group_name = var.nodegroup_name
  node_role_arn   = data.aws_iam_role.eks_nodegroup[0].arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = var.nodegroup_instance_types
  disk_size       = var.nodegroup_disk_size

  # SCALING
  scaling_config {
    desired_size = var.nodegroup_desired_size
    min_size     = var.nodegroup_min_size
    max_size     = var.nodegroup_max_size
  }

  # UPDATE CONFIGURATION
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

  # NODE AUTO REPAIR
  node_repair_config {
    enabled = var.enable_node_auto_repair
  }

  # REMOTE ACCESS
  dynamic "remote_access" {
    for_each = var.enable_node_remote_access ? [1] : []
    content {
      ec2_ssh_key               = var.nodegroup_ssh_key_name != "" ? var.nodegroup_ssh_key_name : null
      source_security_group_ids = length(var.nodegroup_remote_access_sg_ids) > 0 ? var.nodegroup_remote_access_sg_ids : null
    }
  }

  tags = merge(local.common_tags, {
    Name             = var.nodegroup_name
    Component        = "eks-nodegroup"
    InstanceTypes    = join(",", var.nodegroup_instance_types)
    Subnets          = "private-only"
    UpdateStrategy   = var.nodegroup_update_strategy
    AutoRepair       = tostring(var.enable_node_auto_repair)
    RemoteAccess     = tostring(var.enable_node_remote_access)
    WarmPool         = tostring(var.enable_asg_warm_pool)
  })

  depends_on = [aws_eks_cluster.main]
}

# ASG WARM POOL
# Node group tạo ra 1 ASG ngầm, cần dùng aws_autoscaling_group_tag
# để tìm đúng ASG rồi gắn warm pool vào
data "aws_autoscaling_groups" "nodegroup" {
  count = local.should_create_nodegroup && var.enable_asg_warm_pool ? 1 : 0

  filter {
    name   = "tag:eks:nodegroup-name"
    values = [var.nodegroup_name]
  }

  filter {
    name   = "tag:eks:cluster-name"
    values = [var.eks_cluster_name]
  }

  depends_on = [aws_eks_node_group.main]
}

resource "aws_autoscaling_warm_pool" "nodegroup" {
  count = local.should_create_nodegroup && var.enable_asg_warm_pool ? 1 : 0

  autoscaling_group_name = data.aws_autoscaling_groups.nodegroup[0].names[0]

  min_size                  = var.warm_pool_min_size
  max_group_prepared_capacity = var.warm_pool_max_prepared_capacity

  pool_state = "Stopped"

  instance_reuse_policy {
    reuse_on_scale_in = var.warm_pool_reuse_on_scale_in
  }

  depends_on = [aws_eks_node_group.main]
}