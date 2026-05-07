variable "region" {
  description = "AWS Region"
  type        = string
  default     = "ap-southeast-3"
}

variable "project" {
  description = "Tên project"
  type        = string
  default     = "lab-test"
}

# TAGS CHUNG
variable "environment" {
  description = "Môi trường: dev | staging | prod"
  type        = string
  default     = "dev"
}

variable "vpc_name" {
  description = "Name VPC"
  type        = string
  default     = "lab-test"
}

variable "vpc_cidr" {
  description = "CIDR block của VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_dns_support" {
  description = "Bật DNS resolution trong VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Bật DNS hostnames trong VPC"
  type        = bool
  default     = true
}

variable "map_public_ip_on_launch" {
  description = "Tự động gắn Public IP khi launch EC2 vào public subnet"
  type        = bool
  default     = true
}

variable "public_subnets" {
  description = "CIDR + AZ của Public Subnets"
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
  description = "CIDR + AZ của Private Subnets"
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
  description = "Tạo Internet Gateway cho public subnets"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Tạo NAT Gateway cho private subnets ra internet"
  type        = bool
  default     = true  
}

variable "single_nat_gateway" {
  description = <<-EOT
    true  = 1 NAT GW dùng chung cho tất cả private subnets (tiết kiệm chi phí)
    false = Mỗi private subnet có 1 NAT GW riêng (high availability)
  EOT
  type        = bool
  default     = true
}

# IAM ROLES
variable "eks_cluster_role_name" {
  description = "IAM Role name cho EKS Cluster"
  type        = string
  default     = "eks-cluster-role"
}

variable "eks_nodegroup_role_name" {
  description = "IAM Role name cho EKS Node Group"
  type        = string
  default     = "eks-nodegroup-role"
}

variable "bastion_instance_role_name" {
  description = "IAM Role name cho EC2 Bastion"
  type        = string
  default     = "ec2-eks-access-role"
}

# EKS CLUSTER
variable "enable_eks" {
  description = "Bật/tắt EKS Cluster"
  type        = bool
  default     = true
}

variable "eks_cluster_name" {
  type    = string
  default = "lab-test-eks"
}

variable "eks_cluster_version" {
  type    = string
  default = "1.32"
}

variable "enable_eks_auto_mode" {
  description = "Bật EKS Auto Mode, tắt để dùng custom node group"
  type        = bool
  default     = false
}

variable "eks_endpoint_access" {
  description = "Chế độ truy cập cluster endpoint: public, private, public_and_private"
  type        = string
  default     = "public_and_private"

  validation {
    condition     = contains(["public", "private", "public_and_private"], var.eks_endpoint_access)
    error_message = "Giá trị hợp lệ: public | private | public_and_private"
  }
}

# NODE GROUP
variable "enable_nodegroup" {
  description = "Bật/tắt node group - tự động tắt nếu enable_eks = false hoặc enable_eks_auto_mode = true"
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
  default = 1
}

variable "nodegroup_min_size" {
  type    = number
  default = 1
}

variable "nodegroup_max_size" {
  type    = number
  default = 1
}

variable "nodegroup_disk_size" {
  description = "Dung lượng disk mỗi node (GB)"
  type        = number
  default     = 20
}

# BASTION
variable "enable_bastion" {
  description = "Bật/tắt bastion - tự động tắt nến enable_eks = false"
  type        = bool
  default     = true
}

variable "bastion_instance_type" {
  type    = string
  default = "t3.large"
}

variable "bastion_key_name" {
  description = "Key pair để SSH, để trống nếu dùng SSM"
  type        = string
  default     = "key-pem"
}

variable "nodegroup_max_unavailable_type" {
  description = "Loại giới hạn khi update: number | percentage"
  type        = string
  default     = "number"

  validation {
    condition     = contains(["number", "percentage"], var.nodegroup_max_unavailable_type)
    error_message = "Giá trị hợp lệ: number | percentage"
  }
}

variable "nodegroup_max_unavailable_value" {
  description = "Giá trị max unavailable khi update node (number hoặc percentage tùy type)"
  type        = number
  default     = 1
}

variable "nodegroup_update_strategy" {
  description = "Chiến lược update node group: Default | Minimal"
  type        = string
  default     = "Default"

  validation {
    condition     = contains(["Default", "Minimal"], var.nodegroup_update_strategy)
    error_message = "Giá trị hợp lệ: Default | Minimal"
  }
}

# NODE GROUP — AUTO REPAIR
variable "enable_node_auto_repair" {
  description = "Bật tự động phát hiện và thay thế node bị lỗi"
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
  description = "EC2 Key Pair để SSH vào nodes (bắt buộc nếu enable_node_remote_access = true)"
  type        = string
  default     = "key-pem"
}

variable "nodegroup_remote_access_sg_ids" {
  description = "Danh sách Security Group IDs được phép SSH vào nodes. Để trống = cho phép 0.0.0.0/0"
  type        = list(string)
  default     = []
}