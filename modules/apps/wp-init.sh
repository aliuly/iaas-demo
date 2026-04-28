#!/bin/bash
# =============================================================================
# cloud-init bootstrap — WordPress on Open Telekom Cloud ECS
#
# Responsibilities
#   1. Mount SFS Turbo share (NFS)
#   2. Detect scale-out (lock file on SFS) vs. first-time install
#   3. First-time install: LAMP stack + WP-CLI + WordPress + plugins
#   4. Every boot: symlink shared dirs, write wp-config.php, configure Nginx
#   5. Configure Authentik OAuth2 via OpenID-Connect plugin
#
# All software versions are pinned via Terraform variables — nothing is
# installed at "latest". To upgrade, update the variables and re-apply.
# =============================================================================
set -euo pipefail
#exec > >(tee /var/log/cloud-init-wordpress.log | logger -t cloud-init) 2>&1

# ── Helpers ──────────────────────────────────────────────────────────────────
log()  { echo "[$(date '+%Y-%m-%dT%H:%M:%S')] $*"; }
die()  { log "ERROR: $*" >&2; exit 1; }
retry() {
  local n=0 max=5
  until "$@"; do
    n=$((n+1)); [[ $n -lt $max ]] || die "Command failed after $max attempts: $*"
    log "Attempt $n failed, retrying in 10s …"; sleep 10
  done
}
# Inject variables
. /root/install-opts.sh

# =============================================================================
# STEP 1 — System updates & base packages
# =============================================================================

# ── WP-CLI — latest stable release ───────────────────────────────────────────
if ! command -v wp &>/dev/null ; then
  log "Installing WP-CLI …"
  retry curl -sL "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" \
    -o /usr/local/bin/wp
  chmod +x /usr/local/bin/wp
  WPCLI_VERSION=$(wp --version --allow-root)
  log "WP-CLI $WPCLI_VERSION installed"
else
  WPCLI_VERSION=$(wp --version --allow-root)
fi

#
# Common install tasks... (happens in all servers)
#
# ── Download WordPress core ───────────────────────────────────────────────
log "Downloading WordPress …"
mkdir -p "$WP_ROOT"
retry wp core download \
  --path="$WP_ROOT" \
  --locale=en_US \
  --allow-root
WP_VERSION=$(wp core version --path="$WP_ROOT" --allow-root)
log "WordPress $WP_VERSION downloaded"

# =============================================================================
# STEP 5 — Symlinks (every boot)
# =============================================================================
log "Configuring symlinks …"
mkdir -p "$WP_ROOT/wp-content"

# uploads — ln -sfn handles both missing and already-correct symlink
ln -sfn "$WP_UPLOADS_DIR" "$WP_ROOT/wp-content/uploads"
# chown -h www-data:www-data "$WP_ROOT/wp-content/uploads"

