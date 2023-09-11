#!/bin/bash

# Deleting AWS ALBs
kubectl delete -f ./kubernetes/manifests/grafana-ingress.yaml

# Deleting the microservices
kubectl delete -f ./release/kubernetes-manifests-tracing.yaml
kubectl delete -f ./release/kubernetes-manifests.yaml
