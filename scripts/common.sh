#!/usr/bin/env bash
# kubernetes ha cluster 
# description: this is a common script file for masters and workers

#variable definitions
OA_MSG=$1
BOX_IMAGE=$2

export DEBIAN_FRONTEND=noninteractive

### Install packages to allow apt to use a repository over HTTPS
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common

### Add Kubernetes GPG key
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

### Kubernetes Repo (NO OFFICIAL FOCAL RELEASE YET, USING DEBIAN XENIAL)
add-apt-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

### Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

### Add Docker apt repository FOR UBUNTU SERVER 20.04 (focal)
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

### Refresh apt cache
apt-get update

apt-get install -y nfs-kernel-server nfs-common avahi-daemon libnss-mdns traceroute htop httpie bash-completion ruby docker-ce kubeadm kubelet kubectl

cat /vagrant/shared/hosts.out >> /etc/hosts

# Setup Docker daemon
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker
systemctl daemon-reload
systemctl restart docker

if [[ ! $BOX_IMAGE =~ "kuberverse" ]]
then
  kubeadm config images pull
fi
