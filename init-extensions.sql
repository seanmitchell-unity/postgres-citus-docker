-- Install required extensions for Nibbler PostgreSQL 17 with Citus, pg_partman, and pg_cron
-- This script runs during database initialization

-- Install Citus extension for distributed database functionality
CREATE EXTENSION IF NOT EXISTS citus;

-- Install pg_cron extension for scheduled jobs
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Create partman schema and install pg_partman extension
CREATE SCHEMA IF NOT EXISTS partman;
CREATE EXTENSION IF NOT EXISTS pg_partman SCHEMA partman CASCADE;

-- Grant necessary permissions to the nibbler user for partman
GRANT USAGE ON SCHEMA partman TO nibbler;
GRANT ALL ON ALL TABLES IN SCHEMA partman TO nibbler;
GRANT ALL ON ALL SEQUENCES IN SCHEMA partman TO nibbler;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA partman TO nibbler;

-- Install pg_stat_statements for query statistics
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
