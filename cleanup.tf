resource "null_resource" "cleanup_nlb" {
  count = local.should_create_bastion ? 1 : 0

  triggers = {
    cluster_name = var.enable_eks ? var.eks_cluster_name : ""
    region       = var.region
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Cleaning up NLBs for cluster: ${self.triggers.cluster_name}"

      LB_ARNS=$(aws elbv2 describe-load-balancers \
        --region ${self.triggers.region} \
        --query "LoadBalancers[*].LoadBalancerArn" \
        --output text 2>/dev/null || echo "")

      if [ -z "$LB_ARNS" ]; then
        echo "No load balancers found"
        exit 0
      fi

      for ARN in $LB_ARNS; do
        TAGS=$(aws elbv2 describe-tags \
          --resource-arns $ARN \
          --region ${self.triggers.region} \
          --query "TagDescriptions[0].Tags" \
          --output json 2>/dev/null || echo "[]")

        if echo "$TAGS" | grep -q "${self.triggers.cluster_name}"; then
          echo "Deleting NLB: $ARN"
          aws elbv2 delete-load-balancer \
            --load-balancer-arn $ARN \
            --region ${self.triggers.region} || true
        fi
      done

      echo "Waiting 60s for NLBs to be deleted..."
      sleep 60
      echo "Cleanup complete"
    EOT
  }

  depends_on = [aws_instance.bastion]
}