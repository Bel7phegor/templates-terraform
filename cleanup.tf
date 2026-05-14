resource "null_resource" "cleanup_nlb" {
  count = local.should_create_bastion ? 1 : 0

  triggers = {
    cluster_name = var.enable_eks ? aws_eks_cluster.main[0].name : ""
    region       = var.region
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Cleaning up NLBs in VPC..."

      # Tìm tất cả NLB có tag của cluster
      LB_ARNS=$(aws elbv2 describe-load-balancers \
        --region ${self.triggers.region} \
        --query "LoadBalancers[*].LoadBalancerArn" \
        --output text)

      for ARN in $LB_ARNS; do
        TAGS=$(aws elbv2 describe-tags \
          --resource-arns $ARN \
          --region ${self.triggers.region} \
          --query "TagDescriptions[0].Tags" \
          --output json)

        if echo "$TAGS" | grep -q "${self.triggers.cluster_name}"; then
          echo "Deleting NLB: $ARN"
          aws elbv2 delete-load-balancer \
            --load-balancer-arn $ARN \
            --region ${self.triggers.region}
        fi
      done

      echo "Waiting 60s for NLBs to be fully deleted..."
      sleep 60
    EOT
  }

  depends_on = [aws_instance.bastion]
}