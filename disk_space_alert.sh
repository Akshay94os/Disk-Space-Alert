#!/usr/bin/env bash
set -u

LIMIT="${1:-80}"
REPORT_DIR="$(dirname "$0")/reports"
mkdir -p "$REPORT_DIR"
REPORT="$REPORT_DIR/disk_alert_$(date '+%Y%m%d_%H%M%S').txt"

if ! [[ "$LIMIT" =~ ^[0-9]+$ ]] || (( LIMIT > 100 )); then
  echo "Usage: $0 [limit_percent]"
  exit 1
fi

alert=0

{
  echo "===== DISK SPACE ALERT ====="
  echo "Date: $(date)"
  echo "Limit: ${LIMIT}%"
  echo

  while read -r filesystem size used avail percent mount; do
    [[ "$percent" =~ ^[0-9]+%$ ]] || continue
    usage="${percent%\%}"

    if (( usage >= LIMIT )); then
      echo "ALERT: $mount is ${usage}% full"
      alert=1
    fi
  done < <(df -P -x tmpfs -x devtmpfs | tail -n +2)

  if (( alert == 0 )); then
    echo "OK: No filesystem exceeded the limit."
  fi

  echo
  df -h
} | tee "$REPORT"

echo
echo "Report saved to: $REPORT"
exit "$alert"
