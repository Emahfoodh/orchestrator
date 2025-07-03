#!/usr/bin/env python3
"""
API Testers for CRUD Master Microservices
Tests all endpoints for API Gateway, Inventory App, and Billing App
"""

import requests
import json
import time
import sys
from typing import Dict, Any, Optional

class Colors:
    """ANSI color codes for terminal output"""
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    END = '\033[0m'
    BOLD = '\033[1m'

class APITester:
    def __init__(self, base_url: str, service_name: str):
        self.base_url = base_url.rstrip('/')
        self.service_name = service_name
        self.session = requests.Session()
        self.test_results = []

    def log(self, message: str, color: str = Colors.CYAN):
        print(f"{color}{message}{Colors.END}")

    def success(self, message: str):
        self.log(f"✅ {message}", Colors.GREEN)

    def error(self, message: str):
        self.log(f"❌ {message}", Colors.RED)

    def warning(self, message: str):
        self.log(f"⚠️  {message}", Colors.YELLOW)

    def info(self, message: str):
        self.log(f"ℹ️  {message}", Colors.BLUE)

    def test_endpoint(self, method: str, endpoint: str, data: Optional[Dict] = None, 
                     expected_status: int = 200, description: str = ""):
        """Test a single endpoint"""
        url = f"{self.base_url}{endpoint}"
        
        try:
            self.info(f"Testing {method} {endpoint} - {description}")
            
            if method.upper() == 'GET':
                response = self.session.get(url)
            elif method.upper() == 'POST':
                response = self.session.post(url, json=data)
            elif method.upper() == 'PUT':
                response = self.session.put(url, json=data)
            elif method.upper() == 'DELETE':
                response = self.session.delete(url)
            else:
                self.error(f"Unsupported HTTP method: {method}")
                return False

            # Check status code
            if response.status_code == expected_status:
                self.success(f"Status: {response.status_code}")
                
                # Try to parse JSON response
                try:
                    json_response = response.json()
                    self.log(f"Response: {json.dumps(json_response, indent=2)}", Colors.CYAN)
                    # Store response for later use
                    self.last_response = json_response
                except:
                    self.log(f"Response: {response.text}", Colors.CYAN)
                    self.last_response = response.text
                
                self.test_results.append(True)
                return True
            else:
                self.error(f"Expected status {expected_status}, got {response.status_code}")
                self.error(f"Response: {response.text}")
                self.test_results.append(False)
                return False

        except requests.exceptions.ConnectionError:
            self.error(f"Connection failed to {url}")
            self.error(f"Make sure {self.service_name} is running!")
            self.test_results.append(False)
            return False
        except Exception as e:
            self.error(f"Request failed: {str(e)}")
            self.test_results.append(False)
            return False

    def get_movie_ids(self):
        """Helper method to get current movie IDs"""
        try:
            response = self.session.get(f"{self.base_url}/api/movies")
            if response.status_code == 200:
                movies = response.json()
                return [movie['id'] for movie in movies]
            return []
        except:
            return []

    def print_summary(self):
        """Print test summary"""
        total_tests = len(self.test_results)
        passed_tests = sum(self.test_results)
        failed_tests = total_tests - passed_tests
        
        print(f"\n{Colors.BOLD}=== {self.service_name} Test Summary ==={Colors.END}")
        print(f"Total Tests: {total_tests}")
        print(f"{Colors.GREEN}Passed: {passed_tests}{Colors.END}")
        print(f"{Colors.RED}Failed: {failed_tests}{Colors.END}")
        
        if failed_tests == 0:
            print(f"{Colors.GREEN}🎉 All tests passed!{Colors.END}")
        else:
            print(f"{Colors.RED}❌ {failed_tests} test(s) failed{Colors.END}")

