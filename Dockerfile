FROM postgres:17-bookworm

LABEL maintainer="Sean Mitchell <seanmitchell@unity3d.com>"
LABEL description="PostgreSQL 17 with Citus, pg_partman, pg_cron extensions"

# Install PostgreSQL extensions
RUN set -ex && \
    apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    curl https://install.citusdata.com/community/deb.sh | bash && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        postgresql-17-citus-13.0 \
        postgresql-17-cron \
        postgresql-17-partman && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add minimal configuration for extensions
RUN echo "shared_preload_libraries = 'citus,pg_cron,pg_partman_bgw'" >> /usr/share/postgresql/postgresql.conf.sample

# Copy initialization script
COPY init-extensions.sql /docker-entrypoint-initdb.d/

EXPOSE 5432
