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
    set -e
    yum update -y
    mkdir -p /tools && cd /tools

    # kubectl
    curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.32.0/2025-01-22/bin/linux/amd64/kubectl
    chmod +x kubectl && mv kubectl /usr/local/bin/

    # helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # kubeconfig
    aws eks update-kubeconfig \
      --region ${data.aws_region.current.name} \
      --name ${aws_eks_cluster.main[0].name}

    # ── INGRESS NGINX ───────────────────────────────────────────────
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update

    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
      --namespace ingress-nginx \
      --create-namespace \
      --set controller.service.type=LoadBalancer \
      --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"=nlb \
      --wait --timeout 5m

    # ── CERT MANAGER (bắt buộc trước Rancher) ──────────────────────
    helm repo add jetstack https://charts.jetstack.io
    helm repo update

    helm upgrade --install cert-manager jetstack/cert-manager \
      --namespace cert-manager \
      --create-namespace \
      --set crds.enabled=true \
      --wait --timeout 5m

    # Chờ cert-manager webhook sẵn sàng
    sleep 30

    # ── RANCHER ────────────────────────────────────────────────────
    helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
    helm repo update

    # Lấy hostname của ingress-nginx load balancer
    RANCHER_HOSTNAME=$(kubectl get svc ingress-nginx-controller \
      -n ingress-nginx \
      -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

    helm upgrade --install rancher rancher-stable/rancher \
      --namespace cattle-system \
      --create-namespace \
      --set hostname=$${RANCHER_HOSTNAME} \
      --set bootstrapPassword=${var.rancher_bootstrap_password} \
      --set ingress.tls.source=secret \
      --set replicas=${var.rancher_replicas} \
      --wait --timeout 10m

    echo "Rancher installed at: https://$${RANCHER_HOSTNAME}"
    echo "Bootstrap password: ${var.rancher_bootstrap_password}"
  EOF

  tags = merge(local.common_tags, {
    Name         = "${var.project}-bastion"
    Component    = "bastion"
    InstanceType = var.bastion_instance_type
  })

  depends_on = [aws_eks_cluster.main]
}