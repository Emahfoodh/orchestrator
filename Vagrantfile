# -*- mode: ruby -*-
# vi: set ft=ruby :

# CRUD Master - Multi-VM Vagrant Configuration (Alpine Linux)
# Creates three VMs for distributed microservices architecture:
# 1. Gateway VM (192.168.56.10) - API Gateway
# 2. Inventory VM (192.168.56.11) - Inventory Service + Database
# 3. Billing VM (192.168.56.12) - Billing Service + Database + RabbitMQ

Vagrant.configure("2") do |config|
  # Base box configuration - Alpine Linux
  config.vm.box = "generic/alpine319"
  config.vm.box_check_update = false

  # VM specifications
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
    vb.cpus = 2
    vb.customize ["modifyvm", :id, "--audio", "none"]
  end

  # Enable synced folders for all VMs
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

  # Common provisioning script for all VMs
  $common_script = <<-SCRIPT
    # Update system
    apk update
    apk upgrade

    # Install common dependencies
    apk add --no-cache \
      curl \
      wget \
      git \
      python3 \
      py3-pip \
      py3-virtualenv \
      postgresql-client \
      ca-certificates \
      openrc \
      docker \
      docker-compose \
      bash \
      shadow

    # Start and enable Docker
    rc-update add docker boot
    service docker start

    # Add vagrant user to docker group
    addgroup vagrant docker

    # Create Python virtual environment directory
    mkdir -p /home/vagrant/.venv
    chown vagrant:vagrant /home/vagrant/.venv

    # Wait for shared folder to be available
    echo "Waiting for shared folder to be available..."
    timeout=30
    while [ $timeout -gt 0 ] && [ ! -d /vagrant ]; do
      sleep 1
      timeout=$((timeout - 1))
    done

    # Copy project files to VM
    if [ -d /vagrant ] && [ ! -d /home/vagrant/crud-master ]; then
      echo "Copying project files from /vagrant to /home/vagrant/crud-master"
      cp -r /vagrant /home/vagrant/crud-master
      chown -R vagrant:vagrant /home/vagrant/crud-master
      # Make scripts executable
      chmod +x /home/vagrant/crud-master/scripts/*.sh
      echo "Project files copied successfully"
    elif [ ! -d /vagrant ]; then
      echo "Warning: /vagrant directory not found, shared folder may not be working"
    else
      echo "Project files already exist in VM"
    fi

    echo "Common setup completed for Alpine Linux"
  SCRIPT

  # Gateway VM Configuration
  config.vm.define "gateway" do |gateway|
    gateway.vm.hostname = "crud-gateway"
    gateway.vm.network "private_network", ip: "192.168.56.10"
    
    # Port forwarding for API Gateway
    gateway.vm.network "forwarded_port", guest: 5000, host: 5000, host_ip: "127.0.0.1"
    
    gateway.vm.provider "virtualbox" do |vb|
      vb.name = "CRUD-Gateway"
      vb.memory = "1024"
      vb.cpus = 1
    end

    gateway.vm.provision "shell", inline: $common_script

    gateway.vm.provision "shell", inline: <<-SCRIPT
      echo "Setting up Gateway VM..."
      
      # Update environment configuration for VM deployment
      cd /home/vagrant/crud-master
      
      # Update .env file for VM IPs
      cat > .env << 'EOF'
# Database Configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
INVENTORY_DB_NAME=movies_db
BILLING_DB_NAME=billing_db

# Database Connection Settings (VM IPs)
INVENTORY_DB_HOST=192.168.56.11
INVENTORY_DB_PORT=5435
BILLING_DB_HOST=192.168.56.12
BILLING_DB_PORT=5436

# API Configuration
API_GATEWAY_PORT=5000
INVENTORY_API_PORT=8080
BILLING_API_PORT=8081

# Network Configuration (VM IPs)
GATEWAY_VM_IP=192.168.56.10
INVENTORY_VM_IP=192.168.56.11
BILLING_VM_IP=192.168.56.12

# RabbitMQ Configuration
RABBITMQ_HOST=192.168.56.12
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest
RABBITMQ_QUEUE=billing_queue
RABBITMQ_MANAGEMENT_PORT=15672

# Application URLs (VM IPs)
INVENTORY_API_URL=http://192.168.56.11:8080
BILLING_API_URL=http://192.168.56.12:8081
API_GATEWAY_URL=http://192.168.56.10:5000

# Debug Mode
DEBUG=True
EOF

      # Update API Gateway .env file
      cat > srcs/api-gateway/.env << 'EOF'
INVENTORY_API_URL=http://192.168.56.11:8080
RABBITMQ_HOST=192.168.56.12
RABBITMQ_QUEUE=billing_queue
API_GATEWAY_PORT=5000

# External Services (VM IPs)
INVENTORY_API_URL=http://192.168.56.11:8080

# RabbitMQ Configuration (VM IP)
RABBITMQ_HOST=192.168.56.12
RABBITMQ_QUEUE=billing_queue

# Server Configuration
HOST=0.0.0.0
API_GATEWAY_PORT=5000
DEBUG=True
EOF

      # Create startup script for Gateway VM
      cat > /home/vagrant/start_gateway.sh << 'EOF'
#!/bin/bash
cd /home/vagrant/crud-master/scripts
./start_gateway.sh
EOF
      chmod +x /home/vagrant/start_gateway.sh
      chown vagrant:vagrant /home/vagrant/start_gateway.sh

      echo "Gateway VM setup completed"
      echo "To start the API Gateway: vagrant ssh gateway -c '/home/vagrant/start_gateway.sh'"
    SCRIPT
  end

  # Inventory VM Configuration
  config.vm.define "inventory" do |inventory|
    inventory.vm.hostname = "crud-inventory"
    inventory.vm.network "private_network", ip: "192.168.56.11"
    
    # Port forwarding for Inventory API and Database
    inventory.vm.network "forwarded_port", guest: 8080, host: 8080, host_ip: "127.0.0.1"
    inventory.vm.network "forwarded_port", guest: 5435, host: 5435, host_ip: "127.0.0.1"
    
    inventory.vm.provider "virtualbox" do |vb|
      vb.name = "CRUD-Inventory"
      vb.memory = "2048"
      vb.cpus = 2
    end

    inventory.vm.provision "shell", inline: $common_script

    inventory.vm.provision "shell", inline: <<-SCRIPT
      echo "Setting up Inventory VM..."
      
      cd /home/vagrant/crud-master
      
      # Update inventory app .env file
      cat > srcs/inventory-app/.env << 'EOF'
# Database Configuration (Local PostgreSQL container)
DATABASE_URI=postgresql://postgres:postgres@localhost:5435/movies_db

# Server Configuration
HOST=0.0.0.0
PORT=8080
DEBUG=True
EOF

      # Create startup script for Inventory VM
      cat > /home/vagrant/start_inventory_vm.sh << 'EOF'
#!/bin/bash
echo "Starting Inventory VM services..."

cd /home/vagrant/crud-master/scripts

# Setup database first
echo "Setting up inventory database..."
./setup_inventory_db.sh --setup

# Wait a moment for database to be ready
sleep 5

# Start the inventory service
echo "Starting inventory service..."
./start_inventory.sh
EOF
      chmod +x /home/vagrant/start_inventory_vm.sh
      chown vagrant:vagrant /home/vagrant/start_inventory_vm.sh

      echo "Inventory VM setup completed"
      echo "To start Inventory services: vagrant ssh inventory -c '/home/vagrant/start_inventory_vm.sh'"
    SCRIPT
  end

  # Billing VM Configuration
  config.vm.define "billing" do |billing|
    billing.vm.hostname = "crud-billing"
    billing.vm.network "private_network", ip: "192.168.56.12"
    
    # Port forwarding for Billing API, Database, and RabbitMQ
    billing.vm.network "forwarded_port", guest: 8081, host: 8081, host_ip: "127.0.0.1"
    billing.vm.network "forwarded_port", guest: 5436, host: 5436, host_ip: "127.0.0.1"
    billing.vm.network "forwarded_port", guest: 5672, host: 5672, host_ip: "127.0.0.1"
    billing.vm.network "forwarded_port", guest: 15672, host: 15672, host_ip: "127.0.0.1"
    
    billing.vm.provider "virtualbox" do |vb|
      vb.name = "CRUD-Billing"
      vb.memory = "2048"
      vb.cpus = 2
    end

    billing.vm.provision "shell", inline: $common_script

    billing.vm.provision "shell", inline: <<-SCRIPT
      echo "Setting up Billing VM..."
      
      cd /home/vagrant/crud-master
      
      # Update billing app .env file
      cat > srcs/billing-app/.env << 'EOF'
# Database Configuration (Local PostgreSQL container)
DATABASE_URI=postgresql://postgres:postgres@localhost:5436/billing_db

# RabbitMQ Configuration (Local)
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest
RABBITMQ_QUEUE=billing_queue

# Server Configuration
HOST=0.0.0.0
PORT=8081
DEBUG=True
EOF

      # Create startup script for Billing VM
      cat > /home/vagrant/start_billing_vm.sh << 'EOF'
#!/bin/bash
echo "Starting Billing VM services..."

cd /home/vagrant/crud-master/scripts

# Setup database first
echo "Setting up billing database..."
./setup_billing_db.sh --setup

# Wait a moment for database to be ready
sleep 5

# Start the billing service (includes RabbitMQ setup)
echo "Starting billing service..."
./start_billing.sh
EOF
      chmod +x /home/vagrant/start_billing_vm.sh
      chown vagrant:vagrant /home/vagrant/start_billing_vm.sh

      echo "Billing VM setup completed"
      echo "To start Billing services: vagrant ssh billing -c '/home/vagrant/start_billing_vm.sh'"
    SCRIPT
  end

  # Post-provisioning message
  config.vm.provision "shell", inline: <<-SCRIPT
    echo ""
    echo "=============================================="
    echo "CRUD Master VM Setup Complete!"
    echo "=============================================="
    echo ""
    echo "VM Network Configuration:"
    echo "  Gateway VM:   192.168.56.10:5000"
    echo "  Inventory VM: 192.168.56.11:8080"
    echo "  Billing VM:   192.168.56.12:8081"
    echo ""
    echo "Port Forwarding (from host):"
    echo "  API Gateway:      localhost:5000"
    echo "  Inventory API:    localhost:8080"
    echo "  Billing API:      localhost:8081"
    echo "  RabbitMQ UI:      localhost:15672"
    echo ""
    echo "To start services:"
    echo "  vagrant ssh gateway -c '/home/vagrant/start_gateway.sh'"
    echo "  vagrant ssh inventory -c '/home/vagrant/start_inventory_vm.sh'"
    echo "  vagrant ssh billing -c '/home/vagrant/start_billing_vm.sh'"
    echo ""
    echo "Or start all VMs in separate terminals:"
    echo "  Terminal 1: vagrant ssh gateway"
    echo "  Terminal 2: vagrant ssh inventory"
    echo "  Terminal 3: vagrant ssh billing"
    echo ""
  SCRIPT
end
