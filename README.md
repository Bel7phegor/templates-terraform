# Terraform VPC — lab-test

Khởi tạo hạ tầng AWS gồm VPC, Subnets, Internet Gateway, NAT Gateway và Route Tables.

## Cấu trúc thư mục

```
.
├── main.tf
├── variables.tf
├── vpc.tf
├── igw.tf
├── nat.tf
├── routes.tf
├── outputs.tf
├── terraform.tfvars.example
├── .gitignore
└── README.md
```

## Kiến trúc

```
VPC: lab-test (10.0.0.0/16)
│
├── public-1a  (10.0.1.0/24)  ──┐
├── public-1b  (10.0.2.0/24)  ──┴──► Route Table Public ──► IGW ──► Internet
│
│   [NAT Gateway + EIP] ← đặt tại public-1a
│
├── private-1a (10.0.11.0/24) ──► Route Table private-1a ──► NAT GW
└── private-1b (10.0.12.0/24) ──► Route Table private-1b ──► NAT GW
```

## Yêu cầu

- Terraform >= 1.3.0
- AWS CLI >= 2.0
- IAM Role gắn vào EC2 với các quyền: VPC, Subnet, IGW, NAT Gateway, Elastic IP, Route Table, Tags

## Feature Flags

Các tính năng được bật/tắt qua `variables.tf` hoặc `terraform.tfvars`:

| Biến | Mặc định | Mô tả |
|---|---|---|
| `enable_dns_support` | `true` | DNS resolution trong VPC |
| `enable_dns_hostnames` | `true` | DNS hostnames cho EC2 |
| `map_public_ip_on_launch` | `true` | Tự động gán Public IP tại public subnet |
| `enable_igw` | `true` | Tạo Internet Gateway |
| `enable_nat_gateway` | `true` | Tạo NAT Gateway |
| `single_nat_gateway` | `true` | `true` = 1 NAT dùng chung, `false` = mỗi AZ 1 NAT |

Ví dụ cấu hình theo môi trường:

```hcl
# Dev — tắt NAT để tiết kiệm chi phí
enable_nat_gateway = false

# Staging — bật NAT, dùng chung
enable_nat_gateway = true
single_nat_gateway = true

# Production — mỗi AZ 1 NAT (High Availability)
enable_nat_gateway = true
single_nat_gateway = false
```

## Khởi chạy

```bash
# 1. Khởi tạo provider
terraform init

# 2. Kiểm tra cú pháp
terraform validate

# 3. Xem plan
terraform plan

# 4. Apply
terraform apply
```

## Kiểm tra sau khi apply

```bash
# Danh sách resources đã tạo
terraform state list

# Chi tiết từng resource
terraform state show aws_vpc.main
terraform state show aws_nat_gateway.main[0]

# Output values
terraform output
```

## Cập nhật

```bash
# Sửa file .tf hoặc .tfvars, sau đó
terraform plan
terraform apply
```

Override biến tạm thời không cần sửa file:

```bash
terraform apply -var="enable_nat_gateway=false"
```

## Xóa infrastructure

```bash
terraform destroy
```

## Troubleshooting

**Lỗi credentials:**
```bash
aws sts get-caller-identity
```

**State bị lệch với thực tế:**
```bash
terraform refresh
```

**Lỗi state lock:**
```bash
terraform force-unlock <LOCK_ID>
```