#!/usr/bin/env bash
# Expõe as três aplicações no poi-atividades: 150.165.85.77:800X -> VM:3000X (NodePort).
# Uso (no notebook, com o openrc carregado): bash infra/loadbalancer.sh
set -euo pipefail
SUBNET=17de9c72-e5dc-4da0-ae0a-013f7e42400e
LB=$(openstack loadbalancer list -f value -c id -c vip_address | awk '$2=="10.5.8.242"{print $1}')
VM_IP=$(openstack server show vm-k8s-grupo1 -f json -c addresses | python3 -c "import sys,json; a=json.load(sys.stdin)['addresses']; print(a['provider'][0] if isinstance(a,dict) else a.split('=')[1])")
esperar_lb() { while [ "$(openstack loadbalancer show $LB -f value -c provisioning_status)" != "ACTIVE" ]; do sleep 5; done; }

for item in cpu:8001:30001 mem:8002:30002 io:8003:30003; do
  IFS=: read -r app porta_lb nodeport <<< "$item"
  echo "== $app: $porta_lb -> $VM_IP:$nodeport"
  openstack loadbalancer listener create --name k8s-$app-grupo1 --protocol HTTP --protocol-port $porta_lb $LB -f value -c id; esperar_lb
  openstack loadbalancer pool create --name pool-k8s-$app-grupo1 --listener k8s-$app-grupo1 --protocol HTTP --lb-algorithm ROUND_ROBIN -f value -c id; esperar_lb
  openstack loadbalancer member create --name vm-k8s-grupo1-$app --subnet-id $SUBNET --address $VM_IP --protocol-port $nodeport pool-k8s-$app-grupo1 -f value -c id; esperar_lb
  openstack loadbalancer healthmonitor create --name hm-k8s-$app-grupo1 --delay 5 --timeout 5 --max-retries 3 \
    --type HTTP --http-method GET --url-path /health --expected-codes 200 pool-k8s-$app-grupo1 -f value -c id; esperar_lb
done

sleep 20
for app in cpu mem io; do
  openstack loadbalancer member list pool-k8s-$app-grupo1 -c name -c protocol_port -c operating_status
done
