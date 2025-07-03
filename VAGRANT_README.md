# CRUD Master - Vagrant Multi-VM Setup

This guide explains how to set up and test the distributed CRUD Master microservices architecture using Vagrant with Alpine Linux VMs.

## Architecture Overview

The setup creates three Alpine Linux VMs:

```
┌─────────────────────────────────────────────────────────────────┐
│                         Host Machine                           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Gateway VM    │  │  Inventory VM   │  │   Billing VM    │ │
│  │ 192.168.56.10   │  │ 192.168.56.11   │  │ 192.168.56.12   │ │
│  │                 │  │                 │  │                 │ │
│  │  API Gateway    │  │ Inventory API   │  │  Billing API    │ │
│  │   (Port 5000)   │  │  (Port 8080)    │  │  (Port 8081)    │ │
│  │                 │  │                 │  │                 │ │
│  │                 │  │   PostgreSQL    │  │   PostgreSQL    │ │
│  │                 │  │   Container     │  │   Container     │ │
│  │                 │  │  (Port 5435)    │  │  (Port 5436)    │ │
│  │                 │  │                 │  │                 │ │
│  │                 │  │                 │  │    RabbitMQ     │ │
│  │                 │  │                 │  │   Container     │ │
│  │                 │  │                 │  │   (Port 5672)   │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- **VirtualBox**: Version 6.1+ or 7.0+
- **Vagrant**: Version 2.3+
- **Host Requirements**: 8GB RAM minimum (VMs need 5GB total)
- **Network**: Private network 192.168.56.x available

### Installation

**On Ubuntu/Debian:**
```bash
# Install VirtualBox
sudo apt update
sudo apt install virtualbox virtualbox-ext-pack

# Install Vagrant
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant
```

**On macOS:**
```bash
# Using Homebrew
brew install --cask virtualbox
brew install --cask vagrant
```

**On Windows:**
- Download VirtualBox from: https://www.virtualbox.org/wiki/Downloads
- Download Vagrant from: https://www.vagrantup.com/downloads

## Quick Start

### 1. Clone and Navigate
```bash
git clone <repository-url>
cd crud-master
```

### 2. Start All VMs
```bash
# This will download Alpine Linux and provision all 3 VMs
vagrant up

# Expected output:
# ==> gateway: Machine booted and ready!
# ==> inventory: Machine booted and ready!
# ==> billing: Machine booted and ready!
```

### 3. Start Services (Method 1 - All at once)
```bash
# Terminal 1 - Start Gateway
vagrant ssh gateway -c '/home/vagrant/start_gateway.sh'

# Terminal 2 - Start Inventory (in new terminal)
vagrant ssh inventory -c '/home/vagrant/start_inventory_vm.sh'

# Terminal 3 - Start Billing (in new terminal)
vagrant ssh billing -c '/home/vagrant/start_billing_vm.sh'
```

### 4. Test the Setup
```bash
# Test API Gateway
curl http://localhost:5000/api/movies

# Test Inventory Service directly
curl http://localhost:8080/api/movies

# Test Billing Service directly
curl http://localhost:8081/api/health

# Add a movie via Gateway
curl -X POST http://localhost:5000/api/movies \
  -H "Content-Type: application/json" \
  -d '{"title": "Test Movie", "description": "VM Test"}'

# Send billing request via Gateway
curl -X POST http://localhost:5000/api/billing \
  -H "Content-Type: application/json" \
  -d '{"user_id": "vm_user", "number_of_items": "3", "total_amount": "45.99"}'
```

## Detailed Setup Guide

### Step-by-Step VM Management

#### Start Individual VMs
```bash
# Start only specific VMs
vagrant up gateway
vagrant up inventory
vagrant up billing

# Check VM status
vagrant status
```

#### SSH into VMs
```bash
# SSH into specific VMs
vagrant ssh gateway
vagrant ssh inventory
vagrant ssh billing

# Once inside a VM, you can:
# - Check Docker containers: docker ps
# - View logs: docker logs <container_name>
# - Check services: ps aux | grep python
```

#### Manual Service Startup (Method 2)
```bash
# SSH into each VM and start services manually

