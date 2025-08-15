#!/bin/bash

# Build and Push Docker Images Script
# This script builds Docker images for all microservices and pushes them to Docker Hub

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if user is logged in to Docker Hub
if ! docker info | grep -q "Username:"; then
    print_warning "You may not be logged in to Docker Hub. Consider running 'docker login' first."
fi

# Get Docker Hub username
read -p "Enter your Docker Hub username: " DOCKER_USERNAME

if [ -z "$DOCKER_USERNAME" ]; then
    print_error "Docker Hub username is required"
    exit 1
fi

# Build and push inventory-app
print_status "Building inventory-app..."
cd srcs/inventory-app
docker build -t ${DOCKER_USERNAME}/inventory-app:latest .
docker tag ${DOCKER_USERNAME}/inventory-app:latest ${DOCKER_USERNAME}/inventory-app:v1.0
print_status "Pushing inventory-app to Docker Hub..."
docker push ${DOCKER_USERNAME}/inventory-app:latest
docker push ${DOCKER_USERNAME}/inventory-app:v1.0
cd ../..

# Build and push billing-app
print_status "Building billing-app..."
cd srcs/billing-app
docker build -t ${DOCKER_USERNAME}/billing-app:latest .
docker tag ${DOCKER_USERNAME}/billing-app:latest ${DOCKER_USERNAME}/billing-app:v1.0
print_status "Pushing billing-app to Docker Hub..."
docker push ${DOCKER_USERNAME}/billing-app:latest
docker push ${DOCKER_USERNAME}/billing-app:v1.0
cd ../..

# Build and push api-gateway
print_status "Building api-gateway..."
cd srcs/api-gateway
docker build -t ${DOCKER_USERNAME}/api-gateway-app:latest .
docker tag ${DOCKER_USERNAME}/api-gateway-app:latest ${DOCKER_USERNAME}/api-gateway-app:v1.0
print_status "Pushing api-gateway to Docker Hub..."
docker push ${DOCKER_USERNAME}/api-gateway-app:latest
docker push ${DOCKER_USERNAME}/api-gateway-app:v1.0
cd ../..

print_status "All images built and pushed successfully!"

# Update image references in Kubernetes manifests
print_status "Updating Kubernetes manifests with your Docker Hub username..."
for file in Manifests/applications/*.yaml; do
    sed -i "s/\${DOCKER_USERNAME}/$DOCKER_USERNAME/g" "$file"
done

print_status "Image references updated in manifests"
print_status "Images available at:"
echo "  - ${DOCKER_USERNAME}/inventory-app:latest"
echo "  - ${DOCKER_USERNAME}/billing-app:latest"
echo "  - ${DOCKER_USERNAME}/api-gateway-app:latest"

# Create a file with the image names for easy reference
cat > docker-images.txt << EOF
# Docker Images for Microservices
inventory-app: ${DOCKER_USERNAME}/inventory-app:latest
billing-app: ${DOCKER_USERNAME}/billing-app:latest
api-gateway-app: ${DOCKER_USERNAME}/api-gateway-app:latest

# Tagged versions
inventory-app: ${DOCKER_USERNAME}/inventory-app:v1.0
billing-app: ${DOCKER_USERNAME}/billing-app:v1.0
api-gateway-app: ${DOCKER_USERNAME}/api-gateway-app:v1.0
EOF

print_status "Image names saved to docker-images.txt"
