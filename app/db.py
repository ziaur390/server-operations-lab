"""
PostgreSQL connectivity.

Settings come from environment variables with sane local defaults,
so the app can run with `docker run postgres` during development and
inside Compose in the next module without code changes.
"""
import os

import psycopg

_conninfo = None


def _settings():
    return {
        "host": os.getenv("POSTGRES_HOST", "127.0.0.1"),
        "port": os.getenv("POSTGRES_PORT", "5432"),
        "dbname": os.getenv("POSTGRES_DB", "appdb"),
        "user": os.getenv("POSTGRES_USER", "app"),
        "password": os.getenv("POSTGRES_PASSWORD", "changeme"),
    }


def get_conn():
    """One connection per request. Lab-sized: fine at this traffic level."""
    global _conninfo
    if _conninfo is None:
        s = _settings()
        _conninfo = f"host={s['host']} port={s['port']} dbname={s['dbname']} user={s['user']} password={s['password']}"
    return psycopg.connect(_conninfo, connect_timeout=3)


def init_db():
    """Create the items table if it does not exist. Idempotent."""
    with get_conn() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS items (
                id   SERIAL PRIMARY KEY,
                name TEXT NOT NULL
            )
            """
        )
