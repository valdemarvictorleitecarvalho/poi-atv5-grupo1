#!/usr/bin/env bash
# Instala Docker, Minikube e kubectl na VM (Ubuntu 24.04).
set -euo pipefail
sudo apt-get update
sudo apt-get install -y docker.io conntrack curl git
sudo usermod -aG docker "$USER"

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

KVER=$(curl -Ls https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KVER}/bin/linux/amd64/kubectl"
sudo install -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl

minikube version
kubectl version --client
echo "Saia (exit) e entre de novo na VM para o grupo docker funcionar."
