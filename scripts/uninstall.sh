#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# Coirtx Uninstaller
#
# Removes a source-built Coirtx installation.
###############################################################################

APP_NAME="coirtx"

PREFIX="/opt/${APP_NAME}"
SYSCONFDIR="/etc/${APP_NAME}"
WEBROOT="${PREFIX}/ui"

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
echo "        COIRTX UNINSTALLER"
echo "==========================================="
echo
echo "This will permanently remove:"
echo
echo "  ${PREFIX}"
echo "  ${SYSCONFDIR}"
echo "  ${WEBROOT}"
echo "  PostgreSQL database: ${DB_NAME}"
echo "  PostgreSQL user: ${DB_USER}"
echo "  Linux user: ${SERVICE_USER}"
echo

read -rp "Continue? (yes/no): " ANSWER

[[ "$ANSWER" == "yes" ]] || {
    echo "Cancelled."
    exit 0
}

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

sudo rm -rf "${PREFIX}"

###############################################################################

echo
echo "Removing configuration..."

sudo rm -rf "${SYSCONFDIR}"

###############################################################################

echo
echo "Removing runtime files..."

sudo rm -rf "${LOGDIR}"
sudo rm -rf "${LIBDIR}"
sudo rm -rf "${RUNDIR}"

###############################################################################

echo
echo "Removing nginx configuration..."

sudo rm -f "${NGINX_ENABLED}"
sudo rm -f "${NGINX_AVAILABLE}"

sudo nginx -t && sudo systemctl reload nginx || true

###############################################################################

echo
echo "Removing systemd service..."

sudo systemctl disable "${SYSTEMD_SERVICE}" 2>/dev/null || true

sudo rm -f "/etc/systemd/system/${SYSTEMD_SERVICE}"
sudo rm -f "/etc/systemd/system/multi-user.target.wants/${SYSTEMD_SERVICE}"

sudo systemctl daemon-reload
sudo systemctl reset-failed

###############################################################################

echo
echo "Removing PostgreSQL database..."

sudo -u postgres psql <<EOF
DROP DATABASE IF EXISTS ${DB_NAME};
DROP ROLE IF EXISTS ${DB_USER};
EOF

###############################################################################

echo
echo "Removing Linux user/group..."

sudo userdel "${SERVICE_USER}" 2>/dev/null || true
sudo groupdel "${SERVICE_GROUP}" 2>/dev/null || true

###############################################################################

echo
echo "Removing nginx logs..."

sudo rm -f "/var/log/nginx/${APP_NAME}.access.log"
sudo rm -f "/var/log/nginx/${APP_NAME}.error.log"

###############################################################################

echo
echo "Searching for remaining Coirtx files..."

find /opt -iname "*coirtx*" 2>/dev/null || true
find /etc -iname "*coirtx*" 2>/dev/null || true
find /var -iname "*coirtx*" 2>/dev/null || true

###############################################################################

echo
echo "==========================================="
echo "Coirtx has been removed."
echo "==========================================="

###############################################################################
echo
echo "==========================================="
echo "Verification"
echo "==========================================="

echo
echo "=== Installation ==="
find /opt -iname "*coirtx*" 2>/dev/null

echo
echo "=== Config ==="
find /etc -iname "*coirtx*" 2>/dev/null

echo
echo "=== Runtime ==="
find /var -iname "*coirtx*" 2>/dev/null

echo
echo "=== Running Processes ==="
ps aux | grep -Ei "coirtx|zabbix" | grep -v grep || true

echo
echo "=== PostgreSQL Database ==="
sudo -u postgres psql -tAc "SELECT datname FROM pg_database WHERE datname='${DB_NAME}';"

echo
echo "=== PostgreSQL Role ==="
sudo -u postgres psql -tAc "SELECT rolname FROM pg_roles WHERE rolname='${DB_USER}';"

echo
echo "=== Linux User ==="
id "${SERVICE_USER}" 2>/dev/null || echo "No user"

echo
echo "=== Linux Group ==="
getent group "${SERVICE_GROUP}" || echo "No group"

echo
echo "=== systemd ==="
systemctl list-unit-files | grep -i "${APP_NAME}" || true
