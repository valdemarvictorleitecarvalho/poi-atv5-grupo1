#!/usr/bin/env bash
# Sobe o cluster Minikube (driver docker) publicando os NodePorts na VM.
set -euo pipefail
minikube start --driver=docker --cpus=3 --memory=6g \
  --ports=30001:30001 --ports=30002:30002 --ports=30003:30003
minikube addons enable metrics-server
kubectl get nodes -o wide
