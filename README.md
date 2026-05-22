# Terraform AWS VPC and EKS Sample

This repository contains Terraform configuration to provision an AWS lab environment with reusable networking and EKS infrastructure. The sample deploys a VPC with public and private subnets, optional NAT gateway support, an EKS cluster, an optional node group, and a bastion host for secure cluster access.

## What this project builds

- AWS VPC with a configurable CIDR block
- Public and private subnets across multiple availability zones
- Internet Gateway and public route table
- Optional NAT gateway deployment for private subnet internet access
- EKS cluster with configurable endpoint access
- Optional EKS managed node group or EKS auto mode
- Bastion host with SSH access
- Security groups for EKS control plane, worker nodes, and bastion
- Cleanup helper to remove Network Load Balancers during destroy

## Repository layout

- `main.tf` - provider, backend and core configuration
- `variables.tf` - variable definitions and defaults
- `local.tf` - computed locals and creation conditions
- `vpc.tf` - VPC and subnets
- `igw.tf` - Internet Gateway
- `nat.tf` - NAT Gateway and Elastic IP
- `routes.tf` - route tables and associations
- `sg.tf` - security groups for EKS and bastion
- `eks.tf` - EKS cluster and access entry
- `nodegroup.tf` - EKS managed node group
- `outputs.tf` - exported output values
- `cleanup.tf` - destroy-time cleanup for NLBs
- `install-tools.sh` - installation script for ingress and Rancher
- `setup-tools.sh` - Terraform install helper for Ubuntu
- `environments/dev/terraform.tfvars` - development variables
- `environments/prod/terraform.tfvars` - production variables
- `.gitignore`
- `README.md`

## Prerequisites

- Terraform 1.3 or later
- AWS CLI 2 or later
- AWS credentials configured locally
- IAM roles already created for EKS cluster, node group, and bastion host
- S3 backend bucket and DynamoDB lock table available for Terraform state

## Configuration

The project uses `variables.tf` for defaults and environment files under `environments/` for deployment settings.

Use one of the provided variable files:

```bash
terraform apply -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/prod/terraform.tfvars
```

You can also override individual values at runtime:

```bash
terraform apply -var="enable_nat_gateway=false"
```

## Deployment

Initialize Terraform and apply the configuration:

```bash
terraform init
terraform validate
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
```

If you change backend settings or move environments, update the backend configuration and re-run `terraform init`.

## Destroy

Destroy the deployed infrastructure when it is no longer needed:

```bash
terraform destroy -var-file=environments/dev/terraform.tfvars
```

## Post-deployment

The `install-tools.sh` script can be used after cluster provisioning to install ingress-nginx and Rancher. The `setup-tools.sh` script installs Terraform on Ubuntu.

## Notes

- The sample backend is configured for S3 with DynamoDB locking.
- `enable_nat_gateway` controls whether NAT gateway resources are created.
- `single_nat_gateway` controls whether one NAT gateway is shared across AZs or one per AZ.
- `enable_eks_auto_mode` enables EKS auto mode and disables the managed node group.
