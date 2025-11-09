import pytest
from fastapi.testclient import TestClient
from main import app

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
    response = client.get("/results")
    assert response.status_code == 200
    assert "dogs" in response.json()
    assert "cats" in response.json()