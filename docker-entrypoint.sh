#!/bin/sh
set -e

# Run as postgres user if started as root
if [ "$(id -u)" = '0' ]; then
    exec su-exec postgres "$0" "$@"
fi

# Initialize database if PGDATA is empty
if [ "$1" = 'postgres' ] && [ -z "$(ls -A "$PGDATA" 2>/dev/null)" ]; then
    # Set password file for initdb
    if [ -n "$POSTGRES_PASSWORD" ]; then
        PWFILE=$(mktemp)
        printf '%s' "$POSTGRES_PASSWORD" > "$PWFILE"
        INITDB_OPTS="--pwfile=$PWFILE"
        AUTH_METHOD="scram-sha-256"
    elif [ "${POSTGRES_HOST_AUTH_METHOD:-}" = 'trust' ]; then
        AUTH_METHOD="trust"
        INITDB_OPTS=""
    else
        echo "Error: POSTGRES_PASSWORD must be set or POSTGRES_HOST_AUTH_METHOD=trust" >&2
        exit 1
    fi

    initdb \
        --username="${POSTGRES_USER:-postgres}" \
        --auth-host="$AUTH_METHOD" \
        --auth-local="$AUTH_METHOD" \
        $INITDB_OPTS \
        "$PGDATA"

    [ -n "${PWFILE:-}" ] && rm -f "$PWFILE"

    # Configure listening
    echo "listen_addresses = '*'" >> "$PGDATA/postgresql.conf"

    # Allow connections from anywhere (container networking)
    echo "host all all all $AUTH_METHOD" >> "$PGDATA/pg_hba.conf"

    # Create additional user/database if specified
    if [ -n "$POSTGRES_DB" ] || [ -n "$POSTGRES_USER" ]; then
        # Temporarily allow local connections without password for setup
        HBA_BACKUP="$PGDATA/pg_hba.conf.backup"
        cp "$PGDATA/pg_hba.conf" "$HBA_BACKUP"
        echo "local all all trust" > "$PGDATA/pg_hba.conf"
        echo "host all all all trust" >> "$PGDATA/pg_hba.conf"

        pg_ctl -D "$PGDATA" -o "-c listen_addresses=''" -w start

        # Connect to the postgres database (which always exists) for running SQL commands
        PSQL_CMD="psql -v ON_ERROR_STOP=1 --username ${POSTGRES_USER:-postgres} --dbname postgres"

        if [ "$POSTGRES_DB" != 'postgres' ] && [ -n "$POSTGRES_DB" ]; then
            $PSQL_CMD <<-EOSQL
                CREATE DATABASE "$POSTGRES_DB";
EOSQL
        fi

        # Run init scripts if present
        for f in /docker-entrypoint-initdb.d/*; do
            case "$f" in
                *.sh)  echo "Running $f"; . "$f" ;;
                *.sql) echo "Running $f"; $PSQL_CMD -f "$f" ;;
                *)     echo "Ignoring $f" ;;
            esac
        done 2>/dev/null || true

        pg_ctl -D "$PGDATA" -m fast -w stop

        # Restore original pg_hba.conf with proper authentication
        mv "$HBA_BACKUP" "$PGDATA/pg_hba.conf"
    fi

    echo "PostgreSQL init complete; ready for start up."
fi

exec "$@"