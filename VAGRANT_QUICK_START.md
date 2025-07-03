# 🚀 Vagrant Quick Start Guide - CRUD Master

**Simple 3-step guide to run the distributed microservices on separate Alpine Linux VMs**

## ⚡ Quick Setup

### Prerequisites
```bash
# Install VirtualBox and Vagrant
sudo apt install virtualbox vagrant  # Ubuntu/Debian
brew install virtualbox vagrant      # macOS
```

### Step 1: Start All VMs
```bash
# Clone and navigate to project
git clone <repository-url>
cd crud-master

# Start all 3 VMs (takes ~5-10 minutes)
vagrant up

# Check VMs are running
vagrant status
# Should show:
# gateway     running (virtualbox)
# inventory   running (virtualbox) 
# billing     running (virtualbox)
```

### Step 2: Start Services (3 separate terminals)

**Terminal 1 - Inventory Service:**
```bash
vagrant ssh inventory -c '/home/vagrant/start_inventory_vm.sh'
# Wait for: "Running on http://127.0.0.1:8080"
```

**Terminal 2 - Billing Service:**
```bash
vagrant ssh billing -c '/home/vagrant/start_billing_vm.sh'
# Wait for: "Running on http://127.0.0.1:8081"
```

**Terminal 3 - Gateway Service:**
```bash
vagrant ssh gateway -c '/home/vagrant/start_gateway.sh'
# Wait for: "Running on http://127.0.0.1:5000"
```

### Step 3: Test Everything Works

**Quick Test (copy & paste):**
```bash
# Test each service
curl http://localhost:8080/api/movies  # Inventory
curl http://localhost:8081/api/health  # Billing
curl http://localhost:5000/api/movies  # Gateway

# Should get responses from all three!
```

**Full Test Suite:**
```bash
python3 api_testers.py
# Should show: "🎉 ALL TESTS PASSED! 🎉"
```

---

## 🎯 Simple API Tests

### Test Inventory (Movies)
```bash
# Get all movies
curl http://localhost:5000/api/movies

# Add a movie
curl -X POST http://localhost:5000/api/movies \
  -H "Content-Type: application/json" \
  -d '{"title": "Test Movie", "description": "My test"}'

# Get movies again (should see your movie)
curl http://localhost:5000/api/movies
```

### Test Billing
```bash
# Send a billing request
curl -X POST http://localhost:5000/api/billing \
  -H "Content-Type: application/json" \
  -d '{"user_id": "123", "number_of_items": "2", "total_amount": "25.99"}'

# Should get: {"message": "Message posted to billing queue"}
```

### Test Gateway Routing
```bash
# Test gateway routes to inventory
curl http://localhost:5000/api/movies

# Test gateway routes to billing  
curl -X POST http://localhost:5000/api/billing \
  -H "Content-Type: application/json" \
  -d '{"user_id": "test", "number_of_items": "1", "total_amount": "10.00"}'
```

---

## 🔧 Management Commands

### VM Control
```bash
# Check VM status
vagrant status

# Stop all VMs
vagrant halt

# Start all VMs
vagrant up

# Restart a specific VM
vagrant reload inventory

# SSH into a VM
vagrant ssh gateway
vagrant ssh inventory  
vagrant ssh billing
```

### Service Control
```bash
# Stop services (Ctrl+C in each terminal)

# Start individual services again
vagrant ssh inventory -c '/home/vagrant/start_inventory_vm.sh'
vagrant ssh billing -c '/home/vagrant/start_billing_vm.sh'
vagrant ssh gateway -c '/home/vagrant/start_gateway.sh'
```

### Reset Everything
```bash
# Complete reset (destroys all VMs and data)
vagrant destroy -f
vagrant up
```

---

## 🚨 Troubleshooting

### Services Won't Start
```bash
# Check if VMs are running
vagrant status

# Check if Docker is running in VMs
vagrant ssh inventory -c 'docker ps'
vagrant ssh billing -c 'docker ps'
```

### Port Conflicts
```bash
# Check what's using ports
lsof -i :5000  # Gateway
lsof -i :8080  # Inventory
lsof -i :8081  # Billing

# Kill conflicting processes if needed
```

### Database Issues
```bash
# Reset databases
vagrant ssh inventory -c 'docker restart inventory_postgres'
vagrant ssh billing -c 'docker restart billing_postgres'
```

---

## 📊 What's Running Where

| Service | VM IP | Host Port | Description |
|---------|-------|-----------|-------------|
| **API Gateway** | 192.168.56.10 | localhost:5000 | Routes requests |
| **Inventory API** | 192.168.56.11 | localhost:8080 | Manages movies |
| **Billing API** | 192.168.56.12 | localhost:8081 | Processes billing |
| **Inventory DB** | 192.168.56.11 | localhost:5435 | PostgreSQL |
| **Billing DB** | 192.168.56.12 | localhost:5436 | PostgreSQL |
| **RabbitMQ** | 192.168.56.12 | localhost:15672 | Message queue |

---

## ✅ Success Checklist

- [ ] All 3 VMs running (`vagrant status`)
- [ ] Inventory service responds (`curl localhost:8080/api/movies`)
- [ ] Billing service responds (`curl localhost:8081/api/health`)
- [ ] Gateway service responds (`curl localhost:5000/api/movies`)
- [ ] Can create movies via gateway
- [ ] Can send billing requests via gateway
- [ ] Full test suite passes (`python3 api_testers.py`)

**🎉 When all checkboxes are ✅, your distributed microservices are working perfectly!**

---

## 💡 Pro Tips

1. **Keep terminals open** - Each service runs in its own terminal
2. **Use Gateway for everything** - Test via `localhost:5000` (routes to other services)
3. **Check logs** - Services show request logs in their terminals
4. **VM communication** - Services talk to each other via VM IPs (192.168.56.x)
5. **Lightweight** - Alpine Linux VMs use minimal resources

**Need help?** Check the logs in each service terminal or run `vagrant ssh <vm>` to debug inside VMs.
