"""
FastAPI application for the Server Operations Lab.

Deliberately small: the point of the project is operating the service
(deployment, monitoring, backup), not the application itself.

Endpoints:
  GET  /health  -> process is up (no dependencies checked)
  GET  /ready   -> readiness: PostgreSQL reachable
  GET  /items   -> list items from PostgreSQL
  POST /items   -> create an item in PostgreSQL
"""
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException

from app import db


@asynccontextmanager
async def lifespan(app: FastAPI):
    db.init_db()
    yield


app = FastAPI(title="Server Operations Lab API", lifespan=lifespan)


@app.get("/health")
def health():
    """Liveness: the API process is responding."""
    return {"status": "ok"}


@app.get("/ready")
def ready():
    """Readiness: the API can reach PostgreSQL."""
    try:
        with db.get_conn() as conn:
            conn.execute("SELECT 1")
        return {"status": "ready"}
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"database unreachable: {e}")


@app.get("/items")
def list_items():
    with db.get_conn() as conn:
        rows = conn.execute("SELECT id, name FROM items ORDER BY id").fetchall()
    return {"items": [{"id": r[0], "name": r[1]} for r in rows]}


@app.post("/items")
def create_item(name: str):
    with db.get_conn() as conn:
        row = conn.execute(
            "INSERT INTO items (name) VALUES (%s) RETURNING id, name", (name,)
        ).fetchone()
    return {"id": row[0], "name": row[1]}
