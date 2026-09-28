"""
FastAPI application for the Server Operations Lab.

Deliberately small: the point of the project is operating the service
(deployment, monitoring, backup), not the application itself.

Endpoints:
  GET  /health  -> process is up (no dependencies checked)
  GET  /ready   -> readiness (DB connectivity arrives in the PostgreSQL module)
  GET  /items   -> list items
  POST /items   -> create an item

Storage: in-memory list for now; swapped for PostgreSQL in the DB module.
"""
from fastapi import FastAPI

app = FastAPI(title="Server Operations Lab API")

# ponytail: in-memory storage, replaced by PostgreSQL in the DB module
items: list[dict] = []


@app.get("/health")
def health():
    """Liveness: the API process is responding."""
    return {"status": "ok"}


@app.get("/ready")
def ready():
    """Readiness: the API can serve requests using its dependencies."""
    return {"status": "ready"}


@app.get("/items")
def list_items():
    return {"items": items}


@app.post("/items")
def create_item(name: str):
    item = {"id": len(items) + 1, "name": name}
    items.append(item)
    return item
