#!/usr/bin/env bash
# Restores a backup into a fresh database and verifies the data:
# compares row counts between the source database and the restore target.
# Usage: restore_db.sh <backup-file> [target-db]
set -euo pipefail

SRC="$1"
TARGET="${2:-restore_test}"
CONTAINER="${CONTAINER:-server-operations-lab-db-1}"
DB_USER="${POSTGRES_USER:-app}"
DB_NAME="${POSTGRES_DB:-appdb}"

[ -f "$SRC" ] || { echo "backup file not found: $SRC"; exit 1; }

echo "restoring $SRC into fresh database '$TARGET'"
docker exec "$CONTAINER" psql -U "$DB_USER" -d postgres -c "DROP DATABASE IF EXISTS \"$TARGET\" WITH (FORCE)"
docker exec "$CONTAINER" psql -U "$DB_USER" -d postgres -c "CREATE DATABASE \"$TARGET\""
docker exec -i "$CONTAINER" psql -U "$DB_USER" -d "$TARGET" -v ON_ERROR_STOP=1 -q < "$SRC"

orig=$(docker exec "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT count(*) FROM items")
rest=$(docker exec "$CONTAINER" psql -U "$DB_USER" -d "$TARGET" -tAc "SELECT count(*) FROM items")

if [ "$orig" = "$rest" ]; then
  echo "RESTORE VERIFIED: $rest rows match source ($orig)"
  exit 0
else
  echo "RESTORE MISMATCH: source=$orig restored=$rest"
  exit 1
fi
