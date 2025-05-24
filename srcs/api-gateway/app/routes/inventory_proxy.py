import requests
from flask import Blueprint, request, Response
from app.config import Config

bp = Blueprint('inventory_proxy', __name__)

@bp.route('/api/movies', methods=['GET', 'POST', 'DELETE'])
@bp.route('/api/movies/<id>', methods=['GET', 'PUT', 'DELETE'])
def forward_to_inventory(id=None):
    url = f"{Config.INVENTORY_API_URL}/api/movies"
    if id:
        url += f"/{id}"
    
    response = requests.request(
        method=request.method,
        url=url,
        headers={key: value for key, value in request.headers if key != 'Host'},
        data=request.get_data(),
        cookies=request.cookies,
        params=request.args
    )
    
    return response.content, response.status_code


# @bp.route('/api/movies', methods=['GET', 'POST', 'DELETE'])
# def proxy_movies():
#     """
#     Proxy requests to the Inventory API for /api/movies endpoint
#     """
#     url = f"{Config.INVENTORY_API_URL}/api/movies"
    
#     # Add query parameters if they exist
#     if request.args:
#         url += '?' + '&'.join([f"{key}={value}" for key, value in request.args.items()])
    
#     # Forward the request to the Inventory API
#     return forward_request(url)

# @bp.route('/api/movies/<movie_id>', methods=['GET', 'PUT', 'DELETE'])
# def proxy_movie_by_id(movie_id):
#     """
#     Proxy requests to the Inventory API for /api/movies/:id endpoint
#     """
#     url = f"{Config.INVENTORY_API_URL}/api/movies/{movie_id}"
    
#     # Forward the request to the Inventory API
#     return forward_request(url)

# def forward_request(url):
#     """
#     Helper function to forward requests to the Inventory API
#     """
#     # Get the method of the original request
#     method = request.method
    
#     # Get the headers from the original request
#     headers = {key: value for key, value in request.headers if key != 'Host'}
    
#     # Get the data from the original request
#     data = request.get_data()
    
#     try:
#         # Forward the request to the Inventory API
#         response = requests.request(
#             method=method,
#             url=url,
#             headers=headers,
#             data=data,
#             params=request.args
#         )
        
#         # Create a Flask response with the same status code, content, and headers
#         resp = Response(
#             response=response.content,
#             status=response.status_code,
#             content_type=response.headers.get('Content-Type', 'application/json')
#         )
        
#         # Copy all headers from the response
#         for header, value in response.headers.items():
#             if header.lower() not in ('content-length', 'content-type', 'transfer-encoding'):
#                 resp.headers[header] = value
                
#         return resp
        
#     except requests.exceptions.RequestException as e:
#         # Handle connection errors
#         return {
#             "error": "Error connecting to Inventory API",
#             "details": str(e)
#         }, 503  # Service Unavailable