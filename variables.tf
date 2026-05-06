variable "region" {
  description = "AWS Region"
  type        = string
  default     = "ap-southeast-3"
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