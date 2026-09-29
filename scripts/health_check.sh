#!/usr/bin/env bash
# Health check: host resources + application endpoints.
# Appends one timestamped line per check to logs/health.log.
# Exit code 0 = all healthy, 1 = something failed (usable by cron/CI).
set -u

LOG_DIR="${LOG_DIR:-$(cd "$(dirname "$0")/.." && pwd)/logs}"
mkdir -p "$LOG_DIR" 2>/dev/null || LOG_DIR=/tmp
LOG="$LOG_DIR/health.log"
BASE_URL="${BASE_URL:-http://localhost}"
FAIL=0

log() { echo "$(date '+%F %T') $1" >> "$LOG"; }

# --- host checks ---
df_out=$(df -h / | awk 'NR==2{print $5}' | tr -d '%')
if [ "$df_out" -gt 90 ]; then log "WARN host disk: ${df_out}% used"; FAIL=1; else log "OK host disk: ${df_out}% used"; fi

mem_avail=$(free -m | awk 'NR==2{print $7}')
if [ "$mem_avail" -lt 200 ]; then log "WARN host memory: only ${mem_avail}MB available"; FAIL=1; else log "OK host memory: ${mem_avail}MB available"; fi

load1=$(awk '{print $1}' /proc/loadavg)
if awk -v l="$load1" 'BEGIN{exit !(l>2)}'; then log "WARN host load: ${load1}"; FAIL=1; else log "OK host load: ${load1}"; fi

if systemctl is-active --quiet docker; then log "OK host service docker: active"; else log "WARN host service docker: $(systemctl is-active docker)"; FAIL=1; fi
# nginx runs as a container (Compose) — checked below with the other containers

# --- application checks (health + readiness) ---
for path in /health /ready; do
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$BASE_URL$path")
  if [ "$code" = 200 ]; then log "OK app $path: $code"; else log "WARN app $path: HTTP $code"; FAIL=1; fi
done

expected="server-operations-lab-api-1 server-operations-lab-db-1 server-operations-lab-nginx-1"
for c in $expected; do
  state=$(docker inspect -f '{{.State.Status}}' "$c" 2>/dev/null || echo missing)
  if [ "$state" = running ]; then log "OK container $c: running"; else log "WARN container $c: $state"; FAIL=1; fi
done

log "SUMMARY: $([ $FAIL -eq 0 ] && echo all-healthy || echo failures-detected)"
exit $FAIL
