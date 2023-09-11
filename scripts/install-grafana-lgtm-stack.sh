#!/bin/bash

echo "Installing Loki, Grafana, Tempo, and Mimir (Grafana LGTM stack) to Kubernetes Cluster"

kubectl create namespace monitoring
printf "\n\n\n"

echo "Installing Promtail and Loki..."
echo "============================================================="
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm upgrade \
  --install grafana-operator grafana/grafana-agent-operator \
  --values ./helm/values/grafana-agent-values.yaml \
  -n monitoring

helm upgrade \
  --install promtail grafana/promtail \
  --values ./helm/values/promtail-values.yaml \
  -n monitoring

helm upgrade \
  --install loki-distributed grafana/loki-distributed \
  --values ./helm/values/loki-distributed-values.yaml \
  -n monitoring
echo "============================================================="
printf "\n\n\n"

echo "Installing Grafana and Prometheus..."
echo "============================================================="

helm repo add prometheus https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade \
  --install prometheus-community prometheus-community/kube-prometheus-stack \
  --values ./helm/values/grafana-prometheus-values.yaml \
  -n monitoring

# echo "Creating a Grafana AWS ALB to access dashboards from a public URL"
# kubectl apply -f ./kubernetes/manifests/grafana-ingress.yaml
# grafana_ingress_url=$(kubectl get ingress/ingress-grafana -n monitoring | awk '{print $4}')
# printf "Grafana ALB URL\n$grafana_ingress_url\n"
echo "============================================================="
printf "\n\n\n"

echo "Installing Tempo..."
echo "============================================================="
helm upgrade \
  --install tempo grafana/tempo-distributed \
  --values ./helm/values/tempo-values.yaml \
  -n monitoring
echo "============================================================="
printf "\n\n\n"

echo "Installing Mimir..."
echo "============================================================="
helm upgrade \
  --install mimir grafana/mimir-distributed \
  --values ./helm/values/mimir-values.yaml \
  -n monitoring
echo "============================================================="
