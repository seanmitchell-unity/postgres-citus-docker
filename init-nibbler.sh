#!/bin/bash
set -e

echo "Creating extensions in nibbler database..."

# Create extensions in nibbler database
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname nibbler <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS citus;
    CREATE EXTENSION IF NOT EXISTS pg_cron;
    CREATE EXTENSION IF NOT EXISTS pg_partman;
EOSQL