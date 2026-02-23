#!/bin/bash
# entrypoint-json.sh
# Wraps the original Bitnami entrypoint to redirect ALL output (including setup messages)
# through the JSON logger, so Railway correctly classifies log levels.

set -o nounset
set -o pipefail

# Clean up any stale FIFO from previous runs (e.g. crash restarts)
LOG_FIFO=/tmp/pgbouncer-log
rm -f "$LOG_FIFO"
mkfifo "$LOG_FIFO"

# Start JSON logger reading from FIFO in background, outputting to real stdout
/json-logger.sh < "$LOG_FIFO" &
JSON_LOGGER_PID=$!

# Run the original entrypoint with all output redirected to the FIFO.
# The original entrypoint ends with `exec "$@"` which will exec the CMD (run-json.sh),
# but since we're already redirecting, we pass the original run.sh directly.
exec /opt/bitnami/scripts/pgbouncer/entrypoint.sh /opt/bitnami/scripts/pgbouncer/run.sh "$@" > "$LOG_FIFO" 2>&1
