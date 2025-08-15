# Microservices Orchestrator on K3s

This project demonstrates a complete microservices architecture deployed on a K3s Kubernetes cluster using Vagrant for infrastructure management. The system consists of inventory management, billing services, and an API gateway, all connected through a message queue.

## Architecture

The microservices architecture includes:

- **Inventory Database**: PostgreSQL database for inventory data
- **Billing Database**: PostgreSQL database for billing data  
- **RabbitMQ**: Message queue for inter-service communication
- **Inventory App**: Python Flask application managing inventory (Port 8080)
- **Billing App**: Python Flask application handling billing (Port 8080)
- **API Gateway**: Python Flask gateway routing requests (Port 3000)

## Prerequisites

Before starting, ensure you have the following installed:

- **Vagrant** (>= 2.0)
- **VirtualBox** (or another Vagrant provider)
- **kubectl** (Kubernetes command-line tool)
- **Docker** (for building images)
- **Docker Hub Account** (for hosting images)

### Installation Commands

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install vagrant virtualbox kubectl docker.io

# macOS (using Homebrew)
brew install vagrant kubectl docker
brew install --cask virtualbox

# Verify installations
vagrant --version
kubectl version --client
docker --version
```

## Project Structure

```
.
├── Manifests/                    # Kubernetes manifests
│   ├── namespaces/              # Namespace definitions
│   ├── secrets/                 # Credentials and secrets
│   ├── databases/               # Database StatefulSets
│   ├── applications/            # Application deployments
│   ├── services/                # Service definitions
│   └── ingress/                 # Ingress controllers
├── Scripts/                     # Deployment and management scripts
│   ├── build-and-push-images.sh
│   ├── deploy-microservices.sh
│   └── cleanup-microservices.sh
├── srcs/                        # Application source code
│   ├── api-gateway/
│   ├── billing-app/
│   └── inventory-app/
├── Vagrantfile                  # VM configuration
├── orchestrator.sh              # Main orchestration script
└── README.md                    # This file
```

## Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd microservices-orchestrator
chmod +x orchestrator.sh Scripts/*.sh
```

### 2. Create K3s Cluster

```bash
./orchestrator.sh create
```

This command will:
- Create and configure two VMs (master and agent)
- Install K3s on both nodes
- Generate kubeconfig for cluster access
- Verify cluster connectivity

### 3. Build and Push Docker Images

```bash
# Login to Docker Hub
docker login

# Build and push all images
./Scripts/build-and-push-images.sh
```

**Important**: Update the image names in the Kubernetes manifests with your Docker Hub username:

```bash
# Update image references in manifests
sed -i 's/inventory-app:latest/YOUR_USERNAME\/inventory-app:latest/g' Manifests/applications/inventory-app.yaml
sed -i 's/billing-app:latest/YOUR_USERNAME\/billing-app:latest/g' Manifests/applications/billing-app.yaml
sed -i 's/api-gateway-app:latest/YOUR_USERNAME\/api-gateway-app:latest/g' Manifests/applications/api-gateway.yaml
```

### 4. Deploy Microservices

```bash
./orchestrator.sh deploy
```

This will deploy:
- Namespace and secrets
- PostgreSQL databases (StatefulSets)
- RabbitMQ message queue
- Application services with auto-scaling
- Ingress configuration

### 5. Verify Deployment

```bash
./orchestrator.sh status
```

Check specific resources:

```bash
export KUBECONFIG=./kubeconfig

# Check all pods
kubectl get pods -n microservices

# Check services
kubectl get services -n microservices

# Check horizontal pod autoscalers
kubectl get hpa -n microservices

# Check persistent volumes
kubectl get pv,pvc -n microservices
```

## Configuration

### Secrets Management

All credentials are stored as Kubernetes secrets:

- **postgres-credentials**: Database username/password
- **rabbitmq-credentials**: RabbitMQ username/password  
- **database-config**: Database names and queue configuration

### Auto-scaling Configuration

- **API Gateway**: Min 1, Max 3 replicas (60% CPU trigger)
- **Inventory App**: Min 1, Max 3 replicas (60% CPU trigger)
- **Billing App**: StatefulSet (no auto-scaling)

### Database Persistence

Databases use StatefulSets with persistent volume claims:
- Storage size: 1Gi per database
- Access mode: ReadWriteOnce
- Data persists across pod restarts

## Usage

### Accessing Services