# ── Install PG4WP drop-in BEFORE wp core install ──────────────────────────
# PG4WP works by placing db.php into wp-content/, which WordPress loads
# before making any database connection.  It must be on disk before
# wp core install runs so that all DB operations go to PostgreSQL.
# We install it manually (download + unzip) to avoid needing a DB
# connection, which wp plugin install would require.
if [[ ! -f "$WP_ROOT/wp-content/db.php" ]]; then
  log "Installing PG4WP drop-in …"

  # Fetch the latest release zip URL from the GitHub API
  json=$(curl -sSL https://api.github.com/repos/kevinoid/postgresql-for-wordpress/releases/latest)
  PG4WP_VERSION="$(echo "$json" | jq -r .tag_name)"
  PG4WP_URL="$(echo "$json" | jq -r .zipball_url)"

  # Fall back to downloading the main branch if no release exists
  [[ -n "$PG4WP_URL" ]] \
    || die "Unable to find a suitable URL"

  retry curl -sL "$PG4WP_URL" -o /tmp/pg4wp.zip
  unzip -q /tmp/pg4wp.zip -d /tmp/pg4wp-src

  PG4WP_DB_PHP=$(find /tmp/pg4wp-src -name "db.php" | head -1)
  [[ -n "$PG4WP_DB_PHP" ]] || die "db.php not found in PG4WP archive"

  PG4WP_DIR=$(find /tmp/pg4wp-src -type d -name "pg4wp" | head -1)
  [[ -n "$PG4WP_DIR" ]] || die "pg4wp/ directory not found in PG4WP archive"

  # Drop-in and support directory
  cp "$PG4WP_DB_PHP" "$WP_ROOT/wp-content/db.php"
  cp -r "$PG4WP_DIR" "$WP_ROOT/wp-content/pg4wp"

  #~ # Plugin directory for WP admin visibility
  #~ PG4WP_PLUGIN_SRC=$(find /tmp/pg4wp-src -mindepth 1 -maxdepth 1 -type d | head -1)
  #~ mkdir -p "$WP_ROOT/wp-content/plugins/pg4wp"
  #~ cp -r "$PG4WP_PLUGIN_SRC/." "$WP_ROOT/wp-content/plugins/pg4wp/"
  #~ chown -R www-data:www-data \
    #~ "$WP_ROOT/wp-content/db.php" \
    #~ "$WP_ROOT/wp-content/pg4wp" \
    #~ "$WP_ROOT/wp-content/plugins/pg4wp"

  chown -R www-data:www-data \
    "$WP_ROOT/wp-content/db.php" \
    "$WP_ROOT/wp-content/pg4wp"

  rm -rf /tmp/pg4wp.zip /tmp/pg4wp-src
  log "PG4WP drop-in installed — WordPress will use PostgreSQL"
fi

# ── Install remaining plugins manually (no DB connection required) ────────
# All plugins are downloaded and extracted directly into wp-content/plugins/,
# the same way PG4WP is handled above.  All plugin files are on disk before
# wp core install runs.  wp plugin activate is called afterwards to register
# each plugin in wp_options — that is the only step that touches the DB.

install_plugin_zip() {
  local slug="$1" url="$2"
  local dest="$WP_ROOT/wp-content/plugins/$slug"
  if [[ -d "$dest" ]]; then
    log "Plugin $slug already on disk — skipping"
    return 0
  fi
  log "Downloading plugin $slug …"
  retry curl -sL "$url" -o "/tmp/${slug}.zip"
  unzip -q "/tmp/${slug}.zip" -d "$WP_ROOT/wp-content/plugins/"
  rm -f "/tmp/${slug}.zip"
  chown -R www-data:www-data "$dest"
  log "Plugin $slug installed"
}

# Fetch latest version number for a wordpress.org plugin slug
latest_plugin_version() {
  local slug="$1"
  curl -sS "https://api.wordpress.org/plugins/info/1.0/${slug}.json" \
    | jq -r '.version'
}

OIDC_VERSION=$(latest_plugin_version "daggerhart-openid-connect-generic")
W3TC_VERSION=$(latest_plugin_version "w3-total-cache")

install_plugin_zip "daggerhart-openid-connect-generic" \
  "https://downloads.wordpress.org/plugin/daggerhart-openid-connect-generic.${OIDC_VERSION}.zip"

install_plugin_zip "w3-total-cache" \
  "https://downloads.wordpress.org/plugin/w3-total-cache.${W3TC_VERSION}.zip"

# Write a version manifest to SFS for auditability on all nodes
cat > "$WP_ROOT/.versions" <<VERSIONS
wordpress=$WP_VERSION
wpcli=$WPCLI_VERSION
plugin_pg4wp=${PG4WP_VERSION:-unknown}
plugin_pg4wp_url=${PG4WP_URL:-none}
plugin_oidc=$OIDC_VERSION
plugin_w3tc=$W3TC_VERSION
installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
installed_on=$(hostname)
VERSIONS
log "Version manifest written to $WP_ROOT/.versions"

mountpoint -q "$SFS_MOUNT" || die "SFS Turbo mount failed"
log "SFS Turbo mounted successfully"

# =============================================================================
# STEP 3 — Scale-out detection (atomic NFS mkdir lock)
# =============================================================================
# Race condition protection: two nodes starting simultaneously would both see
# no lock file and both attempt a full install.  We use `mkdir` as an atomic
# NFS operation — exactly one node will succeed; all others either wait (if
# install is in progress) or skip (if install has already completed).
#
# States:
#   .install.lock/ dir exists, .installed absent → install in progress, wait
#   .installed file exists                        → scale-out node, skip
#   neither exists                                → we won the race, install

SALT_FILE="$WP_SHARED_DIR/.wp-salts.php"
if mkdir "$WP_SHARED_DIR" 2>/dev/null; then
  # We atomically created the Shared dir — we are the primary installer
  log "Acquired install lock (mkdir): this node will perform first-time install"
  FIRST_INSTALL=true

  # ── Generate auth salts (once, stored on SFS, shared by all nodes) ────────
  # The WordPress API returns a ready-to-include PHP snippet of define() calls.
  # It is stored on SFS but copied to the local fs and the copy is sourced
  # directly by wp-config.php via require_once,
  # so all nodes share identical salts without embedding them in wp-config.php.
  if [[ ! -f "$SALT_FILE" ]]; then
    log "Generating WordPress auth salts …"
    curl -sS https://api.wordpress.org/secret-key/1.1/salt/ > "$SALT_FILE"
    chmod 640 "$SALT_FILE"
    chown www-data:www-data "$SALT_FILE"
    log "Auth salts written to $SALT_FILE"
  fi
  mkdir -p "$WP_UPLOADS_DIR"
  chown -R www-data:www-data "$WP_UPLOADS_DIR"
else
  FIRST_INSTALL=false
  log "Lock file found: scale-out node — skipping first-time install"
  # Another node holds the install lock — wait for it to complete
  log "Install lock held by another node — waiting for first-time install to complete …"
  WAIT_SECS=0
  WAIT_MAX=1800   # 30 minutes ceiling
  while [[ ! -f "$WP_INSTALL_LOCK" ]]; do
    if [[ $WAIT_SECS -ge $WAIT_MAX ]]; then
      die "Timed out after ${WAIT_MAX}s waiting for primary install to complete. Check /var/log/cloud-init-wordpress.log on the primary node."
    fi
    sleep 15
    WAIT_SECS=$((WAIT_SECS + 15))
    log "  … still waiting (${WAIT_SECS}s elapsed)"
  done
  log "Primary install completed — proceeding as scale-out node"
fi

[[ ! -f "$SALT_FILE" ]] && die "$SALT_FILE: missing unable to continue"

#
# Generate wp config file
#

# ── Write wp-config.php (pre-install) ────────────────────────────────────
# wp core install reads wp-config.php to get DB credentials.
# Salts are not embedded — wp-config.php sources them from SFS via require_once.
log "Writing wp-config.php (pre-install) …"
WP_SALTS=$(cat "$SALT_FILE")
cat > "$WP_ROOT/wp-config.php" <<WPCONFIG
<?php
/**
 * WordPress configuration — generated by cloud-init.
 * Re-written on every boot by STEP 6.
 */

/*
 * This is needed to make sure that replacing MySQL with PostgreSQL
 * works properly...
 */
if ( ! defined( 'MYSQLI_REPORT_OFF' ) )        { define( 'MYSQLI_REPORT_OFF',        0 ); }
if ( ! defined( 'MYSQLI_REPORT_ERROR' ) )      { define( 'MYSQLI_REPORT_ERROR',       1 ); }
if ( ! defined( 'MYSQLI_REPORT_STRICT' ) )     { define( 'MYSQLI_REPORT_STRICT',      4 ); }
if ( ! defined( 'MYSQLI_REPORT_INDEX' ) )      { define( 'MYSQLI_REPORT_INDEX',       4 ); }
if ( ! defined( 'MYSQLI_REPORT_ALL' ) )        { define( 'MYSQLI_REPORT_ALL',       255 ); }

// ── Database (PostgreSQL via PG4WP) ─────────────────────────
define( 'DB_NAME',     '${DB_NAME}' );
define( 'DB_USER',     '${DB_USER}' );
define( 'DB_PASSWORD', '${DB_PASSWORD}' );
define( 'DB_HOST',     '${DB_HOST}:${DB_PORT}' );
define( 'DB_CHARSET',  'utf8' );
define( 'DB_COLLATE',  '' );

\$table_prefix = '${DB_PREFIX}';

// ── Authentication keys & salts ─────────────────────────────
${WP_SALTS}

// ── Environment ─────────────────────────────────────────────
define( 'WP_HOME',    'https://${WP_DOMAIN}' );
define( 'WP_SITEURL', 'https://${WP_DOMAIN}' );
define( 'WP_DEBUG',   false );
define( 'WP_DEBUG_LOG',     false );
define( 'WP_DEBUG_DISPLAY', false );

// Force HTTPS
if ( ! defined( 'FORCE_SSL_ADMIN' ) ) {
    define( 'FORCE_SSL_ADMIN', true );
}

// ── Uploads path (symlinked to SFS) ─────────────────────────
putenv( 'WP_UPLOADS_REL=wp-content/uploads' );
// Uploads live on SFS
if ( ! defined( 'UPLOADS' ) ) {
    define( 'UPLOADS', getenv('WP_UPLOADS_REL') ?: 'wp-content/uploads' );
}

// Multisite / load-balancer trust
if ( isset( \$_SERVER['HTTP_X_FORWARDED_PROTO'] ) &&
     \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https' ) {
    \$_SERVER['HTTPS'] = 'on';
}

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}
require_once ABSPATH . 'wp-settings.php';

