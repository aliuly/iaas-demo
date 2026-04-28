#!/bin/bash
# =============================================================================
# drop-wordpress-db.sh
#
# Drops the WordPress PostgreSQL database and application role.
# This is destructive and irreversible — use with care.
#
# Usage:
#   chmod +x drop-wordpress-db.sh
#   ./drop-wordpress-db.sh [options]
#
# Options:
#   -h HOST         RDS endpoint hostname or IP  (required)
#   -P PORT         RDS port                     (default: 5432)
#   -S SUPERUSER    RDS superuser username        (default: root)
#   -s SUPER_PASS   Superuser password            (required, or set PGPASSWORD)
#   -d DB_NAME      Database to drop              (default: wordpress)
#   -u APP_USER     Application role to drop      (default: wordpress)
#   -n              Dry-run: print SQL but do not execute
#   --help          Show this help
#
# Required apt packages:
#   postgresql-client
#
# Example:
#   ./drop-wordpress-db.sh -h 192.168.10.20 -S root -s "$RDS_SUPER_PASS"
# =============================================================================
set -euo pipefail

# ── Defaults ─────────────────────────────────────────────────────────────────
RDS_HOST=""
RDS_PORT="5432"
RDS_SUPERUSER="root"
RDS_SUPERUSER_PASS=""
APP_DB="wordpress"
APP_USER="wordpress"
DRY_RUN=false

# ── Helpers ──────────────────────────────────────────────────────────────────
log() { echo "[$(date '+%Y-%m-%dT%H:%M:%S')] $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

# ── Argument parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h) RDS_HOST="$2";           shift 2 ;;
    -P) RDS_PORT="$2";           shift 2 ;;
    -S) RDS_SUPERUSER="$2";      shift 2 ;;
    -s) RDS_SUPERUSER_PASS="$2"; shift 2 ;;
    -d) APP_DB="$2";             shift 2 ;;
    -u) APP_USER="$2";           shift 2 ;;
    -n) DRY_RUN=true;            shift   ;;
    --help) sed -n '/^# Usage:/,/^# ====/p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) die "Unknown option: $1. Use --help for usage." ;;
  esac
done

# ── Validate ─────────────────────────────────────────────────────────────────
[[ -n "$RDS_HOST" ]] || die "RDS host is required (-h)"

command -v psql &>/dev/null \
  || die "psql not found. Install with: sudo apt-get install -y postgresql-client"

# ── Prompt for password if not supplied ──────────────────────────────────────
if [[ "$DRY_RUN" == "false" && -z "$RDS_SUPERUSER_PASS" && -z "${PGPASSWORD:-}" ]]; then
  read -r -s -p "Enter password for RDS superuser '$RDS_SUPERUSER': " RDS_SUPERUSER_PASS
  echo
fi

# ── Confirmation prompt ───────────────────────────────────────────────────────
if [[ "$DRY_RUN" == "false" ]]; then
  echo ""
  echo "  WARNING: This will permanently drop:"
  echo "    Database : $APP_DB"
  echo "    Role     : $APP_USER"
  echo "    Host     : $RDS_HOST:$RDS_PORT"
  echo ""
  read -r -p "  Type the database name to confirm: " CONFIRM
  [[ "$CONFIRM" == "$APP_DB" ]] || die "Confirmation did not match — aborting"
fi

# ── SQL ───────────────────────────────────────────────────────────────────────
SQL_DROP_DB=$(cat <<SQL
-- Terminate any active connections to the database before dropping it.
-- (DROP DATABASE fails if any sessions are connected.)
SELECT pg_terminate_backend(pid)
FROM   pg_stat_activity
WHERE  datname = '$APP_DB'
  AND  pid <> pg_backend_pid();

-- Drop the database if it exists
DROP DATABASE IF EXISTS "$APP_DB";
SQL
)

SQL_DROP_ROLE=$(cat <<SQL
-- Drop the application role if it exists
DROP ROLE IF EXISTS "$APP_USER";
SQL
)

# ── Dry-run ───────────────────────────────────────────────────────────────────
if [[ "$DRY_RUN" == "true" ]]; then
  log "DRY RUN — SQL that would be executed:"
  echo ""
  echo "--- Step 1: Terminate connections and drop database ---"
  echo "$SQL_DROP_DB"
  echo ""
  echo "--- Step 2: Drop application role ---"
  echo "$SQL_DROP_ROLE"
  exit 0
fi

# ── Execute ───────────────────────────────────────────────────────────────────
PSQL_ARGS=(
  --host="$RDS_HOST"
  --port="$RDS_PORT"
  --username="$RDS_SUPERUSER"
  --no-password
  --set=ON_ERROR_STOP=1
  --dbname=postgres
)

[[ -n "$RDS_SUPERUSER_PASS" ]] && export PGPASSWORD="$RDS_SUPERUSER_PASS"

log "Connecting to $RDS_HOST:$RDS_PORT as '$RDS_SUPERUSER' …"

log "Step 1/2: Terminating connections and dropping database '$APP_DB' …"
psql "${PSQL_ARGS[@]}" <<< "$SQL_DROP_DB"

log "Step 2/2: Dropping role '$APP_USER' …"
psql "${PSQL_ARGS[@]}" <<< "$SQL_DROP_ROLE"

unset PGPASSWORD

log "Done. Database '$APP_DB' and role '$APP_USER' have been dropped."
