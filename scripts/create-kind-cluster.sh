#!/bin/bash

# Create Kind Cluster
kind create cluster --name demo-cluster --config=./kubernetes/local/cluster-config.yaml

# Pause before creating the ingress controller
sleep 5

# Install Kind Ingress Nginx Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

echo "Installing ArgoCD to Kubernetes Cluster"
kubectl create namespace argocd

# In-progress: Testing ArgoCD to route with Nginx Ingress Controller
# Not working yet to expose ArgoCD UI with Nginx Ingress Controller
# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# kubectl apply -f ./kubernetes/local/ingress-argocd.yaml

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm upgrade \
  --install argo-cd argo/argo-cd \
  --values ./kubernetes/helm/local/values/argocd-values.yaml \
  -n argocd

# kubectl create -f ./kubernetes/local/ingress-argocd.yaml

echo "Installing Loki, Grafana, Tempo, and Mimir (Grafana LGTM stack) to Kubernetes Cluster"

kubectl create namespace monitoring
printf "\n\n\n"

echo "Installing Grafana Agent and Loki..."
echo "============================================================="
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm upgrade \
  --install grafana-operator grafana/grafana-agent-operator \
  --values ./kubernetes/helm/local/values/grafana-agent-values.yaml \
  -n monitoring

helm upgrade \
  --install promtail grafana/promtail \
  --values ./kubernetes/helm/local/values/promtail-values.yaml \
  -n monitoring

helm upgrade \
  --install loki-distributed grafana/loki-distributed \
  --values ./kubernetes/helm/local/values/loki-values.yaml \
  -n monitoring
echo "============================================================="
printf "\n\n\n"

echo "Installing Tempo..."
echo "============================================================="
helm upgrade \
  --install tempo grafana/tempo-distributed \
  --values ./kubernetes/helm/local/values/tempo-values.yaml \
  -n monitoring
echo "============================================================="
printf "\n\n\n"

echo "Installing Mimir..."
echo "============================================================="
helm upgrade \
  --install mimir grafana/mimir-distributed \
  --values ./kubernetes/helm/local/values/mimir-values.yaml \
  -n monitoring
echo "============================================================="

echo "Installing Grafana and Prometheus..."
echo "============================================================="

helm repo add prometheus https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade \
  --install prometheus-community prometheus-community/kube-prometheus-stack \
  --values ./kubernetes/helm/local/values/grafana-prometheus-values.yaml \
  -n monitoring
echo "============================================================="
printf "\n\n\n"

sleep 10

# Run the microservices load test to genereate logs and traces
kubectl apply -f ./kubernetes/local/microservices-loadtest.yaml

Wait for prometheus-community-grafana deployment to be ready
kubectl wait --namespace monitoring \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=grafana \
  --timeout=90s

# Export the Grafana URL on localhost:3000
kubectl port-forward service/prometheus-community-grafana 3000:80 -n monitoring
