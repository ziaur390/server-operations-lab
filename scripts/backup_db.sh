#!/usr/bin/env bash
# Creates a PostgreSQL backup via pg_dump inside the db container.
# Prints the backup file path; exits non-zero on failure.
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-$(cd "$(dirname "$0")/.." && pwd)/backups}"
CONTAINER="${CONTAINER:-server-operations-lab-db-1}"
DB_USER="${POSTGRES_USER:-app}"
DB_NAME="${POSTGRES_DB:-appdb}"

mkdir -p "$BACKUP_DIR"
OUT="$BACKUP_DIR/${DB_NAME}_$(date +%F_%H%M%S).sql"

docker exec "$CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" > "$OUT"
echo "backup written: $OUT"
