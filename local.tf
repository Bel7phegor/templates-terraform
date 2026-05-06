locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  endpoint_public_access  = contains(["public", "public_and_private"], var.eks_endpoint_access)
  endpoint_private_access = contains(["private", "public_and_private"], var.eks_endpoint_access)

  # Nodegroup chỉ chạy khi: EKS bật + Auto Mode tắt + enable_nodegroup = true
  should_create_nodegroup = var.enable_eks && !var.enable_eks_auto_mode && var.enable_nodegroup

  # Bastion chỉ chạy khi: EKS bật + enable_bastion = true
  should_create_bastion = var.enable_eks && var.enable_bastion
}