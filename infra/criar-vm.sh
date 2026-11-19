#!/usr/bin/env bash
# Cria a VM do cluster e o acesso SSH pelo poi-atividades.
# Uso (no notebook, com o openrc carregado): bash infra/criar-vm.sh
set -euo pipefail
VM=vm-k8s-grupo1
SUBNET=17de9c72-e5dc-4da0-ae0a-013f7e42400e
LB=$(openstack loadbalancer list -f value -c id -c vip_address | awk '$2=="10.5.8.242"{print $1}')
esperar_lb() { while [ "$(openstack loadbalancer show $LB -f value -c provisioning_status)" != "ACTIVE" ]; do sleep 5; done; }

# NodePorts das aplicações no grupo de segurança (a porta 22 já está liberada)
openstack security group rule create --ingress --protocol tcp --dst-port 30001:30003 sg-grupo1 || true

# VM: Ubuntu 24.04, 4 vCPUs, 8 GB de RAM (general.large)
openstack server create --flavor general.large --image ubuntu-24.04 \
  --key-name chave-grupo1 --security-group sg-grupo1 --network provider --wait $VM
VM_IP=$(openstack server show $VM -f json -c addresses | python3 -c "import sys,json; a=json.load(sys.stdin)['addresses']; print(a['provider'][0] if isinstance(a,dict) else a.split('=')[1])")
echo "IP da VM: $VM_IP"

# SSH: 150.165.85.77:2201 -> VM:22
openstack loadbalancer listener create --name ssh-k8s-grupo1 --protocol TCP --protocol-port 2201 $LB -f value -c id; esperar_lb
openstack loadbalancer pool create --name pool-ssh-k8s-grupo1 --listener ssh-k8s-grupo1 --protocol TCP --lb-algorithm ROUND_ROBIN -f value -c id; esperar_lb
openstack loadbalancer member create --name $VM-ssh --subnet-id $SUBNET --address $VM_IP --protocol-port 22 pool-ssh-k8s-grupo1 -f value -c id; esperar_lb
openstack loadbalancer healthmonitor create --name hm-ssh-k8s-grupo1 --delay 5 --timeout 5 --max-retries 3 --type TCP pool-ssh-k8s-grupo1 -f value -c id; esperar_lb
echo "Pronto. IP da VM: $VM_IP"
