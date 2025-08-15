# -*- mode: ruby -*-
# vi: set ft=ruby :

# Orchestrator Project - K3s Cluster for Microservices
Vagrant.configure("2") do |config|
  # Use Ubuntu 22.04 LTS
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_check_update = false

  # K3s Master Node
  config.vm.define "master" do |master|
    master.vm.hostname = "k3s-master"
    master.vm.network "private_network", ip: "192.168.56.10"
    
    master.vm.provider "virtualbox" do |vb|
      vb.name = "k3s-master"
      vb.memory = "2048"
      vb.cpus = 2
    end

    # Install K3s master
    master.vm.provision "shell", inline: <<-SHELL
      # Update system
      apt-get update -q
      
      # Install K3s master
      curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--bind-address=192.168.56.10 --node-external-ip=192.168.56.10 --flannel-iface=enp0s8" sh -
      
      # Wait for K3s to be ready
      while ! kubectl get nodes &> /dev/null; do
        echo "Waiting for K3s master to be ready..."
        sleep 5
      done
      
      # Setup kubeconfig for vagrant user
      mkdir -p /home/vagrant/.kube
      cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
      chown vagrant:vagrant /home/vagrant/.kube/config
      
      # Save node token for agent
      cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token
      
      # Copy kubeconfig to host (replace server IP)
      cp /etc/rancher/k3s/k3s.yaml /vagrant/kubeconfig
      sed -i 's/127.0.0.1/192.168.56.10/g' /vagrant/kubeconfig
      
      echo "✅ K3s master node is ready!"
    SHELL
  end

  # K3s Agent Node
  config.vm.define "agent" do |agent|
    agent.vm.hostname = "k3s-agent"
    agent.vm.network "private_network", ip: "192.168.56.11"
    
    agent.vm.provider "virtualbox" do |vb|
      vb.name = "k3s-agent"
      vb.memory = "2048"
      vb.cpus = 2
    end

    # Install K3s agent
    agent.vm.provision "shell", inline: <<-SHELL
      # Update system
      apt-get update -q
      
      # Wait for master and node token
      while [ ! -f /vagrant/node-token ]; do
        echo "Waiting for master node token..."
        sleep 5
      done
      
      # Install K3s agent
      curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.10:6443 K3S_TOKEN=$(cat /vagrant/node-token) INSTALL_K3S_EXEC="--flannel-iface=enp0s8" sh -
      
      echo "✅ K3s agent node is ready!"
    SHELL
  end
end
