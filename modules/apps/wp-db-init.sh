#!/bin/bash
# =============================================================================
# create-wordpress-db.sh
#
# Creates the WordPress PostgreSQL database, application role, and all
# required privileges on an existing RDS PostgreSQL instance.
#
# Run this ONCE before the first `tofu apply`, from any machine that has
# network access to the RDS endpoint (bastion host, VPN client, CI runner).
#
# Usage:
#   chmod +x create-wordpress-db.sh
#   ./create-wordpress-db.sh [options]
#
# Options:
#   -h HOST         RDS endpoint hostname or IP  (required)
#   -P PORT         RDS port                     (default: 5432)
#   -S SUPERUSER    RDS superuser username        (default: root)
#   -d DB_NAME      Database to create            (default: wordpress)
#   -u APP_USER     Application role to create    (default: wordpress)
#   -p APP_PASS     Application role password     (required)
#   -s SUPER_PASS   Superuser password            (required, or set PGPASSWORD)
#   -n              Dry-run: print SQL but do not execute
#   --help          Show this help
#
# Required apt packages (Debian/Ubuntu):
#   postgresql-client     provides psql
#
#   Install with:
#   sudo apt-get update && sudo apt-get install -y postgresql-client
#
# Examples:
#   # Interactive password prompts
#   ./create-wordpress-db.sh -h 192.168.10.20 -S root -u wordpress -p myAppPass
#
#   # Fully non-interactive (CI usage)
#   ./create-wordpress-db.sh \
#       -h 192.168.10.20 -P 5432 \
#       -S root       -s "$RDS_SUPER_PASS" \
#       -d wordpress  -u wordpress -p "$RDS_APP_PASS"
#
#   # Dry-run to review the SQL first
#   ./create-wordpress-db.sh -h 192.168.10.20 -u wordpress -p secret -n
# =============================================================================
set -euo pipefail

# ── Defaults ─────────────────────────────────────────────────────────────────
RDS_HOST=""
RDS_PORT="5432"
RDS_SUPERUSER="root"
RDS_SUPERUSER_PASS=""
APP_DB="wordpress"
APP_USER="wordpress"
APP_PASS=""
DRY_RUN=false

# ── Helpers ──────────────────────────────────────────────────────────────────
log()  { echo "[$(date '+%Y-%m-%dT%H:%M:%S')] $*"; }
die()  { echo "ERROR: $*" >&2; exit 1; }
usage() {
  sed -n '/^# Usage:/,/^# ====/p' "$0" | sed 's/^# \?//'
  exit 0
}

# ── Argument parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h) RDS_HOST="$2";          shift 2 ;;
    -P) RDS_PORT="$2";          shift 2 ;;
    -S) RDS_SUPERUSER="$2";     shift 2 ;;
    -s) RDS_SUPERUSER_PASS="$2"; shift 2 ;;
    -d) APP_DB="$2";            shift 2 ;;
    -u) APP_USER="$2";          shift 2 ;;
    -p) APP_PASS="$2";          shift 2 ;;
    -n) DRY_RUN=true;           shift   ;;
    --help) usage ;;
    *) die "Unknown option: $1. Use --help for usage." ;;
  esac
done

# ── Validate required arguments ───────────────────────────────────────────────
[[ -n "$RDS_HOST"  ]] || die "RDS host is required (-h)"
[[ -n "$APP_USER"  ]] || die "Application username is required (-u)"

# Prompt for passwords if not supplied and not in dry-run mode
if [[ "$DRY_RUN" == "false" ]]; then
  if [[ -z "$RDS_SUPERUSER_PASS" && -z "${PGPASSWORD:-}" ]]; then
    read -r -s -p "Enter password for RDS superuser '$RDS_SUPERUSER': " RDS_SUPERUSER_PASS
    echo
  fi
  if [[ -z "$APP_PASS" ]]; then
    read -r -s -p "Enter password for application role '$APP_USER': " APP_PASS
    echo
    read -r -s -p "Confirm password for '$APP_USER': " APP_PASS_CONFIRM
    echo
    [[ "$APP_PASS" == "$APP_PASS_CONFIRM" ]] || die "Passwords do not match"
  fi
