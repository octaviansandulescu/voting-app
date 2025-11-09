import os
import pytest
from fastapi.testclient import TestClient
from main import app

# Set testing environment
os.environ["TESTING"] = "true"

client = TestClient(app)

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
    # Adaugă câteva voturi pentru test
    client.post("/vote", json={"choice": "dog"})
    client.post("/vote", json={"choice": "cat"})
    client.post("/vote", json={"choice": "dog"})
    
    response = client.get("/results")
    assert response.status_code == 200
    result = response.json()
    assert result["dogs"] == 2
    assert result["cats"] == 1