#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# Ktrix Uninstaller
#
# Removes a source-built Ktrix installation from Ubuntu.
#
# This script removes:
#   - Installed binaries
#   - Configuration
#   - Web frontend
#   - Runtime directories
#   - Logs
#   - systemd service
#   - nginx configuration
#   - PostgreSQL database
#   - PostgreSQL user
#   - Linux service user/group
#
###############################################################################

APP_NAME="ktrix"

PREFIX="/opt/${APP_NAME}"
SYSCONFDIR="/etc/${APP_NAME}"
WEBROOT="/opt/${APP_NAME}/ui"

LOGDIR="/var/log/${APP_NAME}"
LIBDIR="/var/lib/${APP_NAME}"
RUNDIR="/run/${APP_NAME}"

SYSTEMD_SERVICE="${APP_NAME}-server.service"

NGINX_AVAILABLE="/etc/nginx/sites-available/${APP_NAME}"
NGINX_ENABLED="/etc/nginx/sites-enabled/${APP_NAME}"

DB_NAME="${APP_NAME}"
DB_USER="${APP_NAME}"

SERVICE_USER="${APP_NAME}"
SERVICE_GROUP="${APP_NAME}"

###############################################################################

echo
echo "==========================================="
echo "         KTRIX UNINSTALLER"
echo "==========================================="
echo
echo "This will permanently remove:"
echo
echo "  $PREFIX"
echo "  $SYSCONFDIR"
echo "  $WEBROOT"
echo "  PostgreSQL database: $DB_NAME"
echo "  PostgreSQL user: $DB_USER"
echo "  Linux user: $SERVICE_USER"
echo
read -rp "Continue? (yes/no): " ANSWER

if [[ "$ANSWER" != "yes" ]]; then
    echo "Cancelled."
    exit 0
fi

###############################################################################
echo
echo "Stopping services..."

sudo systemctl stop "${SYSTEMD_SERVICE}" 2>/dev/null || true

sudo pkill zabbix_server 2>/dev/null || true
sudo pkill zabbix_proxy 2>/dev/null || true
sudo pkill zabbix_agentd 2>/dev/null || true
sudo pkill zabbix_agent2 2>/dev/null || true
sudo pkill zabbix_web_service 2>/dev/null || true

###############################################################################
echo
echo "Removing installation..."

sudo rm -rf "$PREFIX"

###############################################################################
echo
echo "Removing configuration..."

sudo rm -rf "$SYSCONFDIR"

###############################################################################
echo
echo "Removing runtime files..."

sudo rm -rf "$LOGDIR"
sudo rm -rf "$LIBDIR"
sudo rm -rf "$RUNDIR"

###############################################################################
echo
echo "Removing nginx configuration..."

sudo rm -f "$NGINX_ENABLED"
sudo rm -f "$NGINX_AVAILABLE"

sudo nginx -t && sudo systemctl reload nginx || true

###############################################################################
echo
echo "Removing systemd service..."

sudo rm -f "/etc/systemd/system/${SYSTEMD_SERVICE}"
sudo systemctl daemon-reload

###############################################################################
echo
echo "Removing PostgreSQL database..."

sudo -u postgres psql <<EOF
DROP DATABASE IF EXISTS ${DB_NAME};
DROP ROLE IF EXISTS ${DB_USER};
EOF

###############################################################################
echo
echo "Removing Linux user..."

sudo userdel "${SERVICE_USER}" 2>/dev/null || true
sudo groupdel "${SERVICE_GROUP}" 2>/dev/null || true

###############################################################################
echo
echo "Searching for remaining Ktrix files..."

find /opt -iname "*ktrix*" 2>/dev/null || true
find /etc -iname "*ktrix*" 2>/dev/null || true
find /var -iname "*ktrix*" 2>/dev/null || true


echo
echo "Removing nginx logs..."

sudo rm -f /var/log/nginx/${APP_NAME}.access.log
sudo rm -f /var/log/nginx/${APP_NAME}.error.log

###############################################################################
echo
echo "==========================================="
echo "Ktrix has been removed."
echo "==========================================="
echo



echo
echo "==========================================="
echo "Verification."
echo "==========================================="
echo

echo "=== Installation ==="
find /opt -iname "*ktrix*" 2>/dev/null

echo
echo "=== Config ==="
find /etc -iname "*ktrix*" 2>/dev/null

echo
echo "=== Runtime ==="
find /var -iname "*ktrix*" 2>/dev/null

echo
echo "=== Processes ==="
ps aux | grep -Ei "ktrix|zabbix" | grep -v grep

echo
echo "=== PostgreSQL Databases ==="
sudo -u postgres psql -tAc "SELECT datname FROM pg_database WHERE datname='ktrix';"

echo
echo "=== PostgreSQL Roles ==="
sudo -u postgres psql -tAc "SELECT rolname FROM pg_roles WHERE rolname='ktrix';"

echo
echo "=== Linux User ==="
id ktrix 2>/dev/null || echo "No user"

echo
echo "=== Linux Group ==="
getent group ktrix || echo "No group"

echo
echo "=== systemd ==="
systemctl list-unit-files | grep -i ktrix || true
