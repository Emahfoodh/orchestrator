from flask import Blueprint, request, jsonify
from app.models import db, Movie

# Create a blueprint for inventory routes
inventory_bp = Blueprint('inventory', __name__)

@inventory_bp.route('/movies', methods=['GET'])
def get_movies():
    """
    Get all movies or filter by title.
    
    GET /api/movies
    GET /api/movies?title=[name]
    """
    title_filter = request.args.get('title')
    
    if title_filter:
        movies = Movie.query.filter(Movie.title.ilike(f'%{title_filter}%')).all()
    else:
        movies = Movie.query.all()
    
    return jsonify([movie.to_dict() for movie in movies]), 200

@inventory_bp.route('/movies', methods=['POST'])
def create_movie():
    """
    Create a new movie.
    
    POST /api/movies
    """
    if not request.is_json:
        return jsonify({"message": "Missing JSON in request"}), 400
    
    data = request.get_json()
    
    if 'title' not in data:
        return jsonify({"message": "Missing required field: title"}), 400
    
    if 'description' not in data or not data['description']:
        return jsonify({"message": "Missing required field: description"}), 400

    movie = Movie.from_dict(data)
    
    db.session.add(movie)
    db.session.commit()
    
    return jsonify(movie.to_dict()), 201

@inventory_bp.route('/movies', methods=['DELETE'])
def delete_all_movies():
    """
    Delete all movies.
    
    DELETE /api/movies
    """
    db.session.query(Movie).delete()
    db.session.commit()
    
    return jsonify({"message": "All movies have been deleted"}), 200

@inventory_bp.route('/movies/<int:id>', methods=['GET'])
def get_movie(id):
    """
    Get a specific movie by ID.
    
    GET /api/movies/:id
    """
    movie = Movie.query.get_or_404(id)
    return jsonify(movie.to_dict()), 200

@inventory_bp.route('/movies/<int:id>', methods=['PUT'])
def update_movie(id):
    """
    Update a specific movie by ID.
    
    PUT /api/movies/:id
    """
    if not request.is_json:
        return jsonify({"message": "Missing JSON in request"}), 400
    
    movie = Movie.query.get_or_404(id)
    data = request.get_json()
    
    if 'title' in data:
        movie.title = data['title']
    
    if 'description' in data:
        movie.description = data['description']
    
    db.session.commit()
    
    return jsonify(movie.to_dict()), 200

@inventory_bp.route('/movies/<int:id>', methods=['DELETE'])
def delete_movie(id):
    """
    Delete a specific movie by ID.
    
    DELETE /api/movies/:id
    """
    movie = Movie.query.get_or_404(id)
    
    db.session.delete(movie)
    db.session.commit()
    
    return jsonify({"message": f"Movie with id {id} has been deleted"}), 200