1. **API Gateway via NodePort**:
   ```bash
   # Get node IP
   kubectl get nodes -o wide
   
   # Access via NodePort
   curl http://<node-ip>:30000/health
   ```

2. **API Gateway via Ingress**:
   ```bash
   # Add to /etc/hosts
   echo "<node-ip> api-gateway.local" | sudo tee -a /etc/hosts
   
   # Access via hostname
   curl http://api-gateway.local/health
   ```

3. **RabbitMQ Management**:
   ```bash
   kubectl port-forward -n microservices svc/rabbitmq 15672:15672
   # Access: http://localhost:15672 (guest/guest)
   ```

### API Endpoints

- **Health Check**: `GET /health`
- **Inventory**: `GET /inventory`, `POST /inventory`
- **Billing**: `GET /billing`, `POST /billing`

### Monitoring and Logs

```bash
# View pod logs
kubectl logs -n microservices <pod-name>

# Follow logs
kubectl logs -n microservices -f <pod-name>

# Execute into pod
kubectl exec -n microservices -it <pod-name> -- /bin/sh
```

## Management Commands

### Orchestrator Script

```bash
./orchestrator.sh create    # Create new cluster
./orchestrator.sh start     # Start existing cluster
./orchestrator.sh stop      # Stop cluster
./orchestrator.sh destroy   # Destroy cluster completely
./orchestrator.sh deploy    # Deploy microservices
./orchestrator.sh cleanup   # Remove microservices
./orchestrator.sh status    # Show cluster status
```

### Manual Deployment

```bash
# Deploy step by step
kubectl apply -f Manifests/namespaces/
kubectl apply -f Manifests/secrets/
kubectl apply -f Manifests/databases/
kubectl apply -f Manifests/applications/
kubectl apply -f Manifests/ingress/
```

### Cleanup

```bash
# Remove microservices only
./orchestrator.sh cleanup

# Destroy entire cluster
./orchestrator.sh destroy
```

## Troubleshooting

### Common Issues

1. **Cluster Creation Fails**:
   ```bash
   # Check VM status
   vagrant status
   
   # Destroy and recreate
   vagrant destroy -f
   ./orchestrator.sh create
   ```

2. **Pods Stuck in Pending**:
   ```bash
   # Check node resources
   kubectl describe nodes
   
   # Check pod events
   kubectl describe pod -n microservices <pod-name>
   ```

3. **Image Pull Errors**:
   ```bash
   # Verify image exists on Docker Hub
   docker pull <your-username>/inventory-app:latest
   
   # Check imagePullSecrets if using private registry
   ```

4. **Database Connection Issues**:
   ```bash
   # Check database pods
   kubectl get pods -n microservices -l app=inventory-db
   
   # Check database logs
   kubectl logs -n microservices <db-pod-name>
   
   # Test connectivity
   kubectl exec -n microservices -it <app-pod> -- nc -zv inventory-db 5432
   ```

### Performance Tuning

1. **Resource Limits**:
   - Adjust memory/CPU limits in manifests based on workload
   - Monitor resource usage with `kubectl top`

2. **Auto-scaling**:
   - Modify HPA settings for different scaling behavior
   - Ensure metrics-server is available for CPU-based scaling

3. **Storage**:
   - Increase PVC size for databases if needed
   - Consider using faster storage classes

## Development

### Local Development

```bash
# Run services locally with docker-compose
docker-compose up -d

# Build individual images
cd srcs/inventory-app
docker build -t inventory-app .
```

### Adding New Services

1. Create application in `srcs/<service-name>/`
2. Add Kubernetes manifests in `Manifests/applications/`
3. Update deployment scripts
4. Add service to ingress configuration

## Security Considerations

- Secrets are stored in Kubernetes secrets (base64 encoded)
- Non-root containers with security contexts
- Network policies can be added for micro-segmentation
- Consider using external secret management for production

## Production Readiness

For production deployment, consider:

- **High Availability**: Multi-master K3s setup
- **Monitoring**: Prometheus, Grafana, and alerting
- **Logging**: Centralized logging with ELK stack
- **Backup**: Regular database and configuration backups
- **Security**: Pod security policies, network policies
- **CI/CD**: Automated testing and deployment pipelines

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test thoroughly
4. Submit a pull request with detailed description

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Check the troubleshooting section
- Review Kubernetes and K3s documentation
- Create an issue in the repository

---

**Note**: This is a demonstration project. For production use, implement proper security measures, monitoring, and backup strategies.
