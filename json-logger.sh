#!/bin/sh
# json-logger.sh
# Converts PGBouncer log lines into JSON for Railway structured logging.
#
# PGBouncer log format:
#   2026-02-23 10:23:48.621 UTC [1] LOG C-0x55bcf8a48570: message...
#   2026-02-23 10:23:48.621 UTC [1] WARNING message...
#   2026-02-23 10:23:48.621 UTC [1] ERROR message...
#
# Output JSON format (for Railway structured logging):
#   {"level":"info","timestamp":"2026-02-23T10:23:48.621Z","pid":"1","message":"..."}
#
# Uses POSIX awk (compatible with busybox/mawk on Alpine).

exec awk '{
  # Fields: $1=date $2=time $3=TZ $4=[pid] $5=LEVEL $6..=message
  # Validate: $1 looks like a date and $4 looks like [number]
  if ($1 ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ && $4 ~ /^\[[0-9]+\]$/) {
    date = $1
    time = $2
    pid = $4
    gsub(/[\[\]]/, "", pid)
    raw_level = $5

    # Map PGBouncer levels to standard levels
    if (raw_level == "LOG")          level = "info"
    else if (raw_level == "DEBUG")   level = "debug"
    else if (raw_level == "WARNING") level = "warn"
    else if (raw_level == "ERROR")   level = "error"
    else if (raw_level == "FATAL")   level = "fatal"
    else if (raw_level == "PANIC")   level = "fatal"
    else                             level = "info"

    # Build message from remaining fields
    msg = ""
    for (i = 6; i <= NF; i++) {
      if (i > 6) msg = msg " "
      msg = msg $i
    }

    # Build ISO8601 timestamp
    timestamp = date "T" time "Z"

    # Escape JSON special characters in message
    gsub(/\\/, "\\\\", msg)
    gsub(/"/, "\\\"", msg)
    gsub(/\t/, "\\t", msg)
    gsub(/\r/, "\\r", msg)

    printf "{\"level\":\"%s\",\"timestamp\":\"%s\",\"pid\":\"%s\",\"message\":\"%s\"}\n", level, timestamp, pid, msg
  } else {
    # Lines that do not match the expected format: output as-is in JSON
    msg = $0
    gsub(/\\/, "\\\\", msg)
    gsub(/"/, "\\\"", msg)
    gsub(/\t/, "\\t", msg)
    gsub(/\r/, "\\r", msg)
    printf "{\"level\":\"info\",\"message\":\"%s\"}\n", msg
  }

  # Flush after each line for real-time output
  fflush()
}'