def test_inventory_service():
    """Test Inventory Service directly (port 8080)"""
    tester = APITester("http://localhost:8080", "Inventory Service")
    
    print(f"\n{Colors.BOLD}=== Testing Inventory Service (Direct) ==={Colors.END}")
    
    # Test get all movies (empty)
    tester.test_endpoint("GET", "/api/movies", description="Get all movies (should be empty initially)")
    
    # Test create movie
    movie_data = {
        "title": "The Matrix",
        "description": "A sci-fi classic about reality and simulation"
    }
    tester.test_endpoint("POST", "/api/movies", data=movie_data, expected_status=201, 
                        description="Create a new movie")
    
    # Test create another movie
    movie_data2 = {
        "title": "Inception",
        "description": "A mind-bending thriller about dreams within dreams"
    }
    tester.test_endpoint("POST", "/api/movies", data=movie_data2, expected_status=201,
                        description="Create another movie")
    
    # Test get all movies (should have 2 movies)
    tester.test_endpoint("GET", "/api/movies", description="Get all movies (should have 2 movies)")
    
    # Test search movies by title
    tester.test_endpoint("GET", "/api/movies?title=Matrix", description="Search movies by title")
    
    # Get current movie IDs for testing
    movie_ids = tester.get_movie_ids()
    
    # Test get movie by ID using actual ID
    if movie_ids:
        first_id = movie_ids[0]
        tester.test_endpoint("GET", f"/api/movies/{first_id}", description="Get movie by ID")
        
        # Test update movie using actual ID
        update_data = {
            "title": "The Matrix Reloaded", 
            "description": "The sequel to The Matrix"
        }
        tester.test_endpoint("PUT", f"/api/movies/{first_id}", data=update_data, description="Update movie by ID")
        
        # Test delete movie by ID using actual ID
        if len(movie_ids) > 1:
            second_id = movie_ids[1]
            tester.test_endpoint("DELETE", f"/api/movies/{second_id}", description="Delete movie by ID")
        else:
            tester.test_endpoint("DELETE", f"/api/movies/{first_id}", description="Delete movie by ID")
    else:
        # Fallback to hardcoded IDs if we can't get them dynamically
        tester.test_endpoint("GET", "/api/movies/1", description="Get movie by ID")
        update_data = {
            "title": "The Matrix Reloaded",
            "description": "The sequel to The Matrix"
        }
        tester.test_endpoint("PUT", "/api/movies/1", data=update_data, description="Update movie by ID")
        tester.test_endpoint("DELETE", "/api/movies/2", description="Delete movie by ID")
    
    # Test invalid movie ID (should return 404)
    tester.test_endpoint("GET", "/api/movies/999", expected_status=404, 
                        description="Get non-existent movie (should return 404)")
    
    tester.print_summary()
    return tester.test_results

def test_billing_service():
    """Test Billing Service directly (port 8081)"""
    tester = APITester("http://localhost:8081", "Billing Service")
    
    print(f"\n{Colors.BOLD}=== Testing Billing Service (Direct) ==={Colors.END}")
    
    # Test health check
    tester.test_endpoint("GET", "/api/health", description="Health check")
    
    # Test get all orders (should be empty initially)
    tester.test_endpoint("GET", "/api/orders", description="Get all orders (should be empty initially)")
    
    # Test get existing order (if any exist) or non-existent order
    try:
        response = tester.session.get(f"{tester.base_url}/api/orders")
        if response.status_code == 200:
            orders = response.json()
            if orders:
                # Test getting an existing order
                existing_id = orders[0]['id']
                tester.test_endpoint("GET", f"/api/orders/{existing_id}", expected_status=200,
                                    description="Get existing order by ID")
            else:
                # Test getting non-existent order
                tester.test_endpoint("GET", "/api/orders/999", expected_status=404,
                                    description="Get non-existent order (should return 404)")
        else:
            # Test getting non-existent order
            tester.test_endpoint("GET", "/api/orders/999", expected_status=404,
                                description="Get non-existent order (should return 404)")
    except:
        # Fallback to testing non-existent order
        tester.test_endpoint("GET", "/api/orders/999", expected_status=404,
                            description="Get non-existent order (should return 404)")
    
    tester.print_summary()
    return tester.test_results

def test_api_gateway():
    """Test API Gateway (port 5000)"""
    tester = APITester("http://localhost:5000", "API Gateway")
    
    print(f"\n{Colors.BOLD}=== Testing API Gateway ==={Colors.END}")
    
    # Test inventory endpoints through gateway
    tester.test_endpoint("GET", "/api/movies", description="Get movies through gateway")
    
    # Test create movie through gateway
    movie_data = {
        "title": "Blade Runner",
        "description": "A dystopian sci-fi film about androids and humanity"
    }
    tester.test_endpoint("POST", "/api/movies", data=movie_data, expected_status=201,
                        description="Create movie through gateway")
    
    # Test billing endpoint through gateway
    billing_data = {
        "user_id": "123",
        "number_of_items": "5",
        "total_amount": "99.99"
    }
    tester.test_endpoint("POST", "/api/billing", data=billing_data,
                        description="Send billing request through gateway")
    
    # Test billing with missing data (should fail)
    invalid_billing_data = {
        "user_id": "123"
        # Missing required fields
    }
    tester.test_endpoint("POST", "/api/billing", data=invalid_billing_data, expected_status=400,
                        description="Send invalid billing request (should return 400)")
    
    tester.print_summary()
    return tester.test_results

