#!/bin/bash

# CRUD Master API Tests using curl
# Simple bash script to test all microservices endpoints

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Base URLs
GATEWAY_URL="http://localhost:5000"
INVENTORY_URL="http://localhost:8080"
BILLING_URL="http://localhost:8081"

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_header() {
    echo -e "\n${CYAN}=== $1 ===${NC}"
}

# Function to test an endpoint
test_endpoint() {
    local method=$1
    local url=$2
    local data=$3
    local description=$4
    local expected_status=${5:-200}
    
    print_info "Testing $method $url - $description"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$url")
    elif [ "$method" = "POST" ]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST -H "Content-Type: application/json" -d "$data" "$url")
    elif [ "$method" = "PUT" ]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X PUT -H "Content-Type: application/json" -d "$data" "$url")
    elif [ "$method" = "DELETE" ]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X DELETE "$url")
    fi
    
    # Extract status code
    status_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
    
    if [ "$status_code" -eq "$expected_status" ]; then
        print_success "Status: $status_code"
        if [ -n "$body" ]; then
            echo -e "${CYAN}Response: $body${NC}"
        fi
    else
        print_error "Expected status $expected_status, got $status_code"
        if [ -n "$body" ]; then
            print_error "Response: $body"
        fi
    fi
    
    echo ""
}

# Function to check if services are running
check_services() {
    print_header "Checking Services"
    
    local all_running=true
    
    # Check API Gateway
    if curl -s "$GATEWAY_URL/api/movies" > /dev/null 2>&1; then
        print_success "API Gateway is running at $GATEWAY_URL"
    else
        print_error "API Gateway is not responding at $GATEWAY_URL"
        all_running=false
    fi
    
    # Check Inventory Service
    if curl -s "$INVENTORY_URL/api/movies" > /dev/null 2>&1; then
        print_success "Inventory Service is running at $INVENTORY_URL"
    else
        print_error "Inventory Service is not responding at $INVENTORY_URL"
        all_running=false
    fi
    
    # Check Billing Service
    if curl -s "$BILLING_URL/api/health" > /dev/null 2>&1; then
        print_success "Billing Service is running at $BILLING_URL"
    else
        print_error "Billing Service is not responding at $BILLING_URL"
        all_running=false
    fi
    
    if [ "$all_running" = false ]; then
        print_error "Not all services are running. Please start them first."
        echo ""
        print_warning "To start the services:"
        echo "1. Inventory Service: cd srcs/inventory-app && source venv/bin/activate && python run.py"
        echo "2. Billing Service: cd srcs/billing-app && source venv/bin/activate && python run.py"
        echo "3. API Gateway: cd srcs/api-gateway && source venv/bin/activate && python run.py"
        exit 1
    fi
    
    print_success "All services are running!"
}

# Test Inventory Service directly
test_inventory_service() {
    print_header "Testing Inventory Service (Direct)"
    
    # Get all movies (empty)
    test_endpoint "GET" "$INVENTORY_URL/api/movies" "" "Get all movies (should be empty initially)"
    
    # Create a movie
    movie_data='{"title": "The Matrix", "description": "A sci-fi classic about reality and simulation"}'
    test_endpoint "POST" "$INVENTORY_URL/api/movies" "$movie_data" "Create a new movie" 201
    
    # Create another movie
    movie_data2='{"title": "Inception", "description": "A mind-bending thriller about dreams within dreams"}'
    test_endpoint "POST" "$INVENTORY_URL/api/movies" "$movie_data2" "Create another movie" 201
    
    # Get all movies (should have 2 movies)
    test_endpoint "GET" "$INVENTORY_URL/api/movies" "" "Get all movies (should have 2 movies)"
    
    # Search movies by title
    test_endpoint "GET" "$INVENTORY_URL/api/movies?title=Matrix" "" "Search movies by title"
    
    # Get movie by ID
    test_endpoint "GET" "$INVENTORY_URL/api/movies/1" "" "Get movie by ID"
    
    # Update movie
    update_data='{"title": "The Matrix Reloaded", "description": "The sequel to The Matrix"}'
    test_endpoint "PUT" "$INVENTORY_URL/api/movies/1" "$update_data" "Update movie by ID"
    
    # Delete movie by ID
    test_endpoint "DELETE" "$INVENTORY_URL/api/movies/2" "" "Delete movie by ID"
    
    # Test invalid movie ID
    test_endpoint "GET" "$INVENTORY_URL/api/movies/999" "" "Get non-existent movie (should return 404)" 404
}

