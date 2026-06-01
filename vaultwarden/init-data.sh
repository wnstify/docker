#!/bin/bash
set -e

if [ -n "${POSTGRES_NON_ROOT_USER:-}" ] && [ -n "${POSTGRES_NON_ROOT_PASSWORD:-}" ]; then
    psql -v ON_ERROR_STOP=1 \
        --username "$POSTGRES_USER" \
        --dbname "$POSTGRES_DB" \
        --set=app_user="$POSTGRES_NON_ROOT_USER" \
        --set=app_pass="$POSTGRES_NON_ROOT_PASSWORD" \
        --set=app_db="$POSTGRES_DB" <<'EOSQL'
CREATE USER :"app_user" WITH PASSWORD :'app_pass';
GRANT CONNECT ON DATABASE :"app_db" TO :"app_user";
GRANT ALL PRIVILEGES ON DATABASE :"app_db" TO :"app_user";
GRANT USAGE, CREATE ON SCHEMA public TO :"app_user";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO :"app_user";
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO :"app_user";
EOSQL
fi
