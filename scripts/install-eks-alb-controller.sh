#!/bin/bash

# Add the AWS ELB Service Account to the EKS Cluster
# https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
# https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html

EKS_CLUSTER_NAME="eks-microservices-default"
EKS_ALB_NAME="aws-load-balancer-controller"

# Replace the AWS_ACCOUNT_ID in the alb-controller-service-account.yaml file
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
sed -i "" "s/{{AWS_ACCOUNT_ID}}/$AWS_ACCOUNT_ID/g" ./kubernetes/manifests/alb-controller-service-account.yaml

kubectl create -f ./kubernetes/manifests/alb-controller-service-account.yaml
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
helm install $EKS_ALB_NAME eks/$EKS_ALB_NAME \
  -n kube-system \
  --set clusterName=$EKS_CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=$EKS_ALB_NAME

# Verify the ELB Controller is running
kubectl rollout status deployment/$EKS_ALB_NAME -n kube-system --timeout=180s
echo "Successfully installed AWS ELB Controller to Kubernetes Cluster!!"

# Revert the alb-controller-service-account.yaml file changes
sed -i "" "s/$AWS_ACCOUNT_ID/{{AWS_ACCOUNT_ID}}/g" ./kubernetes/manifests/alb-controller-service-account.yaml
