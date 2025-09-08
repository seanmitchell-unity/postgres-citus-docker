-- Create the nibbler database if it doesn't exist
SELECT 'CREATE DATABASE nibbler' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'nibbler')\gexec

-- Connect to the nibbler database
\c nibbler

-- Create extensions in the nibbler database
CREATE EXTENSION IF NOT EXISTS citus;
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_partman;

-- Create the nibbler role if it doesn't exist (with error handling)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'nibbler') THEN
        CREATE ROLE nibbler WITH LOGIN;
        ALTER ROLE nibbler CREATEDB;
    END IF;
END
$$;

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE nibbler TO nibbler;
GRANT ALL ON SCHEMA public TO nibbler;
GRANT ALL ON SCHEMA partman TO nibbler;

-- Grant cron permissions
GRANT USAGE ON SCHEMA cron TO nibbler;
GRANT ALL ON ALL TABLES IN SCHEMA cron TO nibbler;
