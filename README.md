# PostgreSQL 17 + Citus + pg_partman + pg_cron

A Docker image extending the official PostgreSQL 17 image with essential extensions for distributed databases and automation.

## Features

- **PostgreSQL 17** - Latest PostgreSQL with performance improvements
- **Citus 13.0** - Distributed PostgreSQL for horizontal scaling
- **pg_cron** - Job scheduler for PostgreSQL (configured for `nibbler` database)
- **pg_partman** - Automated partition management (configured with `nibbler` role)

## Image

`ghcr.io/seanmitchell-unity/citus-pg17`

Available tags:
- `latest` - Built from main branch
- `vX.Y.Z` - Tagged releases
- Branch and SHA tags for development

## Quick Start

```bash
# Pull and run the image
docker run --rm -d \
  --name pg-citus \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  ghcr.io/seanmitchell-unity/citus-pg17:latest

# Connect to PostgreSQL
docker exec -it pg-citus psql -U postgres
```

### Testing Extensions

```sql
-- Check all installed extensions
\dx

-- Test Citus functionality
SELECT citus_version();

-- Test pg_cron (must connect to nibbler database)
\c nibbler
SELECT * FROM cron.job;

-- Test pg_partman
SELECT * FROM partman.part_config;
```

## Configuration

The image is pre-configured with:

- `shared_preload_libraries = 'citus,pg_cron,pg_partman_bgw'`
- `cron.database_name = 'nibbler'` (pg_cron database)
- `pg_partman_bgw.role = 'nibbler'` (partition maintenance role)
- `pg_partman_bgw.dbname = 'nibbler'` (partition maintenance database)
- `pg_partman_bgw.interval = 3600` (maintenance interval in seconds)

### Database Layout

- **Default database** (e.g., `postgres`, `testdb`): Contains Citus and pg_partman extensions
- **nibbler database**: Contains Citus, pg_cron, and pg_partman extensions (required for pg_cron configuration)
- **nibbler role**: Created automatically for pg_partman background worker

## Development

### Local Testing

```bash
# Run the comprehensive test suite
./test-local.sh
```

### Manual Testing

```bash
# Build and test locally
docker build -t postgres-citus-test .
docker run --rm -d \
  --name postgres-test \
  -e POSTGRES_PASSWORD=testpass \
  -e POSTGRES_DB=testdb \
  -p 5432:5432 \
  postgres-citus-test

# Connect and verify
docker exec -it postgres-test psql -U postgres -d testdb
```

## Publishing

After the first publish, make the package public:
1. Go to GitHub → Packages → select `citus-pg17`
2. Package settings → Change visibility → Public