# Gateway VM
vagrant ssh gateway
cd /home/vagrant/crud-master/scripts
./start_gateway.sh

# Inventory VM (in new terminal)
vagrant ssh inventory
cd /home/vagrant/crud-master/scripts
./setup_inventory_db.sh --setup
./start_inventory.sh

# Billing VM (in new terminal)
vagrant ssh billing
cd /home/vagrant/crud-master/scripts
./setup_billing_db.sh --setup
./start_billing.sh
```

## Testing the Distributed Architecture

### 1. Service Health Checks
```bash
# Check all services are responding
echo "Testing Gateway..."
curl -f http://localhost:5000/ && echo "✓ Gateway OK" || echo "✗ Gateway Failed"

echo "Testing Inventory..."
curl -f http://localhost:8080/api/movies && echo "✓ Inventory OK" || echo "✗ Inventory Failed"

echo "Testing Billing..."
curl -f http://localhost:8081/api/health && echo "✓ Billing OK" || echo "✗ Billing Failed"

echo "Testing RabbitMQ..."
curl -f http://localhost:15672 && echo "✓ RabbitMQ OK" || echo "✗ RabbitMQ Failed"
```

### 2. Complete API Test Suite
```bash
# Run the comprehensive test suite
python3 api_testers.py

# Or use curl-based tests
./curl_tests.sh
```

### 3. Manual Integration Tests

#### Test Movie Operations
```bash
# Create movies
curl -X POST http://localhost:5000/api/movies \
  -H "Content-Type: application/json" \
  -d '{"title": "Alpine Test", "description": "Running on Alpine Linux VMs"}'

curl -X POST http://localhost:5000/api/movies \
  -H "Content-Type: application/json" \
  -d '{"title": "Vagrant Test", "description": "Distributed microservices test"}'

# List movies
curl http://localhost:5000/api/movies

# Search movies
curl "http://localhost:5000/api/movies?title=Alpine"

# Update movie (replace ID with actual ID from list)
curl -X PUT http://localhost:5000/api/movies/1 \
  -H "Content-Type: application/json" \
  -d '{"title": "Alpine Linux", "description": "Updated in VM"}'
```

#### Test Billing Operations
```bash
# Send billing requests
curl -X POST http://localhost:5000/api/billing \
  -H "Content-Type: application/json" \
  -d '{"user_id": "vm_test_1", "number_of_items": "2", "total_amount": "29.99"}'

curl -X POST http://localhost:5000/api/billing \
  -H "Content-Type: application/json" \
  -d '{"user_id": "vm_test_2", "number_of_items": "5", "total_amount": "99.99"}'

# Check processed orders (direct access)
curl http://localhost:8081/api/orders
```

### 4. Database Verification
```bash
# Check inventory database
vagrant ssh inventory -c 'docker exec inventory_postgres psql -U postgres -d movies_db -c "SELECT * FROM movies;"'

# Check billing database
vagrant ssh billing -c 'docker exec billing_postgres psql -U postgres -d billing_db -c "SELECT * FROM orders;"'
```

### 5. Network Connectivity Tests
```bash
# Test inter-VM communication
vagrant ssh gateway -c 'curl http://192.168.56.11:8080/api/movies'
vagrant ssh gateway -c 'curl http://192.168.56.12:8081/api/health'

# Test from inventory VM to billing VM
vagrant ssh inventory -c 'curl http://192.168.56.12:8081/api/health'
```

## Monitoring and Debugging

### View Service Logs
```bash
# Gateway logs
vagrant ssh gateway -c 'tail -f /home/vagrant/crud-master/logs/gateway.log'

# Inventory logs
vagrant ssh inventory -c 'tail -f /home/vagrant/crud-master/logs/inventory.log'

# Billing logs
vagrant ssh billing -c 'tail -f /home/vagrant/crud-master/logs/billing.log'
```

### Check Docker Containers
```bash
# Inventory VM containers
vagrant ssh inventory -c 'docker ps'
vagrant ssh inventory -c 'docker logs inventory_postgres'

