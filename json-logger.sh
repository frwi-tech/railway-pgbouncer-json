#!/bin/sh
# json-logger.sh
# Converts PGBouncer log lines into JSON for Railway structured logging.
#
# Handles two log formats:
#
# 1. PGBouncer native format:
#   2026-02-23 10:23:48.621 UTC [1] LOG C-0x55bcf8a48570: message...
#   2026-02-23 10:23:48.621 UTC [1] WARNING message...
#
# 2. Bitnami setup format (with ANSI color codes):
#   pgbouncer 11:01:20.42 INFO ==> Welcome to the Bitnami pgbouncer container
#   pgbouncer 11:01:20.42 WARN ==> Some warning
#
# Output JSON format (for Railway structured logging):
#   {"level":"info","timestamp":"...","message":"..."}

exec awk '{
  # Strip ANSI color/escape codes first
  line = $0
  gsub(/\033\[[0-9;]*m/, "", line)
  gsub(/\[38;5;[0-9]+m/, "", line)
  gsub(/\[0m/, "", line)
  gsub(/\[1m/, "", line)

  # Re-parse fields from cleaned line
  n = split(line, f)

  # Format 1: PGBouncer native log
  # Fields: f[1]=date f[2]=time f[3]=TZ f[4]=[pid] f[5]=LEVEL f[6..]=message
  if (f[1] ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ && f[4] ~ /^\[[0-9]+\]$/) {
    date = f[1]
    time = f[2]
    pid = f[4]
    gsub(/[\[\]]/, "", pid)
    raw_level = f[5]

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
    for (i = 6; i <= n; i++) {
      if (i > 6) msg = msg " "
      msg = msg f[i]
    }

    timestamp = date "T" time "Z"

    # Escape JSON special characters in message
    gsub(/\\/, "\\\\", msg)
    gsub(/"/, "\\\"", msg)
    gsub(/\t/, "\\t", msg)
    gsub(/\r/, "\\r", msg)

    printf "{\"level\":\"%s\",\"timestamp\":\"%s\",\"pid\":\"%s\",\"message\":\"%s\"}\n", level, timestamp, pid, msg

  # Format 2: Bitnami setup log
  # Fields: f[1]=pgbouncer f[2]=HH:MM:SS.ms f[3]=LEVEL f[4]==> f[5..]=message
  } else if (f[1] == "pgbouncer" && f[3] ~ /^(INFO|WARN|ERROR|DEBUG)$/ && f[4] == "==>") {
    raw_level = f[3]
    if (raw_level == "INFO")       level = "info"
    else if (raw_level == "WARN")  level = "warn"
    else if (raw_level == "ERROR") level = "error"
    else if (raw_level == "DEBUG") level = "debug"
    else                           level = "info"

    msg = ""
    for (i = 5; i <= n; i++) {
      if (i > 5) msg = msg " "
      msg = msg f[i]
    }

    gsub(/\\/, "\\\\", msg)
    gsub(/"/, "\\\"", msg)
    gsub(/\t/, "\\t", msg)
    gsub(/\r/, "\\r", msg)

    printf "{\"level\":\"%s\",\"message\":\"%s\"}\n", level, msg

  } else {
    # Lines that do not match any known format: output as-is in JSON
    msg = line
    # Skip empty lines
    if (msg ~ /^[[:space:]]*$/) { fflush(); next }

    gsub(/\\/, "\\\\", msg)
    gsub(/"/, "\\\"", msg)
    gsub(/\t/, "\\t", msg)
    gsub(/\r/, "\\r", msg)
    printf "{\"level\":\"info\",\"message\":\"%s\"}\n", msg
  }

  # Flush after each line for real-time output
  fflush()
}'
