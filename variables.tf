# GENERAL
variable "region" {
  type    = string
  default = "ap-southeast-3"
}

variable "project" {
  type    = string
  default = "lab-test"
}

variable "environment" {
  description = "dev | staging | prod"
  type        = string
  default     = "dev"
}

# VPC
variable "vpc_name" {
  type    = string
  default = "lab-test"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "enable_dns_support" {
  type    = bool
  default = true
}

variable "enable_dns_hostnames" {
  type    = bool
  default = true
}

variable "map_public_ip_on_launch" {
  type    = bool
  default = true
}

variable "public_subnets" {
  type = list(object({
    cidr = string
    az   = string
    name = string
  }))
  default = [
    { cidr = "10.0.1.0/24", az = "ap-southeast-3a", name = "public-3a" },
    { cidr = "10.0.2.0/24", az = "ap-southeast-3b", name = "public-3b" }
  ]
}

variable "private_subnets" {
  type = list(object({
    cidr = string
    az   = string
    name = string
  }))
  default = [
    { cidr = "10.0.11.0/24", az = "ap-southeast-3a", name = "private-3a" },
    { cidr = "10.0.12.0/24", az = "ap-southeast-3b", name = "private-3b" }
  ]
}

# IGW / NAT
variable "enable_igw" {
  type    = bool
  default = true
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "single_nat_gateway" {
  description = "true = 1 NAT dùng chung | false = mỗi AZ 1 NAT"
  type        = bool
  default     = true
}

# IAM ROLES
variable "eks_cluster_role_name" {
  type    = string
  default = "eks-cluster-role"
}

variable "eks_nodegroup_role_name" {
  type    = string
  default = "eks-nodegroup-role"
}

variable "bastion_instance_role_name" {
  type    = string
  default = "ec2-eks-access-role"
}

# EKS
variable "enable_eks" {
  description = "Bật/tắt toàn bộ EKS cluster"
  type        = bool
  default     = true
}

variable "eks_cluster_name" {
  type    = string
  default = "lab-test-eks"
}

variable "eks_cluster_version" {
  type    = string
  default = "1.35"
}

variable "enable_eks_auto_mode" {
  description = "Bật EKS Auto Mode, tắt để tự quản lý node group"
  type        = bool
  default     = false
}

variable "eks_endpoint_access" {
  description = "public | private | public_and_private"
  type        = string
  default     = "public_and_private"

  validation {
    condition     = contains(["public", "private", "public_and_private"], var.eks_endpoint_access)
    error_message = "Giá trị hợp lệ: public | private | public_and_private"
  }
}

# NODE GROUP
variable "enable_nodegroup" {
  description = "Bật/tắt node group — tự động tắt nếu enable_eks = false hoặc enable_eks_auto_mode = true"
  type        = bool
  default     = true
}

variable "nodegroup_name" {
  type    = string
  default = "lab-test-nodegroup"
}

variable "nodegroup_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "nodegroup_desired_size" {
  type    = number
  default = 2
}

variable "nodegroup_min_size" {
  type    = number
  default = 1
}

variable "nodegroup_max_size" {
  type    = number
  default = 4
}

variable "nodegroup_disk_size" {
  type    = number
  default = 20
}

# NODE GROUP — UPDATE CONFIGURATION
variable "nodegroup_max_unavailable_type" {
  description = "number | percentage"
  type        = string
  default     = "number"

  validation {
    condition     = contains(["number", "percentage"], var.nodegroup_max_unavailable_type)
    error_message = "Giá trị hợp lệ: number | percentage"
  }
}

variable "nodegroup_max_unavailable_value" {
  description = "Giá trị max unavailable khi update node"
  type        = number
  default     = 1
}

variable "nodegroup_update_strategy" {
  description = "Default | Minimal"
  type        = string
  default     = "Default"

  validation {
    condition     = contains(["Default", "Minimal"], var.nodegroup_update_strategy)
    error_message = "Giá trị hợp lệ: Default | Minimal"
  }
}

# NODE GROUP — AUTO REPAIR
variable "enable_node_auto_repair" {
  description = "Tự động phát hiện và thay thế node bị lỗi"
  type        = bool
  default     = true
}

# NODE GROUP — REMOTE ACCESS
variable "enable_node_remote_access" {
  description = "Bật remote access vào nodes qua SSH key pair"
  type        = bool
  default     = true
}

variable "nodegroup_ssh_key_name" {
  description = "EC2 Key Pair để SSH vào nodes"
  type        = string
  default     = ""
}

variable "nodegroup_remote_access_sg_ids" {
  description = "Security Group IDs được phép SSH vào nodes, để trống = cho phép 0.0.0.0/0"
  type        = list(string)
  default     = []
}

# BASTION
variable "enable_bastion" {
  description = "Bật/tắt EC2 Bastion — tự động tắt nếu enable_eks = false"
  type        = bool
  default     = true
}

variable "bastion_instance_type" {
  type    = string
  default = "t3.large"
}

variable "bastion_key_name" {
  description = "Key pair SSH cho bastion, để trống nếu dùng SSM"
  type        = string
  default     = ""
}

# BASTION — EKS ACCESS
variable "bastion_eks_access_policy_arn" {
  description = "ARN của EKS access policy, lấy từ: aws eks list-access-policies"
  type        = string
  default     = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
}