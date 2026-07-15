#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# COIRTX Uninstaller
#
# Removes a source-built COIRTX installation.
###############################################################################

APP_NAME="coirtx"
APP_TITLE="COIRTX"

PREFIX="/opt/${APP_NAME}"
SYSCONFDIR="/etc/${APP_NAME}"

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
echo "        ${APP_TITLE} UNINSTALLER"
echo "==========================================="
echo
echo "This will permanently remove:"
echo
echo "  ${PREFIX}"
echo "  ${SYSCONFDIR}"
echo "  PostgreSQL database : ${DB_NAME}"
echo "  PostgreSQL role     : ${DB_USER}"
echo "  Linux user          : ${SERVICE_USER}"
echo

read -rp "Type 'yes' to continue: " ANSWER

[[ "$ANSWER" == "yes" ]] || {
    echo "Cancelled."
    exit 0
}

###############################################################################
echo
echo "Stopping services..."

sudo systemctl stop "${SYSTEMD_SERVICE}" 2>/dev/null || true
sudo systemctl disable "${SYSTEMD_SERVICE}" 2>/dev/null || true

sudo pkill -f coirtx_server 2>/dev/null || true
sudo pkill -f coirtx_proxy 2>/dev/null || true
sudo pkill -f coirtx_agentd 2>/dev/null || true
sudo pkill -f coirtx_agent2 2>/dev/null || true
sudo pkill -f coirtx_web_service 2>/dev/null || true

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

sudo nginx -t >/dev/null 2>&1 && sudo systemctl reload nginx || true

###############################################################################
echo
echo "Removing systemd service..."

sudo rm -f "/etc/systemd/system/${SYSTEMD_SERVICE}"
sudo systemctl daemon-reload

###############################################################################
echo
echo "Removing PostgreSQL database and role..."

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
echo "Searching for remaining ${APP_TITLE} files..."

find /opt -iname "*${APP_NAME}*" 2>/dev/null || true
find /etc -iname "*${APP_NAME}*" 2>/dev/null || true
find /var -iname "*${APP_NAME}*" 2>/dev/null || true

###############################################################################
echo
echo "==========================================="
echo "${APP_TITLE} has been removed."
echo "==========================================="

echo
echo "==========================================="
echo "Verification"
echo "==========================================="

echo
echo "=== Installation ==="
find /opt -iname "*${APP_NAME}*" 2>/dev/null || true

echo
echo "=== Configuration ==="
find /etc -iname "*${APP_NAME}*" 2>/dev/null || true

echo
echo "=== Runtime ==="
find /var -iname "*${APP_NAME}*" 2>/dev/null || true

echo
echo "=== Processes ==="
ps aux | grep -Ei "${APP_NAME}" | grep -v grep || echo "None"

echo
echo "=== PostgreSQL Database ==="
sudo -u postgres psql -tAc "SELECT datname FROM pg_database WHERE datname='${DB_NAME}';"

echo
echo "=== PostgreSQL Role ==="
sudo -u postgres psql -tAc "SELECT rolname FROM pg_roles WHERE rolname='${DB_USER}';"

echo
echo "=== Linux User ==="
id "${SERVICE_USER}" 2>/dev/null || echo "None"

echo
echo "=== Linux Group ==="
getent group "${SERVICE_GROUP}" || echo "None"

echo
echo "=== systemd ==="
systemctl list-unit-files | grep -i "${APP_NAME}" || echo "None"

echo
echo "Done."
