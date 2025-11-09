import os
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from main import app, get_db
from database import Base, Vote

# Create test database
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Set testing environment
os.environ["TESTING"] = "true"

client = TestClient(app)

@pytest.fixture(autouse=True)
def setup_database():
    # Create the test database tables
    Base.metadata.create_all(bind=engine)
    
    # Run the test
    yield
    
    # Clean up (drop all tables after each test)
    Base.metadata.drop_all(bind=engine)

@pytest.fixture
def client():
    # Override the get_db dependency
    def override_get_db():
        try:
            db = TestingSessionLocal()
            yield db
        finally:
            db.close()
    
    app.dependency_overrides[get_db] = override_get_db
    return TestClient(app)

def test_vote_endpoint(client):
    response = client.post("/vote", json={"choice": "dog"})
    assert response.status_code == 200
    assert response.json() == {"message": "Vote recorded"}

def test_invalid_vote(client):
    response = client.post("/vote", json={"choice": "invalid"})
    assert response.status_code == 400
    assert "Invalid choice" in response.json()["detail"]

def test_get_results(client):
    # Add test votes one by one
    response = client.post("/vote", json={"choice": "dog"})
    assert response.status_code == 200
    
    response = client.post("/vote", json={"choice": "cat"})
    assert response.status_code == 200
    
    response = client.post("/vote", json={"choice": "dog"})
    assert response.status_code == 200
    
    response = client.get("/results")
    assert response.status_code == 200
    result = response.json()
    assert result["dogs"] == 2
    assert result["cats"] == 1