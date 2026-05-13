# Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
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
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.bastion_instance_type
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.bastion[0].id]
  iam_instance_profile   = aws_iam_instance_profile.bastion[0].name
  key_name               = var.bastion_key_name != "" ? var.bastion_key_name : null

  user_data = <<-USERDATA
#!/bin/bash
exec > >(tee /var/log/userdata.log|logger -t user-data -s 2>/dev/console) 2>&1

set -x # Debug mode: In ra từng câu lệnh trước khi chạy
apt-get update -y
apt-get install -y curl unzip wget net-tools

# AWS CLI
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/awscliv2.zip /tmp/aws
aws --version

# kubectl
curl -fLo /usr/local/bin/kubectl \
  "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x /usr/local/bin/kubectl
kubectl version --client

# helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

# kubeconfig
mkdir -p /root/.kube
aws eks update-kubeconfig \
  --region ${data.aws_region.current.name} \
  --name ${aws_eks_cluster.main[0].name} \
  --kubeconfig /root/.kube/config

echo 'export KUBECONFIG=/root/.kube/config' >> /root/.bashrc
echo 'export KUBECONFIG=/root/.kube/config' >> /home/ubuntu/.bashrc

# install-tools script
cat > /usr/local/bin/install-tools.sh << 'SCRIPT'
#!/bin/bash
set -e
exec >> /var/log/install-tools.log 2>&1

export KUBECONFIG=/root/.kube/config

echo "[$(date)] Waiting for nodes..."
kubectl wait --for=condition=Ready nodes --all --timeout=600s

echo "[$(date)] Installing ingress-nginx..."
PUBLIC_SUBNET_1="${aws_subnet.public[0].id}"
PUBLIC_SUBNET_2="${aws_subnet.public[1].id}"
PUBLIC_SUBNETS="$PUBLIC_SUBNET_1\\,$PUBLIC_SUBNET_2"

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

STATUS=$(helm status ingress-nginx -n ingress-nginx 2>&1 || echo "Not Found")
if echo "$STATUS" | grep -q "pending-"; then
  echo "[$(date)] Detected pending state, deleting stuck release..."
  helm uninstall ingress-nginx -n ingress-nginx --wait || true
  sleep 10
fi

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"=nlb \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"=internet-facing \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-subnets"="$PUBLIC_SUBNETS" \
  --atomic --cleanup-on-fail \
  --wait --timeout 5m

echo "Userdata complete"
  USERDATA

  tags = merge(local.common_tags, {
    Name         = "${var.project}-bastion"
    Component    = "bastion"
    OS           = "ubuntu-22.04"
    InstanceType = var.bastion_instance_type
  })

  depends_on = [aws_eks_cluster.main]
}