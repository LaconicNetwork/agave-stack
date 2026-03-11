#!/bin/bash
# Idempotent InfluxDB initialization.
#
# The influxdb:1.8 image only runs /docker-entrypoint-initdb.d/ scripts when
# the data directory is empty. After cluster recreation the data dir has stale
# files so auto-init is skipped. This script runs on every container start to
# ensure the database and admin user exist regardless of data dir state.
#
# Mounted at /docker-entrypoint-initdb.d/init-db.sh for fresh starts, and also
# called explicitly from the entrypoint wrapper for restarts with existing data.

set -e

INFLUXDB_URL="${INFLUXDB_URL:-http://localhost:8086}"
DB="${INFLUXDB_DB:-agave_metrics}"
ADMIN="${INFLUXDB_ADMIN_USER:-admin}"
PASS="${INFLUXDB_ADMIN_PASSWORD:-admin}"

wait_for_influxdb() {
    for i in $(seq 1 30); do
        if influx -execute "SHOW DATABASES" >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    echo "ERROR: InfluxDB not ready after 30s" >&2
    return 1
}

wait_for_influxdb

# Create admin user (idempotent — errors if exists, which is fine)
influx -execute "CREATE USER ${ADMIN} WITH PASSWORD '${PASS}' WITH ALL PRIVILEGES" 2>/dev/null || true

# Create database (idempotent)
influx -username "${ADMIN}" -password "${PASS}" \
    -execute "CREATE DATABASE ${DB}" 2>/dev/null || true

echo "InfluxDB init complete: db=${DB}, user=${ADMIN}"
