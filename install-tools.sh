#!/bin/bash
set -e
exec >> /var/log/install-tools.log 2>&1

export KUBECONFIG=/root/.kube/config

echo "[$(date)] Waiting for nodes to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=600s
echo "[$(date)] All nodes ready."
kubectl get nodes

echo "[$(date)] Installing ingress-nginx with ACM certificate..."
PUBLIC_SUBNET_1="${aws_subnet.public[0].id}"
PUBLIC_SUBNET_2="${aws_subnet.public[1].id}"
PUBLIC_SUBNETS="$PUBLIC_SUBNET_1\\,$PUBLIC_SUBNET_2"
ACM_CERT_ARN="${var.acm_certificate_arn}"

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"=nlb \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"=internet-facing \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-subnets"="$PUBLIC_SUBNETS" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-cert"="$ACM_CERT_ARN" \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-ssl-ports"=https \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-backend-protocol"=http \
  --set controller.service.targetPorts.https=http \
  --set controller.config.use-forwarded-headers="true" \
  --set controller.config.proxy-real-ip-cidr="0.0.0.0/0" \
  --set controller.config.ssl-redirect="false" \
  --set controller.config.force-ssl-redirect="false" \
  --timeout 10m

echo "[$(date)] ingress-nginx installed."
kubectl get svc -n ingress-nginx

echo "[$(date)] Waiting for NLB hostname..."
NLB_HOSTNAME=""
for i in $(seq 1 40); do
  NLB_HOSTNAME=$(kubectl get svc ingress-nginx-controller \
    -n ingress-nginx \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
  if [ -n "$NLB_HOSTNAME" ]; then
    echo "[$(date)] NLB hostname: $NLB_HOSTNAME"
    break
  fi
  echo "[$(date)] Waiting for NLB... attempt $i/40"
  sleep 15
done

if [ -z "$NLB_HOSTNAME" ]; then
  echo "[$(date)] ERROR: NLB hostname not available after 10 minutes"
  kubectl describe svc ingress-nginx-controller -n ingress-nginx
  exit 1
fi

echo "[$(date)] Installing Rancher..."
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update

helm upgrade --install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --create-namespace \
  --set hostname=${var.rancher_hostname} \
  --set bootstrapPassword=${var.rancher_bootstrap_password} \
  --set ingress.tls.source=external \
  --set ingress.ingressClassName=nginx \
  --set replicas=${var.rancher_replicas} \
  --wait --timeout 10m

kubectl annotate ingress rancher \
  -n cattle-system \
  "nginx.ingress.kubernetes.io/ssl-redirect=false" \
  "nginx.ingress.kubernetes.io/force-ssl-redirect=false" \
  --overwrite

echo "[$(date)] Done: https://${var.rancher_hostname}"
echo "[$(date)] DNS: ${var.rancher_hostname} CNAME $NLB_HOSTNAME"