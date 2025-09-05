-- Create extensions in the default database
CREATE EXTENSION IF NOT EXISTS citus;
CREATE EXTENSION IF NOT EXISTS pg_partman;

-- Create nibbler role for background workers
CREATE ROLE nibbler WITH LOGIN;

-- Create nibbler database for pg_cron
CREATE DATABASE nibbler;