# Billing VM containers
vagrant ssh billing -c 'docker ps'
vagrant ssh billing -c 'docker logs billing_postgres'
vagrant ssh billing -c 'docker logs rabbitmq'
```

### Resource Usage
```bash
# Check VM resource usage
vagrant ssh gateway -c 'free -h && df -h'
vagrant ssh inventory -c 'free -h && df -h'
vagrant ssh billing -c 'free -h && df -h'

# Check processes
vagrant ssh inventory -c 'ps aux | grep python'
vagrant ssh billing -c 'ps aux | grep python'
```

## Troubleshooting

### Common Issues

#### VMs Won't Start
```bash
# Check VirtualBox status
vboxmanage list runningvms

# Restart VirtualBox service
sudo systemctl restart vboxdrv

# Check Vagrant status
vagrant global-status
```

#### Port Conflicts
```bash
# Check what's using ports on host
lsof -i :5000  # Gateway
lsof -i :8080  # Inventory
lsof -i :8081  # Billing
lsof -i :5672  # RabbitMQ
lsof -i :15672 # RabbitMQ Management
```

#### Service Won't Start
```bash
# Check if Docker is running in VM
vagrant ssh inventory -c 'sudo service docker status'
vagrant ssh billing -c 'sudo service docker status'

# Restart Docker if needed
vagrant ssh inventory -c 'sudo service docker restart'
vagrant ssh billing -c 'sudo service docker restart'
```

#### Database Connection Issues
```bash
# Check database containers
vagrant ssh inventory -c 'docker exec inventory_postgres pg_isready -U postgres'
vagrant ssh billing -c 'docker exec billing_postgres pg_isready -U postgres'

# Restart database containers
vagrant ssh inventory -c 'docker restart inventory_postgres'
vagrant ssh billing -c 'docker restart billing_postgres'
```

### Reset Everything
```bash
# Stop all VMs
vagrant halt

# Destroy all VMs (will delete all data)
vagrant destroy -f

# Start fresh
vagrant up
```

### Partial Reset
```bash
# Reset just databases
vagrant ssh inventory -c 'docker rm -f inventory_postgres'
vagrant ssh billing -c 'docker rm -f billing_postgres'

# Restart services
vagrant ssh inventory -c '/home/vagrant/start_inventory_vm.sh'
vagrant ssh billing -c '/home/vagrant/start_billing_vm.sh'
```

## Performance Optimization

### VM Resource Allocation
Edit `Vagrantfile` to adjust resources:
```ruby
# For high-performance testing
gateway.vm.provider "virtualbox" do |vb|
  vb.memory = "1024"  # Increase if needed
  vb.cpus = 2         # Increase for better performance
end
```

### Alpine Package Cache
```bash
# Speed up subsequent provisioning
vagrant ssh inventory -c 'sudo apk add --no-cache --virtual build-deps'
```

## Production Considerations

This VM setup simulates a production environment where:
- Each service runs on a separate server
- Services communicate over network (not localhost)
- Each service has its own database
- Message queuing is properly distributed

### Next Steps for Production
1. **Container Orchestration**: Use Kubernetes or Docker Swarm
2. **Load Balancing**: Add nginx or HAProxy
3. **Service Discovery**: Implement Consul or similar
4. **Monitoring**: Add Prometheus + Grafana
5. **Security**: Implement proper authentication and TLS

## Useful Commands

```bash
# Quick status check
vagrant status

# Stop all VMs
vagrant halt

# Start all VMs
vagrant up

# Restart a specific VM
vagrant reload inventory

# Get VM SSH config
vagrant ssh-config gateway

# Forward additional ports
vagrant port gateway

# View VM network info
vagrant ssh gateway -c 'ip addr show'
```

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review VM logs: `vagrant ssh <vm> -c 'dmesg | tail'`
3. Check service logs in each VM
4. Verify network connectivity between VMs
5. Ensure all prerequisites are met

---

**Ready to test?** Start with the Quick Start section and run the health checks to verify everything is working!