WPCONFIG
chown www-data:www-data "$WP_ROOT/wp-config.php"
chmod 640 "$WP_ROOT/wp-config.php"

if [[ "$FIRST_INSTALL" == "true" ]]; then
  log "Running WordPress database install …"
  wp core install \
    --path="$WP_ROOT" \
    --url="https://$WP_DOMAIN" \
    --title="WordPress" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASS" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --skip-email \
    --allow-root
  #~ # ── Move uploads to SFS ───────────────────────────────────────────────────
  #~ log "Moving wp-content/uploads -> SFS …"
  #~ if [[ -d "$WP_ROOT/wp-content/uploads" ]]; then
    #~ rsync -a "$WP_ROOT/wp-content/uploads/" "$WP_UPLOADS_DIR/"
    #~ rm -rf "$WP_ROOT/wp-content/uploads"
  #~ fi

  # ── Activate plugins (DB now exists, files already on disk) ──────────────
  log "Activating plugins …"
  wp plugin activate daggerhart-openid-connect-generic \
    --path="$WP_ROOT" --allow-root
  wp plugin activate w3-total-cache \
    --path="$WP_ROOT" --allow-root || log "w3-total-cache activation failed — non-fatal"

  # ── Write completion lock, release in-progress sentinel ──────────────────
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) installed on $(hostname)" > "$WP_INSTALL_LOCK"
  log "Install complete. Lock file written: $WP_INSTALL_LOCK"
