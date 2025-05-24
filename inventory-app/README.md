Flask Movie Inventory API
=======================

A RESTful API for managing a movie inventory using Flask and PostgreSQL.

## Project Structure

```
flask_inventory/
├── app/
│   ├── __init__.py
│   ├── routes/
│   │   ├── __init__.py
│   │   └── inventory.py
│   ├── models.py
│   └── config.py
├── run.py
├── requirements.txt
└── README.md
```

## Installation

1. Clone the repository
2. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```
3. Install dependencies:
```bash
pip install -r requirements.txt
```
4. Create PostgreSQL database:
using docker
```bash
docker pull postgres
docker run --name inventory -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres
docker exec -it inventory psql -U postgres
# inside psql
CREATE DATABASE movies_db;
\q
```
or 
```bash
psql -U postgres
CREATE DATABASE movies_db;
\q
```
5. Run the application:
```bash
python run.py
```

## API Endpoints

* `GET /api/movies`: Get all movies or filter by title
* `GET /api/movies?title=[name]`: Get movies containing [name] in title
* `POST /api/movies`: Create a new movie
* `DELETE /api/movies`: Delete all movies
* `GET /api/movies/:id`: Get a specific movie by ID
* `PUT /api/movies/:id`: Update a specific movie
* `DELETE /api/movies/:id`: Delete a specific movie

## Testing

Import the provided Postman collection to test all endpoints.