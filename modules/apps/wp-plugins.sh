#!/bin/bash
# This script is dedicated to installing the additional required plugins
set -euo pipefail

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

if ! command -v wp &>/dev/null ; then
  log "Missing WP-CLI …"
else
  WPCLI_VERSION=$(wp --version --allow-root)
  log "using WP-CLI $WPCLI_VERSION"
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

VDATA=""
plugins="
  daggerhart-openid-connect-generic:openid_connect_generic_settings
"
jsdata="/root/wp-plugins"

for pair in $plugins
do
  plugin=$(echo "$pair"|cut -d: -f1)
  settings=$(echo "$pair"|cut -d: -f2)

  plugin_version=$(latest_plugin_version "$plugin")
  plugin_url="https://downloads.wordpress.org/plugin/$plugin.${plugin_version}.zip"
  log "$plugin: $plugin_version"
  install_plugin_zip "$plugin" "$plugin_url"
  VDATA=$(echo "$VDATA" ; echo "$plugin $plugin_version")
  log "Activating $plugin"
  wp plugin activate "$plugin" --path="$WP_ROOT" --allow-root
  if [ -f "$jsdata/$plugin.json" ] && [ -n "$settings" ] ; then
    log "$plugin: configuring from $plugin.json"
    wp option update "$settings" \
      "$(cat "$jsdata/$plugin.json")" \
      --format=json --allow-root --path=/var/www/html/wordpress
  fi
done


# Write a version manifest
cat > "$WP_ROOT/.plugins" <<VERSIONS
installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
installed_on=$(hostname)
$VDATA
VERSIONS
log "Version manifest written to $WP_ROOT/.plugins"

log "Plugin install complete on $(hostname) at $(date -u +%Y-%m-%dT%H:%M:%SZ)"

  #~ wp option get openid_connect_generic_settings --format=json --allow-root
  #~ --path=/var/www/html/wordpress

  #~ That output can then be fed directly back into wp option update to recreate the settings:

