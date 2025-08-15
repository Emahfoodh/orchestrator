#!/bin/bash

# Kubernetes testing script adapted from test.sh

# Base URL using Kubernetes ingress
BASE_URL="http://192.168.56.10"
HOST_HEADER="api-gateway.local"

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Helper function for curl with proper headers
k8s_curl() {
    curl -s -H "Host: ${HOST_HEADER}" "$@"
}

# Track test movie ID
MOVIE_ID=""

# Inventory Service Tests

test_create_movie() {
    echo "Testing POST /api/movies (Create movie)..."

    response=$(k8s_curl -w "\n%{http_code}" -X POST "${BASE_URL}/api/movies" \
        -H "Content-Type: application/json" \
        -d '{
            "title": "Test Movie",
            "description": "Test Description"
        }')

    status_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d')

    if [ "$status_code" -eq 201 ]; then
        print_success "Create movie test passed"
        # Extract and store movie ID for later tests
        MOVIE_ID=$(echo $body | jq -r '.id')
    else
        print_error "Create movie test failed with status $status_code"
        echo "Response: $body"
    fi
}

test_get_all_movies() {
    echo "Testing GET /api/movies (List all movies)..."

    response=$(k8s_curl -w "\n%{http_code}" "${BASE_URL}/api/movies")

    status_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d')

    if [ "$status_code" -eq 200 ]; then
        print_success "Get all movies test passed"
    else
        print_error "Get all movies test failed with status $status_code"
        echo "Response: $body"
    fi
}

test_get_movie_by_title() {
    echo "Testing GET /api/movies?title=... (Filter by title)..."

    response=$(k8s_curl -w "\n%{http_code}" "${BASE_URL}/api/movies?title=Test%20Movie")

    status_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d')

    if [ "$status_code" -eq 200 ]; then
        print_success "Get movie by title test passed"
    else
        print_error "Get movie by title test failed with status $status_code"
        echo "Response: $body"
    fi
}

test_get_movie_by_id() {
    echo "Testing GET /api/movies/:id (Get single movie)..."

    if [ -z "$MOVIE_ID" ]; then
        print_error "No movie ID available for test"
        return
    fi

    response=$(k8s_curl -w "\n%{http_code}" "${BASE_URL}/api/movies/${MOVIE_ID}")

    status_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d')

    if [ "$status_code" -eq 200 ]; then
        print_success "Get movie by ID test passed"
    else
        print_error "Get movie by ID test failed with status $status_code"
        echo "Response: $body"
    fi
}

test_update_movie() {
    echo "Testing PUT /api/movies/:id (Update movie)..."

    if [ -z "$MOVIE_ID" ]; then
        print_error "No movie ID available for test"
        return
    fi

    response=$(k8s_curl -w "\n%{http_code}" -X PUT "${BASE_URL}/api/movies/${MOVIE_ID}" \
        -H "Content-Type: application/json" \
        -d '{
            "title": "Updated Movie",
            "description": "Updated Description"
        }')

    status_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d')

    if [ "$status_code" -eq 200 ]; then
        print_success "Update movie test passed"
    else
        print_error "Update movie test failed with status $status_code"
        echo "Response: $body"
    fi
}

test_delete_movie() {
    echo "Testing DELETE /api/movies/:id (Delete single movie)..."

    if [ -z "$MOVIE_ID" ]; then
        print_error "No movie ID available for test"
        return
    fi

    response=$(k8s_curl -w "\n%{http_code}" -X DELETE "${BASE_URL}/api/movies/${MOVIE_ID}")

    status_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d')

    if [ "$status_code" -eq 200 ]; then
        print_success "Delete movie test passed"
        MOVIE_ID=""
    else
        print_error "Delete movie test failed with status $status_code"
        echo "Response: $body"
    fi
}

test_delete_all_movies() {
    echo "Testing DELETE /api/movies (Delete all movies)..."

    response=$(k8s_curl -w "\n%{http_code}" -X DELETE "${BASE_URL}/api/movies")

    status_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d')

    if [ "$status_code" -eq 200 ]; then
        print_success "Delete all movies test passed"
        MOVIE_ID=""
    else
        print_error "Delete all movies test failed with status $status_code"
        echo "Response: $body"
    fi
}

# Billing Service Tests

test_valid_order() {
    echo "Testing POST /api/billing (Valid order)..."

    response=$(k8s_curl -w "\n%{http_code}" -X POST "${BASE_URL}/api/billing" \
        -H "Content-Type: application/json" \
        -d '{
            "user_id": "test-user-1",
            "number_of_items": 3,
            "total_amount": 45.99
        }')

    status_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d')

    if [ "$status_code" -eq 200 ]; then
        print_success "Valid order test passed"
    else
        print_error "Valid order test failed with status $status_code"
        echo "Response: $body"
    fi
}

# Health check tests
test_health_endpoints() {
    echo "Testing health endpoints..."
    
    # API Gateway health
    response=$(k8s_curl -w "\n%{http_code}" "${BASE_URL}/health")
    status_code=$(echo "$response" | tail -n 1)
    
    if [ "$status_code" -eq 200 ]; then
        print_success "API Gateway health check passed"
    else
        print_error "API Gateway health check failed with status $status_code"
    fi
}

# Run all tests
echo "Starting Kubernetes API Tests..."
echo "================================="
echo "Using BASE_URL: $BASE_URL"
echo "Using HOST_HEADER: $HOST_HEADER"
echo

# Health checks first
test_health_endpoints

echo
echo "Running inventory tests..."
echo "========================="
echo

# Clean up any existing data
test_delete_all_movies

# Run inventory tests
test_create_movie
test_get_all_movies
test_get_movie_by_title
test_get_movie_by_id
test_update_movie
test_delete_movie
test_delete_all_movies

echo
echo "Running billing tests..."
echo "======================="
echo

# Run billing tests
test_valid_order

echo
echo "Tests completed!"
