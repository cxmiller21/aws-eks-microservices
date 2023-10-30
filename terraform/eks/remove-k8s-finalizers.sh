#!/bin/bash

# Example: ./remove-k8s-finalizers.sh monitoring ingress

NAMESPACE=$1
TYPE=$2

if [[ $TYPE == "ingress" ]]; then
  if [[ $NAMESPACE == "monitoring" ]]; then
    echo "Removing finalizers from grafana ingress"
    kubectl patch ing ingress-grafana -n $NAMESPACE -p '{"metadata":{"finalizers":null}}' --type=merge \
    || echo "Grafana ingress not found"
  elif [[ $NAMESPACE == "argocd" ]]; then
    echo "Removing finalizers from argocd ingress"
    kubectl patch ing ingress-argocd -n $NAMESPACE -p '{"metadata":{"finalizers":null}}' --type=merge \
    || echo "ArgoCD ingress not found"
  fi
elif [[ $TYPE == "namespace" ]]; then
  TARGET_PORT="8001"
  # Check if any process is using the target port
  if lsof -i :"$TARGET_PORT" > /dev/null; then
    # Get the PID of the process using the target port
    PID=$(lsof -ti :"$TARGET_PORT")
    echo "Process using port $TARGET_PORT has been found with PID: $PID"

    # Terminate the process
    kill "$PID"
    echo "Process (PID: $PID) using port $TARGET_PORT has been terminated."
  else
    echo "No process found using port $TARGET_PORT."
  fi
  echo "Removing finalizers from $NAMESPACE namespace"
  kubectl proxy &
  kubectl get namespace $NAMESPACE -o json | jq '.spec = {"finalizers":[]}' > temp.json
  curl -k -H "Content-Type: application/json" -X PUT --data-binary @temp.json 127.0.0.1:8001/api/v1/namespaces/$NAMESPACE/finalize
  rm temp.json
fi