fi

# =============================================================================
# STEP 8 — Configure Authentik plugin options in DB (every boot, idempotent)
# =============================================================================
log "Applying Authentik OIDC plugin options …"
wp option update openid_connect_generic_settings \
  "{
    \"login_type\": \"auto\",
    \"client_id\": \"$AUTHENTIK_CLIENT_ID\",
    \"client_secret\": \"$AUTHENTIK_CLIENT_SECRET\",
    \"scope\": \"openid email profile\",
    \"endpoint_login\": \"$AUTHENTIK_BASE_URL/application/o/authorize/\",
    \"endpoint_userinfo\": \"$AUTHENTIK_BASE_URL/application/o/userinfo/\",
    \"endpoint_token\": \"$AUTHENTIK_BASE_URL/application/o/token/\",
    \"endpoint_end_session\": \"$AUTHENTIK_BASE_URL/application/o/end-session/\",
    \"identity_key\": \"preferred_username\",
    \"link_existing_users\": 1,
    \"create_if_does_not_exist\": 1,
    \"redirect_user_back\": 1,
    \"no_sslverify\": 0
  }" \
  --path="$WP_ROOT" --allow-root --format=json 2>/dev/null || true

log "Bootstrap complete on $(hostname) at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
log "Versions: WP=$WP_VERSION  OIDC=$OIDC_VERSION  W3TC=$W3TC_VERSION  WP-CLI=$WPCLI_VERSION"
