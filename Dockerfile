# PostgreSQL 17 with Citus, pg_partman, and pg_cron extensions
# Based on official PostgreSQL 17 image with production-ready extensions for distributed partitioned databases
FROM postgres:17-bookworm

LABEL maintainer="Sean Mitchell <seanmitchell@unity3d.com>"
LABEL description="PostgreSQL 17 with Citus (distributed database), pg_partman (partitioning), and pg_cron (scheduled jobs)"
LABEL version="17-1.0.0"

# Install required packages and extensions in a single layer to minimize image size
RUN set -ex && \
    # Update package lists
    apt-get update && \
    # Install dependencies
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        gnupg \
        lsb-release \
        wget && \
    # Install Citus repository and extension
    curl https://install.citusdata.com/community/deb.sh | bash && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        postgresql-17-citus-13.0 \
        postgresql-17-cron \
        postgresql-17-partman && \
    # Clean up to reduce image size
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create custom postgresql.conf template with required extensions
# This approach is more maintainable than modifying the existing template
COPY postgresql-custom.conf /etc/postgresql/postgresql.conf.d/

# Copy initialization scripts
COPY init-extensions.sql /docker-entrypoint-initdb.d/01-init-extensions.sql

# Set proper ownership for configuration files
RUN chown -R postgres:postgres /etc/postgresql/

EXPOSE 5432

# Health check to ensure the database is ready
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pg_isready -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-postgres} || exit 1
