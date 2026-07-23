from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_root_endpoint_get():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "version" in data


def test_root_endpoint_head():
    response = client.request("HEAD", "/")
    assert response.status_code == 200
    # For HEAD requests, body should be empty, but status must be 200
    assert response.text == ""


def test_health_endpoint_get():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert "database" in data
    assert "redis" in data
    assert "version" in data

    if data["database"] == "healthy" and data["redis"] == "healthy":
        assert data["status"] == "healthy"
    else:
        assert data["status"] == "unhealthy"


def test_health_endpoint_head():
    response = client.request("HEAD", "/health")
    assert response.status_code == 200
    assert response.text == ""


def test_versioned_health_endpoint_get():
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert "database" in data
    assert "redis" in data
    assert "version" in data

    if data["database"] == "healthy" and data["redis"] == "healthy":
        assert data["status"] == "healthy"
    else:
        assert data["status"] == "unhealthy"


def test_docs_endpoints():
    # Test docs pages and openapi specifications at the root level
    assert client.get("/docs").status_code == 200
    assert client.get("/redoc").status_code == 200
    assert client.get("/openapi.json").status_code == 200
