resource "aws_security_group" "eks_cluster" {
  count       = var.enable_eks ? 1 : 0
  name        = "${var.eks_cluster_name}-cluster-sg"
  description = "EKS control plane security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Nodes to control plane"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes[0].id]
  }

  # Thêm rule này — bastion → control plane
  dynamic "ingress" {
    for_each = local.should_create_bastion ? [1] : []
    content {
      description     = "Bastion to control plane"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      security_groups = [aws_security_group.bastion[0].id]
    }
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name      = "${var.eks_cluster_name}-cluster-sg"
    Component = "eks-cluster"
  })
}

resource "aws_security_group" "eks_nodes" {
  count       = var.enable_eks ? 1 : 0
  name        = "${var.eks_cluster_name}-nodes-sg"
  description = "EKS worker nodes security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Node to node"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  dynamic "ingress" {
    for_each = local.should_create_bastion ? [1] : []
    content {
      description     = "Bastion to nodes"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      security_groups = [aws_security_group.bastion[0].id]
    }
  }

  ingress {
    description = "NodePort range from NLB"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from NLB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from NLB"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name      = "${var.eks_cluster_name}-nodes-sg"
    Component = "eks-nodegroup"
  })
}

resource "aws_security_group" "bastion" {
  count       = local.should_create_bastion ? 1 : 0
  name        = "${var.project}-bastion-sg"
  description = "Bastion EC2 security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from within VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name      = "${var.project}-bastion-sg"
    Component = "bastion"
  })
}