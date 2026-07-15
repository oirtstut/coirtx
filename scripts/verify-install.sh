#!/usr/bin/env bash

set -u

APP_NAME="coirtx"

PREFIX="/opt/${APP_NAME}"
SYSCONFDIR="/etc/${APP_NAME}"

LOGDIR="/var/log/${APP_NAME}"
LIBDIR="/var/lib/${APP_NAME}"
RUNDIR="/run/${APP_NAME}"

DB_NAME="${APP_NAME}"
DB_USER="${APP_NAME}"

SERVICE_USER="${APP_NAME}"
SERVICE_GROUP="${APP_NAME}"

SYSTEMD_SERVICE="${APP_NAME}-server.service"

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
echo "        COIRTX INSTALLATION VERIFIER"
echo "==============================================="

###############################################################################
section "Installation"

[[ -d "$PREFIX" ]] \
    && pass "$PREFIX exists" \
    || fail "$PREFIX missing"

[[ -d "$SYSCONFDIR" ]] \
    && pass "$SYSCONFDIR exists" \
    || fail "$SYSCONFDIR missing"

###############################################################################
section "Executables"

for exe in \
    zabbix_server \
    zabbix_proxy \
    zabbix_agentd \
    zabbix_agent2 \
    zabbix_web_service
do
    if [[ -x "$PREFIX/sbin/$exe" ]]; then
        pass "$exe found"
    else
        fail "$exe missing"
    fi
done

###############################################################################
section "Web UI"

[[ -d "$PREFIX/ui" ]] \
    && pass "UI installed" \
    || fail "UI missing"

[[ -f "$PREFIX/ui/index.php" ]] \
    && pass "index.php found" \
    || fail "index.php missing"

[[ -f "$PREFIX/ui/local/conf/brand.conf.php" ]] \
    && pass "brand.conf.php found" \
    || fail "brand.conf.php missing"

###############################################################################
section "Runtime"

[[ -d "$LOGDIR" ]] \
    && pass "$LOGDIR exists" \
    || fail "$LOGDIR missing"

[[ -d "$LIBDIR" ]] \
    && pass "$LIBDIR exists" \
    || fail "$LIBDIR missing"

###############################################################################
section "Systemd"

if systemctl list-unit-files | grep -q "^${SYSTEMD_SERVICE}"; then
    pass "systemd service installed"
else
    fail "systemd service missing"
fi

###############################################################################
section "Processes"

for proc in \
    zabbix_server \
    zabbix_proxy \
    zabbix_agentd \
    zabbix_agent2 \
    zabbix_web_service
do
    if pgrep -x "$proc" >/dev/null; then
        pass "$proc running"
    else
        echo -e "${YELLOW}[WARN]${RESET} $proc not running"
    fi
done

###############################################################################
section "Database"

if sudo -u postgres psql -tAc \
"SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1
then
    pass "Database exists"
else
    fail "Database missing"
fi

if sudo -u postgres psql -tAc \
"SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | grep -q 1
then
    pass "Role exists"
else
    fail "Role missing"
fi

###############################################################################
section "Linux User"

id "$SERVICE_USER" >/dev/null 2>&1 \
    && pass "Linux user exists" \
    || fail "Linux user missing"

getent group "$SERVICE_GROUP" >/dev/null \
    && pass "Linux group exists" \
    || fail "Linux group missing"

###############################################################################
section "Nginx"

if sudo nginx -t >/dev/null 2>&1; then
    pass "nginx configuration OK"
else
    fail "nginx configuration invalid"
fi

###############################################################################
section "Listening Ports"

sudo ss -ltnp | grep zabbix || \
echo -e "${YELLOW}[WARN]${RESET} No Zabbix services listening"

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
    echo -e "${GREEN}Installation looks good.${RESET}"
    exit 0
else
    echo -e "${RED}Some checks failed.${RESET}"
    exit 1
fi