fi

# ── Dependency check ──────────────────────────────────────────────────────────
if ! command -v psql &>/dev/null; then
  die "psql not found. Install with: sudo apt-get install -y postgresql-client"
fi

PSQL_VERSION=$(psql --version | awk '{print $3}' | cut -d. -f1)
log "Using psql version $PSQL_VERSION"

# ── Build the SQL ─────────────────────────────────────────────────────────────
# Escape the password for use in SQL (single-quote doubling)
ESCAPED_PASS="${APP_PASS//\'/\'\'}"

SQL=$(cat <<SQL
-- =============================================================
-- WordPress database provisioning
-- Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
-- Target:    $RDS_HOST:$RDS_PORT
-- Database:  $APP_DB
-- Role:      $APP_USER
-- =============================================================

-- ── 1. Create the application role if it does not exist ──────
DO \$\$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_catalog.pg_roles WHERE rolname = '$APP_USER'
  ) THEN
    CREATE ROLE "$APP_USER"
      LOGIN
      PASSWORD '$ESCAPED_PASS'
      NOSUPERUSER
      NOCREATEDB
      NOCREATEROLE
      INHERIT
      NOREPLICATION;
    RAISE NOTICE 'Role "$APP_USER" created.';
  ELSE
    RAISE NOTICE 'Role "$APP_USER" already exists — skipping creation.';
  END IF;
END
\$\$;

-- ── 2. Create the database if it does not exist ──────────────
-- PostgreSQL has no CREATE DATABASE IF NOT EXISTS, so we use
-- a DO block to check pg_database first.
DO \$\$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_catalog.pg_database WHERE datname = '$APP_DB'
  ) THEN
    PERFORM dblink_exec(
      'dbname=postgres',
      'CREATE DATABASE "$APP_DB"
         OWNER "$APP_USER"
         ENCODING ''UTF8''
         LC_COLLATE ''en_US.UTF-8''
         LC_CTYPE   ''en_US.UTF-8''
         CONNECTION LIMIT -1'
    );
    RAISE NOTICE 'Database "$APP_DB" created.';
  ELSE
    RAISE NOTICE 'Database "$APP_DB" already exists — skipping creation.';
  END IF;
END
\$\$;
SQL
)

# CREATE DATABASE cannot run inside a transaction block, so we use a
# two-pass approach: the DO/dblink trick above handles the idempotency
# check, but some RDS instances may not have dblink available.
# We use a simpler and more reliable two-step method below instead.

SQL_ROLE=$(cat <<SQL
-- ── Step 1: role (runs in postgres DB) ──────────────────────
DO \$\$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_catalog.pg_roles WHERE rolname = '$APP_USER'
  ) THEN
    CREATE ROLE "$APP_USER"
      LOGIN
      PASSWORD '$ESCAPED_PASS'
      NOSUPERUSER
      NOCREATEDB
      NOCREATEROLE
      INHERIT
      NOREPLICATION;
    RAISE NOTICE 'Role "$APP_USER" created.';
  ELSE
    RAISE NOTICE 'Role "$APP_USER" already exists — skipping.';
  END IF;
END
\$\$;
SQL
)

SQL_DB=$(cat <<SQL
-- ── Step 2: database (must run outside transaction block) ────
SELECT 'CREATE DATABASE "$APP_DB"
  OWNER "$APP_USER"
  ENCODING ''UTF8''
  LC_COLLATE ''en_US.UTF-8''
  LC_CTYPE   ''en_US.UTF-8''
  CONNECTION LIMIT -1'
WHERE NOT EXISTS (
  SELECT FROM pg_catalog.pg_database WHERE datname = '$APP_DB'
)\gexec
SQL
)

