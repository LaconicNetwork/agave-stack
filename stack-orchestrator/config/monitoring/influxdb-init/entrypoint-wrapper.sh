#!/bin/bash
# Wrapper entrypoint for influxdb:1.8 that ensures database and admin user
# exist on every start, not just on first init with empty data dir.
#
# Starts influxd in the background, runs idempotent init, then replaces the
# shell with influxd in the foreground.

set -e

INIT_SCRIPT="/docker-entrypoint-initdb.d/init-db.sh"

# Start influxd in the background
influxd &
INFLUXD_PID=$!

# Run init (waits for influxd to be ready)
if [ -x "${INIT_SCRIPT}" ]; then
    "${INIT_SCRIPT}"
fi

# Stop the background influxd gracefully
kill "${INFLUXD_PID}"
wait "${INFLUXD_PID}" 2>/dev/null || true

# Exec influxd in the foreground (PID 1, receives signals properly)
exec influxd
