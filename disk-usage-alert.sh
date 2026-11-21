#!/usr/bin/env bash
set -euo pipefail

THRESHOLD="${1:-80}"     # alert at 80% unless you pass another number
MOUNT="/"                # which disk to check

# Get usage as a plain number, e.g. 23
USAGE=$(df --output=pcent "$MOUNT" | tail -n 1 | tr -dc '0-9')

TIMESTAMP=$(date '+%F %T')

if [ "$USAGE" -ge "$THRESHOLD" ]; then
  echo "$TIMESTAMP ALERT: disk usage on $MOUNT is ${USAGE}% (threshold ${THRESHOLD}%)"
  exit 1
else
  echo "$TIMESTAMP OK: disk usage on $MOUNT is ${USAGE}%"
fi