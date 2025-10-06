#!/usr/bin/env bash
set -euo pipefail

DB_PATH=${1:-"./db/app.sqlite"}
SCHEMA_FILE="./db/migrations/001_init.sql"

mkdir -p "$(dirname "$DB_PATH")"

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "sqlite3 not found. Please install sqlite3." >&2
  exit 1
fi

if [ -f "$DB_PATH" ]; then
  echo "Database exists at $DB_PATH. Skipping create." >&2
  exit 0
fi

sqlite3 "$DB_PATH" < "$SCHEMA_FILE"
echo "Created database at $DB_PATH"
