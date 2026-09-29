"""API self-checks. Run against a real PostgreSQL (CI service container
or the lab-vm). Requires POSTGRES_* env or the defaults in app/db.py."""
from fastapi.testclient import TestClient

from app.main import app


def test_health():
    with TestClient(app) as client:
        assert client.get("/health").json() == {"status": "ok"}


def test_ready():
    with TestClient(app) as client:
        assert client.get("/ready").status_code == 200


def test_items_roundtrip():
    with TestClient(app) as client:
        created = client.post("/items?name=ci-item")
        assert created.status_code == 200
        names = [i["name"] for i in client.get("/items").json()["items"]]
        assert "ci-item" in names
