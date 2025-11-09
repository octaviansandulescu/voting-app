# Voting App

A simple web application that allows users to vote between dogs and cats, built with FastAPI and MySQL.

![CI Tests](https://github.com/octaviansandulescu/voting-app/workflows/CI%20Tests/badge.svg)

## Features

- Vote between dogs and cats
- Real-time results display
- Persistent storage using MySQL
- REST API with FastAPI
- Simple and responsive frontend
- Docker containerization

## Project Structure

```
voting-app/
├── src/
│   ├── frontend/              # Frontend files
│   │   ├── index.html        # Main HTML file
│   │   ├── style.css         # Styles
│   │   └── script.js         # JavaScript for voting and updates
│   │
│   └── backend/              # Backend application
│       ├── main.py           # FastAPI application
│       ├── database.py       # Database models and connection
│       ├── requirements.txt  # Python dependencies
│       ├── Dockerfile        # Backend container definition
│       └── tests/           # Unit tests
│           ├── __init__.py
│           └── test_api.py
│
├── docker-compose.yml        # Docker compose configuration
└── .github/
    └── workflows/
        └── ci.yml           # GitHub Actions CI configuration
```

## Prerequisites

- Docker
- Docker Compose

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/octaviansandulescu/voting-app.git
cd voting-app
```

2. Start the application:
```bash
docker-compose up --build
```

3. Access the application:
- Frontend: http://localhost
- Backend API: http://localhost:8000

## API Endpoints

### GET /results
Returns the current voting results.

Response:
```json
{
    "dogs": 10,
    "cats": 15
}
```

### POST /vote
Submit a vote.

Request body:
```json
{
    "choice": "dog"  // or "cat"
}
```

Response:
```json
{
    "message": "Vote recorded"
}
```

## Development

### Backend Development

1. Install Python dependencies:
```bash
cd src/backend
pip install -r requirements.txt
```

2. Run tests:
```bash
python -m pytest tests/
```

### Frontend Development

The frontend is served using Nginx in production, but for development, you can use any static file server:

```bash
cd src/frontend
python -m http.server 8080
```

## Testing

The project includes automated tests for the backend API. Run the tests with:

```bash
cd src/backend
python -m pytest tests/ --cov=.
```

## CI/CD

The project uses GitHub Actions for Continuous Integration, running:
- Python tests with coverage
- Frontend linting (if configured)

## Contributing

1. Fork the repository
2. Create a new branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
