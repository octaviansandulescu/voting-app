import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from main import app
from database import Base, Vote
from sqlalchemy.pool import StaticPool

# Create a test database in memory
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create the database tables
Base.metadata.create_all(bind=engine)

# Override the get_db dependency
def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

from main import get_db
app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)

def test_vote_endpoint():
    response = client.post("/vote", json={"choice": "dog"})
    assert response.status_code == 200
    assert response.json() == {"message": "Vote recorded"}

def test_invalid_vote():
    response = client.post("/vote", json={"choice": "invalid"})
    assert response.status_code == 400
    assert "Invalid choice" in response.json()["detail"]

def test_get_results():
    # Add some test votes
    db = TestingSessionLocal()
    db.add(Vote(choice="dog"))
    db.add(Vote(choice="cat"))
    db.add(Vote(choice="dog"))
    db.commit()

    response = client.get("/results")
    assert response.status_code == 200
    result = response.json()
    assert result["dogs"] == 2
    assert result["cats"] == 1