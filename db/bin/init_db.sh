#!/bin/bash
set -euo pipefail

DIR="/app/sql/init"

for file in "$DIR"/*.sql; do
  echo "Loading exercise: $(basename "$file")"
  psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -f "$file"
done