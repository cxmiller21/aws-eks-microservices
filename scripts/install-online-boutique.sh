#!/bin/bash

# Create the microservices
kubectl apply -f ./release/kubernetes-manifests-tracing.yaml

# Wait for the ALB Ingress Controller to be ready
# There isn't a wait option on the ingress controller so we'll just sleep for a bit
sleep 30

echo "Successfully installed the Online Boutique microservices in the Kubernetes Cluster!!"

ingress_url=$(kubectl get ingress/ingress-microservices -n online-boutique | awk '{print $4}')
echo "View the ALB URL at"
echo "$ingress_url"
