data "aws_iam_role" "eks_cluster" {
  count = var.enable_eks ? 1 : 0
  name  = var.eks_cluster_role_name
}

data "aws_iam_role" "eks_nodegroup" {
  count = local.should_create_nodegroup ? 1 : 0
  name  = var.eks_nodegroup_role_name
}

resource "aws_eks_cluster" "main" {
  count    = var.enable_eks ? 1 : 0
  name     = var.eks_cluster_name
  version  = var.eks_cluster_version
  role_arn = data.aws_iam_role.eks_cluster[0].arn

  vpc_config {
    subnet_ids = concat(
      aws_subnet.public[*].id,
      aws_subnet.private[*].id
    )
    security_group_ids      = [aws_security_group.eks_cluster[0].id]
    endpoint_public_access  = local.endpoint_public_access
    endpoint_private_access = local.endpoint_private_access
  }

  dynamic "compute_config" {
    for_each = var.enable_eks_auto_mode ? [1] : []
    content {
      enabled       = true
      node_pools    = ["general-purpose"]
      node_role_arn = data.aws_iam_role.eks_nodegroup[0].arn
    }
  }

  dynamic "storage_config" {
    for_each = var.enable_eks_auto_mode ? [1] : []
    content {
      block_storage { enabled = true }
    }
  }

  dynamic "kubernetes_network_config" {
    for_each = var.enable_eks_auto_mode ? [1] : []
    content {
      elastic_load_balancing { enabled = true }
    }
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = merge(local.common_tags, {
    Name              = var.eks_cluster_name
    Component         = "eks-cluster"
    EndpointAccess    = var.eks_endpoint_access
    KubernetesVersion = var.eks_cluster_version
    AutoMode          = tostring(var.enable_eks_auto_mode)
  })

  depends_on = [aws_security_group.eks_cluster]
}