def test_integration():
    """Test integration between services"""
    print(f"\n{Colors.BOLD}=== Integration Tests ==={Colors.END}")
    
    gateway_tester = APITester("http://localhost:5000", "Integration Test")
    
    # Clean up - delete all movies first
    gateway_tester.test_endpoint("DELETE", "/api/movies", description="Clean up - delete all movies")
    
    # Create movies through gateway
    movies = [
        {"title": "Star Wars", "description": "A space opera epic"},
        {"title": "The Lord of the Rings", "description": "A fantasy epic"},
        {"title": "Pulp Fiction", "description": "A crime film with interconnected stories"}
    ]
    
    for i, movie in enumerate(movies, 1):
        gateway_tester.test_endpoint("POST", "/api/movies", data=movie, expected_status=201,
                                   description=f"Create movie {i} through gateway")
    
    # Send multiple billing requests
    billing_requests = [
        {"user_id": "user1", "number_of_items": "2", "total_amount": "29.99"},
        {"user_id": "user2", "number_of_items": "1", "total_amount": "14.99"},
        {"user_id": "user3", "number_of_items": "3", "total_amount": "44.99"}
    ]
    
    for i, billing in enumerate(billing_requests, 1):
        gateway_tester.test_endpoint("POST", "/api/billing", data=billing,
                                   description=f"Send billing request {i}")
    
    # Test search functionality
    gateway_tester.test_endpoint("GET", "/api/movies?title=Star", 
                                description="Search for movies containing 'Star'")
    
    gateway_tester.print_summary()
    return gateway_tester.test_results

def check_services():
    """Check if all services are running"""
    services = [
        ("API Gateway", "http://localhost:5000"),
        ("Inventory Service", "http://localhost:8080"),
        ("Billing Service", "http://localhost:8081")
    ]
    
    print(f"{Colors.BOLD}=== Checking Services ==={Colors.END}")
    
    all_running = True
    for name, url in services:
        try:
            response = requests.get(f"{url}/api/health" if "Billing" in name else f"{url}/api/movies", timeout=5)
            if response.status_code in [200, 404]:  # 404 is ok for empty movie list
                print(f"{Colors.GREEN}✅ {name} is running at {url}{Colors.END}")
            else:
                print(f"{Colors.RED}❌ {name} returned status {response.status_code}{Colors.END}")
                all_running = False
        except requests.exceptions.ConnectionError:
            print(f"{Colors.RED}❌ {name} is not responding at {url}{Colors.END}")
            all_running = False
        except Exception as e:
            print(f"{Colors.RED}❌ Error checking {name}: {str(e)}{Colors.END}")
            all_running = False
    
    return all_running

def main():
    """Main test runner"""
    print(f"{Colors.BOLD}🚀 CRUD Master API Tester{Colors.END}")
    print(f"{Colors.CYAN}Testing all microservices...{Colors.END}\n")
    
    # Check if services are running
    if not check_services():
        print(f"\n{Colors.RED}❌ Not all services are running. Please start them first.{Colors.END}")
        print(f"\n{Colors.YELLOW}To start the services:{Colors.END}")
        print(f"1. Inventory Service: cd srcs/inventory-app && source venv/bin/activate && python run.py")
        print(f"2. Billing Service: cd srcs/billing-app && source venv/bin/activate && python run.py")
        print(f"3. API Gateway: cd srcs/api-gateway && source venv/bin/activate && python run.py")
        return
    
    print(f"\n{Colors.GREEN}✅ All services are running!{Colors.END}")
    
    # Run all tests
    all_results = []
    
    # Test each service
    all_results.extend(test_inventory_service())
    all_results.extend(test_billing_service())
    all_results.extend(test_api_gateway())
    all_results.extend(test_integration())
    
    # Overall summary
    total_tests = len(all_results)
    passed_tests = sum(all_results)
    failed_tests = total_tests - passed_tests
    
    print(f"\n{Colors.BOLD}🎯 OVERALL TEST SUMMARY{Colors.END}")
    print(f"Total Tests: {total_tests}")
    print(f"{Colors.GREEN}Passed: {passed_tests}{Colors.END}")
    print(f"{Colors.RED}Failed: {failed_tests}{Colors.END}")
    
    if failed_tests == 0:
        print(f"\n{Colors.GREEN}🎉 ALL TESTS PASSED! 🎉{Colors.END}")
        print(f"{Colors.GREEN}Your microservices architecture is working perfectly!{Colors.END}")
    else:
        print(f"\n{Colors.RED}❌ {failed_tests} test(s) failed{Colors.END}")
        print(f"{Colors.YELLOW}Check the error messages above for details.{Colors.END}")

if __name__ == "__main__":
    main()
