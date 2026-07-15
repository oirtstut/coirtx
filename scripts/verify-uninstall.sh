#!/usr/bin/env bash

set -u

###############################################################################
# Coirtx Uninstall Verification
###############################################################################

APP_NAME="coirtx"

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

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

PASS=0
FAIL=0

pass() {
    echo -e "${GREEN}[PASS]${RESET} $1"
    ((PASS++))
}

fail() {
    echo -e "${RED}[FAIL]${RESET} $1"
    ((FAIL++))
}

section() {
    echo
    echo "===================================================="
    echo "$1"
    echo "===================================================="
}

###############################################################################

echo
echo "==============================================="
echo "      COIRTX UNINSTALL VERIFICATION"
echo "==============================================="

###############################################################################
section "Installation Directories"

for dir in \
    "$PREFIX" \
    "$SYSCONFDIR" \
    "$LOGDIR" \
    "$LIBDIR" \
    "$RUNDIR"
do
    if [[ -e "$dir" ]]; then
        fail "$dir still exists"
    else
        pass "$dir removed"
    fi
done

###############################################################################
section "Remaining Files"

FOUND=$(find /opt /etc /var -iname "*coirtx*" 2>/dev/null)

if [[ -z "$FOUND" ]]; then
    pass "No remaining Coirtx files found"
else
    fail "Remaining Coirtx files/directories:"
    echo "$FOUND"
fi

###############################################################################
section "Processes"

RUNNING=0

for proc in \
    zabbix_server \
    zabbix_proxy \
    zabbix_agentd \
    zabbix_agent2 \
    zabbix_web_service
do
    if pgrep -x "$proc" >/dev/null; then
        fail "$proc is still running"
        RUNNING=1
    fi
done

[[ $RUNNING -eq 0 ]] && pass "No Coirtx/Zabbix processes running"

###############################################################################
section "systemd"

if systemctl list-unit-files | grep -q "^${SYSTEMD_SERVICE}"; then
    fail "Systemd service still installed"
else
    pass "Systemd service removed"
fi

###############################################################################
section "Nginx"

[[ -f "$NGINX_AVAILABLE" ]] \
    && fail "sites-available entry still exists" \
    || pass "sites-available removed"

[[ -f "$NGINX_ENABLED" ]] \
    && fail "sites-enabled entry still exists" \
    || pass "sites-enabled removed"

if sudo nginx -t >/dev/null 2>&1; then
    pass "Nginx configuration valid"
else
    fail "Nginx configuration invalid"
fi

###############################################################################
section "PostgreSQL"

if sudo -u postgres psql -tAc \
"SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1
then
    fail "Database still exists"
else
    pass "Database removed"
fi

if sudo -u postgres psql -tAc \
"SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | grep -q 1
then
    fail "Role still exists"
else
    pass "Role removed"
fi

###############################################################################
section "Linux User"

if id "$SERVICE_USER" >/dev/null 2>&1; then
    fail "Linux user still exists"
else
    pass "Linux user removed"
fi

if getent group "$SERVICE_GROUP" >/dev/null; then
    fail "Linux group still exists"
else
    pass "Linux group removed"
fi

###############################################################################
section "Installed Executables"

FOUND=$(find /opt -type f \( \
    -name "zabbix_server" \
    -o -name "zabbix_proxy" \
    -o -name "zabbix_agentd" \
    -o -name "zabbix_agent2" \
    -o -name "zabbix_web_service" \
\) 2>/dev/null)

if [[ -z "$FOUND" ]]; then
    pass "No installed executables found"
else
    fail "Executables still present:"
    echo "$FOUND"
fi

###############################################################################
section "Listening Ports"

PORTS=$(sudo ss -ltnp | grep zabbix || true)

if [[ -z "$PORTS" ]]; then
    pass "No listening Zabbix/Coirtx services"
else
    fail "Services still listening:"
    echo "$PORTS"
fi

###############################################################################

echo
echo "==============================================="
echo "Verification Summary"
echo "==============================================="

echo
echo -e "Passed : ${GREEN}${PASS}${RESET}"
echo -e "Failed : ${RED}${FAIL}${RESET}"

echo

if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}✓ Coirtx has been completely removed.${RESET}"
    exit 0
else
    echo -e "${RED}✗ Some Coirtx components still remain.${RESET}"
    exit 1
fi