SQL_GRANTS=$(cat <<SQL
-- ── Step 3: grants (runs in the new database) ────────────────
-- Note: ALTER SCHEMA public OWNER is intentionally omitted.
-- RDS does not grant true superuser, so the superuser role cannot
-- transfer ownership of the public schema.  Instead we grant the
-- app role full rights on the schema it already owns (public),
-- and set default privileges so WP-CLI-created objects are
-- accessible without requiring a superuser grant later.

-- Revoke default public privileges
REVOKE ALL ON DATABASE "$APP_DB" FROM PUBLIC;

-- Grant database-level privileges to the app role
GRANT CONNECT, CREATE, TEMPORARY ON DATABASE "$APP_DB" TO "$APP_USER";

-- Grant schema-level privileges (superuser retains ownership on RDS)
GRANT ALL ON SCHEMA public TO "$APP_USER";

-- Default privileges granted BY the superuser so that any objects
-- the superuser creates are also accessible to the app role.
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON TABLES TO "$APP_USER";

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, UPDATE, USAGE
  ON SEQUENCES TO "$APP_USER";

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT EXECUTE
  ON FUNCTIONS TO "$APP_USER";

-- Default privileges granted BY the app role itself so that objects
-- WP-CLI creates (connecting as the app role) are accessible to itself.
ALTER DEFAULT PRIVILEGES FOR ROLE "$APP_USER" IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON TABLES TO "$APP_USER";

ALTER DEFAULT PRIVILEGES FOR ROLE "$APP_USER" IN SCHEMA public
  GRANT SELECT, UPDATE, USAGE
  ON SEQUENCES TO "$APP_USER";

ALTER DEFAULT PRIVILEGES FOR ROLE "$APP_USER" IN SCHEMA public
  GRANT EXECUTE
  ON FUNCTIONS TO "$APP_USER";
SQL
)

# ── Dry-run: print and exit ───────────────────────────────────────────────────
if [[ "$DRY_RUN" == "true" ]]; then
  log "DRY RUN — SQL that would be executed:"
  echo ""
  echo "--- Step 1: Connect to 'postgres' DB as superuser ---"
  echo "$SQL_ROLE"
  echo ""
  echo "--- Step 2: Create database (outside transaction) ---"
  echo "$SQL_DB"
  echo ""
  echo "--- Step 3: Connect to '$APP_DB' DB to set grants ---"
  echo "$SQL_GRANTS"
  exit 0
fi

# ── Execute ───────────────────────────────────────────────────────────────────
# Build psql connection args
PSQL_ARGS=(
  --host="$RDS_HOST"
  --port="$RDS_PORT"
  --username="$RDS_SUPERUSER"
  --no-password
  --set=ON_ERROR_STOP=1
)

# Export superuser password for psql (avoids it appearing in process list)
if [[ -n "$RDS_SUPERUSER_PASS" ]]; then
  export PGPASSWORD="$RDS_SUPERUSER_PASS"
fi

log "Connecting to $RDS_HOST:$RDS_PORT as '$RDS_SUPERUSER' …"

# Step 1 — create role
log "Step 1/3: Creating application role '$APP_USER' …"
psql "${PSQL_ARGS[@]}" --dbname=postgres <<< "$SQL_ROLE"

# Step 2 — create database (outside transaction block, hence a separate call)
log "Step 2/3: Creating database '$APP_DB' …"
psql "${PSQL_ARGS[@]}" --dbname=postgres <<< "$SQL_DB"

# Step 3 — grants (connect to the new database)
log "Step 3/3: Applying grants on database '$APP_DB' …"
psql "${PSQL_ARGS[@]}" --dbname="$APP_DB" <<< "$SQL_GRANTS"

# ── Verify ────────────────────────────────────────────────────────────────────
log "Verifying …"
psql "${PSQL_ARGS[@]}" --dbname=postgres --tuples-only --no-align <<< "
SELECT
  r.rolname        AS role,
  r.rolcanlogin    AS can_login,
  d.datname        AS database,
  d.datcollate     AS collation,
  pg_encoding_to_char(d.encoding) AS encoding
FROM pg_catalog.pg_roles r
JOIN pg_catalog.pg_database d ON d.datdba = r.oid
WHERE r.rolname = '$APP_USER'
  AND d.datname = '$APP_DB';
" | column -t -s '|'

unset PGPASSWORD

log "Done. Database '$APP_DB' and role '$APP_USER' are ready."
log "You can now populate terraform.tfvars and run: tofu apply"
