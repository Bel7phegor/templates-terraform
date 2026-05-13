data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_iam_role" "bastion" {
  count = local.should_create_bastion ? 1 : 0
  name  = var.bastion_instance_role_name
}

resource "aws_iam_instance_profile" "bastion" {
  count = local.should_create_bastion ? 1 : 0
  name  = "${var.project}-bastion-instance-profile"
  role  = data.aws_iam_role.bastion[0].name

  tags = merge(local.common_tags, {
    Name      = "${var.project}-bastion-instance-profile"
    Component = "bastion"
  })
}

resource "aws_instance" "bastion" {
  count                  = local.should_create_bastion ? 1 : 0
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.bastion_instance_type
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.bastion[0].id]
  iam_instance_profile   = aws_iam_instance_profile.bastion[0].name
  key_name               = var.bastion_key_name != "" ? var.bastion_key_name : null

  user_data = <<-EOF
    #!/bin/bash
    exec > /var/log/userdata.log 2>&1

    yum update -y

    # kubectl
    KUBECTL_VERSION=$(curl -Ls https://dl.k8s.io/release/stable.txt)
    curl -fLo /usr/local/bin/kubectl \
      "https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    chmod +x /usr/local/bin/kubectl

    # helm
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # kubeconfig
    mkdir -p /root/.kube
    aws eks update-kubeconfig \
      --region ${data.aws_region.current.name} \
      --name ${aws_eks_cluster.main[0].name} \
      --kubeconfig /root/.kube/config
    echo 'export KUBECONFIG=/root/.kube/config' >> /root/.bashrc

    # Ghi script cài đặt ra file riêng
    cat > /usr/local/bin/install-tools.sh << 'SCRIPT'
    #!/bin/bash
    set -e
    exec > /var/log/install-tools.log 2>&1

    export KUBECONFIG=/root/.kube/config

    echo "[$(date)] Waiting for nodes..."
    kubectl wait --for=condition=Ready nodes --all --timeout=600s

    echo "[$(date)] Installing ingress-nginx..."
    PUBLIC_SUBNET_1="${aws_subnet.public[0].id}"
    PUBLIC_SUBNET_2="${aws_subnet.public[1].id}"

    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update

    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
      --namespace ingress-nginx \
      --create-namespace \
      --set controller.service.type=LoadBalancer \
      --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"=nlb \
      --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"=internet-facing \
      --set "controller.service.annotations.service\.beta\.kubernetes\.io/aws-load-balancer-subnets"="$$PUBLIC_SUBNET_1,$$PUBLIC_SUBNET_2" \
  EOF

  tags = merge(local.common_tags, {
    Name         = "${var.project}-bastion"
    Component    = "bastion"
    InstanceType = var.bastion_instance_type
  })

  depends_on = [aws_eks_cluster.main]
}