# Test Billing Service directly
test_billing_service() {
    print_header "Testing Billing Service (Direct)"
    
    # Health check
    test_endpoint "GET" "$BILLING_URL/api/health" "" "Health check"
    
    # Get all orders (empty)
    test_endpoint "GET" "$BILLING_URL/api/orders" "" "Get all orders (should be empty initially)"
    
    # Get non-existent order
    test_endpoint "GET" "$BILLING_URL/api/orders/1" "" "Get non-existent order (should return 404)" 404
}

# Test API Gateway
test_api_gateway() {
    print_header "Testing API Gateway"
    
    # Get movies through gateway
    test_endpoint "GET" "$GATEWAY_URL/api/movies" "" "Get movies through gateway"
    
    # Create movie through gateway
    movie_data='{"title": "Blade Runner", "description": "A dystopian sci-fi film about androids and humanity"}'
    test_endpoint "POST" "$GATEWAY_URL/api/movies" "$movie_data" "Create movie through gateway" 201
    
    # Send billing request through gateway
    billing_data='{"user_id": "123", "number_of_items": "5", "total_amount": "99.99"}'
    test_endpoint "POST" "$GATEWAY_URL/api/billing" "$billing_data" "Send billing request through gateway"
    
    # Send invalid billing request
    invalid_billing_data='{"user_id": "123"}'
    test_endpoint "POST" "$GATEWAY_URL/api/billing" "$invalid_billing_data" "Send invalid billing request (should return 400)" 400
}

# Integration tests
test_integration() {
    print_header "Integration Tests"
    
    # Clean up - delete all movies
    test_endpoint "DELETE" "$GATEWAY_URL/api/movies" "" "Clean up - delete all movies"
    
    # Create multiple movies through gateway
    print_info "Creating multiple movies through gateway..."
    movie1='{"title": "Star Wars", "description": "A space opera epic"}'
    test_endpoint "POST" "$GATEWAY_URL/api/movies" "$movie1" "Create movie 1 through gateway" 201
    
    movie2='{"title": "The Lord of the Rings", "description": "A fantasy epic"}'
    test_endpoint "POST" "$GATEWAY_URL/api/movies" "$movie2" "Create movie 2 through gateway" 201
    
    movie3='{"title": "Pulp Fiction", "description": "A crime film with interconnected stories"}'
    test_endpoint "POST" "$GATEWAY_URL/api/movies" "$movie3" "Create movie 3 through gateway" 201
    
    # Send multiple billing requests
    print_info "Sending multiple billing requests..."
    billing1='{"user_id": "user1", "number_of_items": "2", "total_amount": "29.99"}'
    test_endpoint "POST" "$GATEWAY_URL/api/billing" "$billing1" "Send billing request 1"
    
    billing2='{"user_id": "user2", "number_of_items": "1", "total_amount": "14.99"}'
    test_endpoint "POST" "$GATEWAY_URL/api/billing" "$billing2" "Send billing request 2"
    
    billing3='{"user_id": "user3", "number_of_items": "3", "total_amount": "44.99"}'
    test_endpoint "POST" "$GATEWAY_URL/api/billing" "$billing3" "Send billing request 3"
    
    # Test search functionality
    test_endpoint "GET" "$GATEWAY_URL/api/movies?title=Star" "" "Search for movies containing 'Star'"
}

# Main execution
main() {
    echo -e "${CYAN}🚀 CRUD Master API Tests (curl version)${NC}"
    echo -e "${CYAN}Testing all microservices...${NC}\n"
    
    # Check if services are running
    check_services
    
    # Run all tests
    test_inventory_service
    test_billing_service
    test_api_gateway
    test_integration
    
    print_header "Tests Completed"
    print_success "All curl tests have been executed!"
    print_info "For more detailed testing with better error handling, use: python3 api_testers.py"
}

# Run main function
main
