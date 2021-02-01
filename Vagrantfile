# kubernetes high availability cluster
#
# tools used: Vagrant + HAProxy
# provider: libvirt
#
# description: this Vagrantfile creates a cluster with masters and workers
#
# dependencies: 
#
# author: Ole Algoritme (C) 2020
BOX_IMAGE = "generic/ubuntu2004"

# Cluster Privisioning (2 or more masters = HA)
MASTER_COUNT = 2
WORKER_COUNT = 4

# Scaler resources
SCALER_MEMORY = 512
SCALER_CPUS = 2

# Master resources
MASTER_MEMORY = 1024
MASTER_CPUS = 2

# Worker resources
WORKER_MEMORY = 1024
WORKER_CPUS = 2

# Cluster network settings
CLUSTER_NETWORK = "10.8.8.0"

# IP Range of the intra-pod network
POD_CIDR = "172.18.0.0/16"

OA_MSG = "Kubernetes HA Cluster"

COMMON_SCRIPT = "https://raw.githubusercontent.com/olealgoritme/kubernetes-ha-cluster/master/scripts/common.sh"
SCALER_SCRIPT = "https://raw.githubusercontent.com/olealgoritme/kubernetes-ha-cluster/master/scripts/scaler.sh"
MASTER_SCRIPT = "https://raw.githubusercontent.com/olealgoritme/kubernetes-ha-cluster/master/scripts/master.sh"
WORKER_SCRIPT = "https://raw.githubusercontent.com/olealgoritme/kubernetes-ha-cluster/master/scripts/worker.sh"

class KubeCluster

  def initialize
      p "********** #{OA_MSG} **********"
  end

  def defineIp(type,i,kvln)
      case type
      when "master" 
        return kvln.split('.')[0..-2].join('.') + ".#{i + 10}"
      when "worker"
        return kvln.split('.')[0..-2].join('.') + ".#{i + 20}"
      when "scaler"
        return kvln.split('.')[0..-2].join('.') + ".#{i + 50}"
      end
  end
  
  def createScaler(config)
      p "HA Cluster with:"
      p "- 1 Scaler Node"
      p "- #{MASTER_COUNT} Master Nodes"
      p "- #{WORKER_COUNT} Worker Nodes"

      i = 0
      scalerIp = self.defineIp("scaler",i,CLUSTER_NETWORK)

      p "The Scaler #{i} Ip is #{scalerIp}"

      masterIps = Array[]

      (0..MASTER_COUNT-1).each do |m|
        masterIps.push(self.defineIp("master",m,CLUSTER_NETWORK))
      end

      # p masterIps.length
      # masterIps.each {|s| p s}

      config.vm.define "kv-scaler-#{i}" do |scaler|    
        scaler.vm.box = BOX_IMAGE
        scaler.vm.hostname = "kv-scaler-#{i}"
        scaler.vm.network :private_network, ip: scalerIp
        scaler.vm.network "forwarded_port", guest: 6443, host: 6443

        scaler.vm.provider :libvirt do |libvirt|
          libvirt.memory = SCALER_MEMORY
          libvirt.cpus = SCALER_CPUS
        end
       
        $script = <<-SCRIPT
          echo "# Added by OA" > shared/hosts.out
          echo "#{scalerIp} kv-scaler.lab.local kv-scaler.local kv-master" >> shared/hosts.out
          mkdir -p /home/vagrant/scripts
          wget -q #{SCALER_SCRIPT} -O /home/vagrant/scripts/scaler.sh
          chmod +x /home/vagrant/scripts/scaler.sh
          /home/vagrant/scripts/scaler.sh "#{OA_MSG}" #{scalerIp} "#{masterIps}"
        SCRIPT
        scaler.vm.provision "shell", inline: $script
      end
  end

  def createMaster(config)
   
    (0..MASTER_COUNT-1).each do |i|
      masterIp = self.defineIp("master",i,CLUSTER_NETWORK)

      p "The Master #{i} Ip is #{masterIp}"
      config.vm.define "kv-master-#{i}" do |master|
        master.vm.box = BOX_IMAGE
        master.vm.hostname = "kv-master-#{i}"
        master.vm.network :private_network, ip: masterIp
        
        $script = ""

        if MASTER_COUNT == 1
          master.vm.network "forwarded_port", guest: 6443, host: 6443
          $script = <<-SCRIPT
            echo "# Added by OA" > shared/hosts.out
            echo "#{masterIp} kv-master.lab.local kv-master.local kv-master" >> shared/hosts.out
          SCRIPT
        end

        master.vm.provider :libvirt do |libvirt|
          libvirt.memory = MASTER_MEMORY
          libvirt.cpus = MASTER_CPUS
        end

        $script = $script + <<-SCRIPT
          mkdir -p /home/vagrant/scripts
          wget -q #{MASTER_SCRIPT} -O /home/vagrant/scripts/master.sh
          chmod +x /home/vagrant/scripts/master.sh
          /home/vagrant/scripts/master.sh "#{OA_MSG}" #{i} #{POD_CIDR} #{masterIp} #{MASTER_COUNT == 1 ? "single" : "multi"}
        SCRIPT
        master.vm.provision "shell", inline: $script
      end
    end   
  end

  def createWorker(config)
    (0..WORKER_COUNT-1).each do |i|
      workerIp = self.defineIp("worker",i,CLUSTER_NETWORK)

      p "The Worker #{i} Ip is #{workerIp}"

      config.vm.define "kv-worker-#{i}" do |worker|
        worker.vm.box = BOX_IMAGE
        worker.vm.hostname = "kv-worker-#{i}"
        worker.vm.network :private_network, ip: workerIp

        worker.vm.provider :libvirt do |libvirt|
          libvirt.memory = WORKER_MEMORY
          libvirt.cpus = WORKER_CPUS
        end
  
        $script = <<-SCRIPT
          mkdir -p /home/vagrant/scripts
          wget -q #{COMMON_SCRIPT} -O /home/vagrant/scripts/common.sh
          wget -q #{WORKER_SCRIPT} -O /home/vagrant/scripts/worker.sh
          chmod +x /home/vagrant/scripts/common.sh
          chmod +x /home/vagrant/scripts/worker.sh
          /home/vagrant/scripts/common.sh "#{OA_MSG}" #{BOX_IMAGE}
          /home/vagrant/scripts/worker.sh "#{OA_MSG}" #{i} #{workerIp} #{MASTER_COUNT == 1 ? "single" : "multi"}
        SCRIPT
        worker.vm.provision "shell", inline: $script
      end
    end
  end
end

Vagrant.configure("2") do |config|

  cluster = KubeCluster.new()
  cluster.createScaler(config)
  cluster.createMaster(config)
  cluster.createWorker(config)

  config.vm.provision "shell",
   run: "always",
   inline: "swapoff -a"

end
