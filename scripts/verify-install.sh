#!/usr/bin/env bash

set -u

###############################################################################
# Configuration
###############################################################################

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

SERVICES=(
    "${APP_NAME}-server.service"
    "${APP_NAME}-agent2.service"
)

###############################################################################

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

PASS=0
FAIL=0
WARN=0

pass() {
    echo -e "${GREEN}[PASS]${RESET} $1"
    ((PASS++))
}

fail() {
    echo -e "${RED}[FAIL]${RESET} $1"
    ((FAIL++))
}

warn() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
    ((WARN++))
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

for dir in \
    "$PREFIX" \
    "$SYSCONFDIR" \
    "$LOGDIR" \
    "$LIBDIR" \
    "$RUNDIR"
do
    [[ -d "$dir" ]] && pass "$dir exists" || fail "$dir missing"
done

###############################################################################
section "Executables"

declare -A BINS=(
    [zabbix_server]="$PREFIX/sbin/zabbix_server"
    [zabbix_agent2]="$PREFIX/sbin/zabbix_agent2"
    [zabbix_web_service]="$PREFIX/sbin/zabbix_web_service"
    [zabbix_get]="$PREFIX/bin/zabbix_get"
    [zabbix_sender]="$PREFIX/bin/zabbix_sender"
)

for name in "${!BINS[@]}"; do
    [[ -x "${BINS[$name]}" ]] \
        && pass "$name found" \
        || fail "$name missing"
done

###############################################################################
section "Web UI"

[[ -d "$PREFIX/ui" ]] \
    && pass "UI installed" \
    || fail "UI missing"

for file in \
    index.php \
    local/conf/brand.conf.php
do
    [[ -f "$PREFIX/ui/$file" ]] \
        && pass "$file found" \
        || fail "$file missing"
done

###############################################################################
section "Systemd"

for service in "${SERVICES[@]}"; do

    if systemctl list-unit-files | grep -q "^${service}"; then
        pass "$service installed"
    else
        fail "$service missing"
    fi

done

###############################################################################
section "Service Status"

for service in "${SERVICES[@]}"; do

    if systemctl is-active --quiet "$service"; then
        pass "$service running"
    else
        fail "$service not running"
    fi

done

###############################################################################
section "Processes"

for proc in \
    zabbix_server \
    zabbix_agent2
do
    if pgrep -f "$proc" >/dev/null; then
        pass "$proc running"
    else
        fail "$proc not running"
    fi
done

#
# Web Service
#
if [[ -x "$PREFIX/sbin/zabbix_web_service" ]]; then

    if pgrep -f zabbix_web_service >/dev/null; then
        pass "zabbix_web_service running"
    else
        warn "zabbix_web_service installed but not running"
    fi

fi

###############################################################################
section "Database"

if sudo -u postgres psql -tAc \
"SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" \
| grep -q 1
then
    pass "Database exists"
else
    fail "Database missing"
fi

if sudo -u postgres psql -tAc \
"SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" \
| grep -q 1
then
    pass "Role exists"
else
    fail "Role missing"
fi

###############################################################################
section "Linux User"

id "$SERVICE_USER" >/dev/null 2>&1 \
    && pass "User exists" \
    || fail "User missing"

getent group "$SERVICE_GROUP" >/dev/null \
    && pass "Group exists" \
    || fail "Group missing"

###############################################################################
section "Nginx"

if sudo nginx -t >/dev/null 2>&1; then
    pass "Configuration OK"
else
    fail "Configuration invalid"
fi

###############################################################################
section "Listening Ports"

if ss -ltn | grep -q ":10051 "; then
    pass "Server listening on 10051"
else
    fail "Server not listening on 10051"
fi

if ss -ltn | grep -q ":10050 "; then
    pass "Agent2 listening on 10050"
else
    fail "Agent2 not listening on 10050"
fi

###############################################################################
section "Log Files"

for log in \
    "$LOGDIR/zabbix_server.log" \
    "$LOGDIR/zabbix_agent2.log"
do
    [[ -f "$log" ]] \
        && pass "$(basename "$log") exists" \
        || fail "$(basename "$log") missing"
done

###############################################################################

echo
echo "==============================================="
echo "Verification Summary"
echo "==============================================="

echo
echo -e "Passed : ${GREEN}${PASS}${RESET}"
echo -e "Warnings : ${YELLOW}${WARN}${RESET}"
echo -e "Failed : ${RED}${FAIL}${RESET}"

echo

if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}Coirtx installation verified successfully.${RESET}"
    exit 0
else
    echo -e "${RED}Some verification checks failed.${RESET}"
    exit 1
fi
