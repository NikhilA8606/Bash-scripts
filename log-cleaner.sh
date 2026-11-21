#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="${1:-$HOME/app-logs}"   # folder to clean
COMPRESS_AFTER="${2:-7}"         # compress .log files older than 7 days
DELETE_AFTER="${3:-30}"          # delete .gz files older than 30 days

if [ ! -d "$LOG_DIR" ]; then
  echo "ERROR: folder $LOG_DIR does not exist" >&2
  exit 1
fi

echo "$(date '+%F %T') Cleaning $LOG_DIR"

# 1. Compress old logs
find "$LOG_DIR" -type f -name "*.log" -mtime +"$COMPRESS_AFTER" -exec gzip -f {} \;

# 2. Delete very old compressed logs (and print what was deleted)
find "$LOG_DIR" -type f -name "*.log.gz" -mtime +"$DELETE_AFTER" -print -delete

echo "Done."
