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
    exec > /var/log/userdata.log 2>&1

    yum update -y
    mkdir -p /tools && cd /tools

    # kubectl — dùng dl.k8s.io thay vì s3 eks (tránh lỗi XML)
    KUBECTL_VERSION=$(curl -Ls https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    chmod +x kubectl && mv kubectl /usr/local/bin/
    kubectl version --client

    # helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    helm version

    # kubeconfig — export rõ ràng
    mkdir -p /root/.kube
    aws eks update-kubeconfig \
      --region ${data.aws_region.current.name} \
      --name ${aws_eks_cluster.main[0].name} \
      --kubeconfig /root/.kube/config

    export KUBECONFIG=/root/.kube/config

    # Ghi vào bashrc để login sau vẫn dùng được
    echo 'export KUBECONFIG=/root/.kube/config' >> /root/.bashrc

    # Chờ nodes sẵn sàng
    kubectl wait --for=condition=Ready nodes --all --timeout=300s

    # ingress-nginx
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update

    PUBLIC_SUBNET_1="${aws_subnet.public[0].id}"
    PUBLIC_SUBNET_2="${aws_subnet.public[1].id}"

    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
      --namespace ingress-nginx \
      --create-namespace \
      --set controller.service.type=LoadBalancer \
      --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"=nlb \
      --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"=internet-facing \
      --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-subnets"="$${PUBLIC_SUBNET_1}\,$${PUBLIC_SUBNET_2}" \
      --wait --timeout 5m

    # cert-manager
    helm repo add jetstack https://charts.jetstack.io
    helm repo update

    helm upgrade --install cert-manager jetstack/cert-manager \
      --namespace cert-manager \
      --create-namespace \
      --set crds.enabled=true \
      --wait --timeout 5m

    sleep 30

    # Rancher
    RANCHER_HOSTNAME=$(kubectl get svc ingress-nginx-controller \
      -n ingress-nginx \
      -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

    helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
    helm repo update

    helm upgrade --install rancher rancher-stable/rancher \
      --namespace cattle-system \
      --create-namespace \
      --set hostname=$${RANCHER_HOSTNAME} \
      --set bootstrapPassword=${var.rancher_bootstrap_password} \
      --set ingress.tls.source=secret \
      --set replicas=${var.rancher_replicas} \
      --wait --timeout 10m

    echo "Rancher URL: https://$${RANCHER_HOSTNAME}"
  EOF

  tags = merge(local.common_tags, {
    Name         = "${var.project}-bastion"
    Component    = "bastion"
    InstanceType = var.bastion_instance_type
  })

  depends_on = [aws_eks_cluster.main]
}