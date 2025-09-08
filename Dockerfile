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

RUN echo "shared_preload_libraries = 'citus,pg_cron,pg_partman_bgw'" >> /usr/share/postgresql/postgresql.conf.sample && \
    echo "cron.database_name = 'nibbler'" >> /usr/share/postgresql/postgresql.conf.sample && \
    echo "pg_partman_bgw.interval = 3600" >> /usr/share/postgresql/postgresql.conf.sample && \
    echo "pg_partman_bgw.role = 'nibbler'" >> /usr/share/postgresql/postgresql.conf.sample && \
    echo "pg_partman_bgw.dbname = 'nibbler'" >> /usr/share/postgresql/postgresql.conf.sample

COPY init-extensions.sql /docker-entrypoint-initdb.d/

EXPOSE 5432
