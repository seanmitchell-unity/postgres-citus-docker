# custom PostgreSQL 17 image with Citus, pg_partman, and pg_cron
FROM postgres:17-bullseye

RUN apt-get update && \
    apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    wget

RUN curl https://install.citusdata.com/community/deb.sh | bash && \
    apt-get install -y postgresql-17-citus-13.0

RUN apt-get install -y \
    postgresql-17-cron \
    postgresql-17-partman

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configure shared_preload_libraries - this is critical for proper startup
RUN echo "shared_preload_libraries = 'citus'" >> /usr/share/postgresql/postgresql.conf.sample

# Copy the initialization script
COPY init-extensions.sql /docker-entrypoint-initdb.d/

EXPOSE 5432
