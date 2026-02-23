#!/bin/bash
# run-json.sh
# Wraps the original PGBouncer run.sh and pipes all output through json-logger.sh
# This ensures Railway correctly classifies log levels instead of marking everything as "error".

set -o errexit
set -o nounset
set -o pipefail

# Use a FIFO so PGBouncer gets proper signal handling
LOG_FIFO=/tmp/pgbouncer-log
mkfifo "$LOG_FIFO"

# Start JSON logger reading from FIFO in background, outputting to stdout
/json-logger.sh < "$LOG_FIFO" &

# Run the original run.sh with all output redirected to the FIFO
exec /opt/bitnami/scripts/pgbouncer/run.sh "$@" > "$LOG_FIFO" 2>&1
