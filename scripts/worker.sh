#!/usr/bin/env bash
# kubernetes ha cluster 
# description: this is the workers script file
# type: kubeadm-calico-full-cluster-bootstrap

OA_MSG=$1
NODE=$2
WORKER_IP=$3
MASTER_TYPE=$4

if [ $MASTER_TYPE = "single" ]; then
    $(cat /vagrant/kubeadm-init.out | grep -A 2 "kubeadm join" | sed -e 's/^[ \t]*//' | tr '\n' ' ' | sed -e 's/ \\ / /g')
else
    $(cat /vagrant/workers-join.out | sed -e 's/^[ \t]*//' | tr '\n' ' ' | sed -e 's/ \\ / /g')
fi

echo KUBELET_EXTRA_ARGS=--node-ip=$WORKER_IP > /etc/default/kubelet

systemctl restart kubelet
