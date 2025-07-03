#!/usr/bin/env python3
"""
Simple Test Script for CRUD Master Vagrant Setup
Run this after starting all VMs and services to verify everything works
"""

import requests
import json
import time

# ANSI colors for output
GREEN = '\033[92m'
RED = '\033[91m'
BLUE = '\033[94m'
YELLOW = '\033[93m'
END = '\033[0m'

def print_status(message, status="info"):
    colors = {"success": GREEN, "error": RED, "info": BLUE, "warning": YELLOW}
    color = colors.get(status, BLUE)
    print(f"{color}{message}{END}")

def test_service(name, url, expected_status=200):
    """Test if a service is responding"""
    try:
        response = requests.get(url, timeout=5)
        if response.status_code == expected_status:
            print_status(f"✅ {name} is working", "success")
            return True
        else:
            print_status(f"❌ {name} returned status {response.status_code}", "error")
            return False
    except requests.exceptions.ConnectionError:
        print_status(f"❌ {name} is not responding", "error")
        return False
    except Exception as e:
        print_status(f"❌ {name} error: {str(e)}", "error")
        return False

def test_api_functionality():
    """Test basic API functionality"""
    print_status("\n🧪 Testing API Functionality...", "info")
    
    # Test 1: Create a movie via Gateway
    movie_data = {"title": "Test Movie", "description": "Simple test"}
    try:
        response = requests.post("http://localhost:5000/api/movies", 
                               json=movie_data, timeout=10)
        if response.status_code == 201:
            print_status("✅ Created movie via Gateway", "success")
            movie_id = response.json().get('id')
        else:
            print_status(f"❌ Failed to create movie: {response.status_code}", "error")
            return False
    except Exception as e:
        print_status(f"❌ Failed to create movie: {str(e)}", "error")
        return False
    
    # Test 2: Get movies via Gateway
    try:
        response = requests.get("http://localhost:5000/api/movies", timeout=10)
        if response.status_code == 200:
            movies = response.json()
            if any(movie['title'] == 'Test Movie' for movie in movies):
                print_status("✅ Retrieved movies via Gateway", "success")
            else:
                print_status("⚠️  Movies retrieved but test movie not found", "warning")
        else:
            print_status(f"❌ Failed to get movies: {response.status_code}", "error")
            return False
    except Exception as e:
        print_status(f"❌ Failed to get movies: {str(e)}", "error")
        return False
    
    # Test 3: Send billing request via Gateway
    billing_data = {
        "user_id": "test_user",
        "number_of_items": "1",
        "total_amount": "19.99"
    }
    try:
        response = requests.post("http://localhost:5000/api/billing", 
                               json=billing_data, timeout=10)
        if response.status_code == 200:
            print_status("✅ Sent billing request via Gateway", "success")
        else:
            print_status(f"❌ Failed to send billing: {response.status_code}", "error")
            return False
    except Exception as e:
        print_status(f"❌ Failed to send billing: {str(e)}", "error")
        return False
    
    return True

def main():
    print_status("🚀 CRUD Master Simple Test", "info")
    print_status("=" * 50, "info")
    
    # Test service connectivity
    print_status("\n🔍 Checking Services...", "info")
    
    services = [
        ("Gateway Service", "http://localhost:5000/api/movies"),
        ("Inventory Service", "http://localhost:8080/api/movies"),
        ("Billing Service", "http://localhost:8081/api/health")
    ]
    
    all_services_ok = True
    for name, url in services:
        if not test_service(name, url):
            all_services_ok = False
    
    if not all_services_ok:
        print_status("\n❌ Some services are not running!", "error")
        print_status("Make sure you've started all services:", "info")
        print_status("1. vagrant ssh inventory -c '/home/vagrant/start_inventory_vm.sh'", "info")
        print_status("2. vagrant ssh billing -c '/home/vagrant/start_billing_vm.sh'", "info")
        print_status("3. vagrant ssh gateway -c '/home/vagrant/start_gateway.sh'", "info")
        return
    
    # Test API functionality
    if test_api_functionality():
        print_status("\n🎉 ALL TESTS PASSED!", "success")
        print_status("Your distributed microservices are working perfectly!", "success")
        print_status("\nNext steps:", "info")
        print_status("• Try the full test suite: python3 api_testers.py", "info")
        print_status("• Access services directly:", "info")
        print_status("  - Gateway: http://localhost:5000/api/movies", "info")
        print_status("  - Inventory: http://localhost:8080/api/movies", "info")
        print_status("  - Billing: http://localhost:8081/api/health", "info")
        print_status("  - RabbitMQ UI: http://localhost:15672 (guest/guest)", "info")
    else:
        print_status("\n❌ Some API tests failed!", "error")
        print_status("Check the service logs in their terminal windows", "info")

if __name__ == "__main__":
    main()
