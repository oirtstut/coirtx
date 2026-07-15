#!/usr/bin/env bash

###############################################################################
#
# KTRIX / COIRTX POST INSTALL SCRIPT
#
# Run AFTER:
#
# ./configure \
#     --prefix=/opt/coirtx \
#     --sysconfdir=/etc/coirtx \
#     --localstatedir=/var \
#     --enable-server \
#     --enable-agent2 \
#     --enable-webservice \
#     --with-postgresql \
#     --with-net-snmp \
#     --with-libcurl \
#     --with-openipmi \
#     --with-libxml2 \
#     --with-ssh2 \
#     --with-openssl

#     make -j$(nproc)
#     sudo make install
#
#     make dbschema
#
###############################################################################

set -Eeuo pipefail

###############################################################################
# CONFIGURATION
###############################################################################

#
# Product
#
APP_NAME="coirtx"

#
# Installation
#
PREFIX="/opt/${APP_NAME}"
SYSCONFDIR="/etc/${APP_NAME}"
WEBROOT="${PREFIX}/ui"

#
# Runtime
#
LOGDIR="/var/log/${APP_NAME}"
LIBDIR="/var/lib/${APP_NAME}"
RUNDIR="/run/${APP_NAME}"

#
# Linux service account
#
SERVICE_USER="${APP_NAME}"
SERVICE_GROUP="${APP_NAME}"

#
# Database
#
DB_HOST="localhost"
DB_PORT="5432"

DB_NAME="${APP_NAME}"
DB_USER="${APP_NAME}"
DB_PASSWORD="change_me"

#
# Web
#
NGINX_SITE="${APP_NAME}"

#
# PHP
#
PHP_VERSION="8.5"
PHP_FPM_SERVICE="php${PHP_VERSION}-fpm"

PHP_INI="/etc/php/${PHP_VERSION}/fpm/php.ini"

TIMEZONE="Asia/Kolkata"

#
# Source tree
#
#
# This assumes the script lives in:
#
#     scripts/post-install.sh
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SOURCE_ROOT="$(realpath "${SCRIPT_DIR}/..")"

UI_SOURCE="${SOURCE_ROOT}/ui"

###############################################################################
# COLORS
###############################################################################

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

###############################################################################
# HELPERS
###############################################################################

info() {
    echo -e "${BLUE}==>${NC} $*"
}

success() {
    echo -e "${GREEN}✓${NC} $*"
}

warning() {
    echo -e "${YELLOW}!${NC} $*"
}

error() {
    echo -e "${RED}✗${NC} $*"
}

###############################################################################
# ROOT CHECK
###############################################################################

if [[ $EUID -ne 0 ]]; then
    error "Please run using sudo."

    echo
    echo "Example:"
    echo

    echo "    sudo ./scripts/post-install.sh"
    echo

    exit 1
fi

###############################################################################
# HEADER
###############################################################################

echo
echo "=========================================================="
echo "            ${APP_NAME^^} POST INSTALL"
echo "=========================================================="
echo

info "Installation prefix : ${PREFIX}"
info "Configuration       : ${SYSCONFDIR}"
info "Web frontend        : ${WEBROOT}"
info "Database            : ${DB_NAME}"
info "Service user        : ${SERVICE_USER}"
echo


###############################################################################
# PREREQUISITE CHECKS
###############################################################################

info "Checking prerequisites..."

#
# Required commands
#
REQUIRED_COMMANDS=(
    psql
    nginx
    systemctl
    php
    sed
    grep
    install
)

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        error "Required command '${cmd}' not found."
        exit 1
    fi
done

success "Required commands found."

###############################################################################

#
# Verify installation exists
#
SERVER_BIN="${PREFIX}/sbin/zabbix_server"

if [[ ! -x "${SERVER_BIN}" ]]; then
    error "Ktrix/Coirtx does not appear to be installed."

    echo
    echo "Expected:"
    echo "    ${SERVER_BIN}"
    echo
    echo "Did you run:"
    echo
    echo "    make -j\$(nproc)"
    echo "    sudo make install"
    echo

    exit 1
fi

success "Installed binaries found."

###############################################################################

#
# Verify frontend source exists
#
if [[ ! -d "${UI_SOURCE}" ]]; then
    error "Frontend source directory not found."

    echo
    echo "Expected:"
    echo "    ${UI_SOURCE}"
    echo

    exit 1
fi

if [[ ! -f "${UI_SOURCE}/index.php" ]]; then
    error "Frontend appears incomplete."

    exit 1
fi

success "Frontend source found."

###############################################################################

#
# Verify generated SQL files exist
#
POSTGRES_DIR="${SOURCE_ROOT}/database/postgresql"

SQL_FILES=(
    schema.sql
    images.sql
    data.sql
)

for file in "${SQL_FILES[@]}"; do

    if [[ ! -f "${POSTGRES_DIR}/${file}" ]]; then

        error "Missing database file:"

        echo
        echo "    ${POSTGRES_DIR}/${file}"
        echo
        echo "Run:"
        echo
        echo "    make dbschema"
        echo

        exit 1
    fi

done

success "Database schema found."

###############################################################################

#
# Verify PHP configuration
#
if [[ ! -f "${PHP_INI}" ]]; then

    error "php.ini not found."

    echo
    echo "Expected:"
    echo "    ${PHP_INI}"
    echo

    exit 1

fi

success "PHP configuration found."

###############################################################################

#
# Verify nginx configuration directory
#
if [[ ! -d "/etc/nginx/sites-available" ]]; then

    error "Nginx does not appear to be installed."

    exit 1

fi

success "Nginx installation found."

###############################################################################

#
# Verify PostgreSQL server is running
#
if ! systemctl is-active --quiet postgresql; then

    error "PostgreSQL is not running."

    echo
    echo "Start it with:"
    echo
    echo "    sudo systemctl start postgresql"
    echo

    exit 1

fi

success "PostgreSQL is running."

###############################################################################

#
# Verify PHP-FPM
#
if ! systemctl is-active --quiet "${PHP_FPM_SERVICE}"; then

    warning "${PHP_FPM_SERVICE} is not running."

else

    success "PHP-FPM is running."

fi

###############################################################################

#
# Verify nginx
#
if ! systemctl is-active --quiet nginx; then

    warning "Nginx is not running."

else

    success "Nginx is running."

fi

###############################################################################

echo
success "All prerequisite checks passed."
echo


###############################################################################
# CREATE SERVICE USER
###############################################################################

info "Creating service account..."

#
# Group
#
if getent group "${SERVICE_GROUP}" >/dev/null 2>&1; then

    success "Group '${SERVICE_GROUP}' already exists."

else

    groupadd --system "${SERVICE_GROUP}"

    success "Created group '${SERVICE_GROUP}'."

fi

#
# User
#
if id "${SERVICE_USER}" >/dev/null 2>&1; then

    success "User '${SERVICE_USER}' already exists."

else

    useradd \
        --system \
        --gid "${SERVICE_GROUP}" \
        --home-dir "${LIBDIR}" \
        --create-home \
        --shell /usr/sbin/nologin \
        --comment "Coirtx Service Account" \
        "${SERVICE_USER}"

    success "Created user '${SERVICE_USER}'."

fi

###############################################################################
# CREATE DIRECTORIES
###############################################################################

info "Creating directories..."

DIRECTORIES=(
    "${PREFIX}"
    "${SYSCONFDIR}"
    "${WEBROOT}"
    "${LOGDIR}"
    "${LIBDIR}"
    "${RUNDIR}"
)

for dir in "${DIRECTORIES[@]}"; do

    mkdir -p "${dir}"

    success "Ensured ${dir}"

done

###############################################################################
# DIRECTORY PERMISSIONS
###############################################################################

info "Setting ownership..."

#
# Installation directory
#
chown -R root:root "${PREFIX}"

#
# Runtime directories
#
chown -R "${SERVICE_USER}:${SERVICE_GROUP}" \
    "${LOGDIR}" \
    "${LIBDIR}" \
    "${RUNDIR}"

#
# Permissions
#
chmod 755 "${PREFIX}"
chmod 755 "${WEBROOT}"
chmod 755 "${LOGDIR}"
chmod 755 "${LIBDIR}"
chmod 755 "${RUNDIR}"

success "Ownership configured."

###############################################################################
# VERIFY INSTALLATION
###############################################################################

info "Checking installed binaries..."

BINARIES=(
    "${PREFIX}/sbin/zabbix_server"
    "${PREFIX}/sbin/zabbix_proxy"
    "${PREFIX}/sbin/zabbix_agentd"
    "${PREFIX}/bin/zabbix_get"
    "${PREFIX}/bin/zabbix_sender"
)

for bin in "${BINARIES[@]}"; do

    if [[ -x "${bin}" ]]; then
        success "$(basename "${bin}")"
    fi

done

echo


###############################################################################
# POSTGRESQL SETUP
###############################################################################

info "Configuring PostgreSQL..."

#
# Create role if it does not exist
#
ROLE_EXISTS=$(
    sudo -u postgres psql -tAc \
    "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'"
)

if [[ "${ROLE_EXISTS}" != "1" ]]; then

    info "Creating PostgreSQL role '${DB_USER}'..."

    sudo -u postgres psql <<EOF
CREATE ROLE ${DB_USER}
LOGIN
PASSWORD '${DB_PASSWORD}';
EOF

    success "Role created."

else

    success "Role '${DB_USER}' already exists."

fi

###############################################################################

#
# Create database if it does not exist
#
DB_EXISTS=$(
    sudo -u postgres psql -tAc \
    "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'"
)

if [[ "${DB_EXISTS}" != "1" ]]; then

    info "Creating database '${DB_NAME}'..."

    sudo -u postgres createdb \
        --owner="${DB_USER}" \
        "${DB_NAME}"

    success "Database created."

else

    success "Database '${DB_NAME}' already exists."

fi

###############################################################################

#
# Ensure ownership
#
sudo -u postgres psql <<EOF
ALTER DATABASE ${DB_NAME}
OWNER TO ${DB_USER};
EOF

success "Database ownership verified."

###############################################################################

#
# Check whether schema already exists
#
TABLE_EXISTS=$(
    PGPASSWORD="${DB_PASSWORD}" \
    psql \
        -h "${DB_HOST}" \
        -p "${DB_PORT}" \
        -U "${DB_USER}" \
        -d "${DB_NAME}" \
        -tAc \
        "SELECT 1
         FROM information_schema.tables
         WHERE table_name='users';"
)

###############################################################################

if [[ "${TABLE_EXISTS}" == "1" ]]; then

    success "Database schema already installed."

else

    info "Importing initial database..."

    cat \
        "${POSTGRES_DIR}/schema.sql" \
        "${POSTGRES_DIR}/images.sql" \
        "${POSTGRES_DIR}/data.sql" \
    | PGPASSWORD="${DB_PASSWORD}" \
      psql \
            -h "${DB_HOST}" \
            -p "${DB_PORT}" \
            -U "${DB_USER}" \
            -d "${DB_NAME}"

    success "Database imported."

fi

echo


###############################################################################
# FRONTEND DEPLOYMENT
###############################################################################

info "Deploying frontend..."

#
# Remove previous frontend
#
if [[ -d "${WEBROOT}" ]]; then

    info "Removing existing frontend..."

    rm -rf "${WEBROOT}"

fi

###############################################################################

#
# Create destination
#
mkdir -p "${WEBROOT}"

###############################################################################

#
# Copy frontend
#
cp -a "${UI_SOURCE}/." "${WEBROOT}/"

success "Frontend copied."

###############################################################################

#
# Ownership
#
chown -R root:root "${WEBROOT}"

###############################################################################

#
# Directories
#
find "${WEBROOT}" \
    -type d \
    -exec chmod 755 {} \;

###############################################################################

#
# Files
#
find "${WEBROOT}" \
    -type f \
    -exec chmod 644 {} \;

###############################################################################

#
# Executable scripts (if any)
#
find "${WEBROOT}" \
    -type f \
    -name "*.sh" \
    -exec chmod 755 {} \;

###############################################################################

#
# Writable directories
#
#
# Zabbix/Coirtx normally only needs the assets directory
# writable during upgrades if you choose to do so.
#
mkdir -p "${WEBROOT}/assets"

###############################################################################

#
# Verify installation
#
if [[ ! -f "${WEBROOT}/index.php" ]]; then

    error "Frontend deployment failed."

    exit 1

fi

success "index.php found."

###############################################################################

#
# Show frontend version
#
VERSION=$(grep -m1 "Copyright" \
    "${WEBROOT}/index.php" || true)

if [[ -n "${VERSION}" ]]; then
    info "Frontend deployed successfully."
fi

###############################################################################

echo


###############################################################################
# SERVER CONFIGURATION
###############################################################################

info "Configuring server..."

SERVER_CONF="${SYSCONFDIR}/zabbix_server.conf"

###############################################################################
#
# Create configuration only if it does not already exist
#
if [[ ! -f "${SERVER_CONF}" ]]; then

    info "Creating ${SERVER_CONF}..."

cat > "${SERVER_CONF}" <<EOF
##############################################################################
#
# Coirtx Server Configuration
#
##############################################################################

############ GENERAL ##########################################################

LogFile=${LOGDIR}/zabbix_server.log

LogFileSize=10

PidFile=${RUNDIR}/zabbix_server.pid

User=${SERVICE_USER}

############ DATABASE #########################################################

DBHost=${DB_HOST}

DBPort=${DB_PORT}

DBName=${DB_NAME}

DBUser=${DB_USER}

DBPassword=${DB_PASSWORD}

############ CACHE ############################################################

CacheSize=128M

HistoryCacheSize=32M

HistoryIndexCacheSize=16M

TrendCacheSize=32M

ValueCacheSize=64M

############ POLLERS ##########################################################

StartPollers=10

StartPingers=5

StartDiscoverers=5

StartHTTPPollers=5

############ HOUSEKEEPING #####################################################

HousekeepingFrequency=1

MaxHousekeeperDelete=5000

############ TIMEOUT ##########################################################

Timeout=4

############ LOGGING ##########################################################

DebugLevel=3

EOF

    success "Configuration created."

else

    success "Configuration already exists."

fi

echo


###############################################################################
# PHP CONFIGURATION
###############################################################################

info "Configuring PHP..."

###############################################################################

set_php_value() {

    local key="$1"
    local value="$2"

    if grep -q "^${key}[[:space:]]*=" "${PHP_INI}"; then

        sed -Ei \
            "s|^${key}[[:space:]]*=.*|${key} = ${value}|" \
            "${PHP_INI}"

    else

        echo "${key} = ${value}" >> "${PHP_INI}"

    fi
}

###############################################################################

set_php_value "max_execution_time" "300"

set_php_value "memory_limit" "256M"

set_php_value "post_max_size" "32M"

set_php_value "upload_max_filesize" "16M"

set_php_value "max_input_time" "300"

set_php_value "date.timezone" "${TIMEZONE}"

###############################################################################

success "PHP configuration updated."

echo


###############################################################################
# RESTART PHP-FPM
###############################################################################

info "Restarting PHP-FPM..."

systemctl restart "${PHP_FPM_SERVICE}"

success "PHP-FPM restarted."

echo


###############################################################################
# VERIFY PHP
###############################################################################

info "Checking PHP..."

php -v

success "PHP is working."

echo


###############################################################################
# NGINX CONFIGURATION
###############################################################################

info "Configuring Nginx..."

NGINX_CONF="/etc/nginx/sites-available/${NGINX_SITE}"

###############################################################################
# Detect PHP-FPM socket
###############################################################################

PHP_FPM_SOCKET="/run/php/php${PHP_VERSION}-fpm.sock"

if [[ ! -S "${PHP_FPM_SOCKET}" ]]; then

    error "PHP-FPM socket not found."

    echo
    echo "Expected:"
    echo "    ${PHP_FPM_SOCKET}"
    echo

    exit 1

fi

success "PHP-FPM socket found."

###############################################################################
# Create nginx site configuration
###############################################################################

cat > "${NGINX_CONF}" <<EOF
server {

    listen 80;

    server_name _;

    root ${WEBROOT};

    index index.php;

    access_log /var/log/nginx/${APP_NAME}.access.log;
    error_log  /var/log/nginx/${APP_NAME}.error.log;

    client_max_body_size 32M;

    location / {

        try_files \$uri \$uri/ /index.php?\$query_string;

    }

    location ~ \.php\$ {

        include snippets/fastcgi-php.conf;

        fastcgi_pass unix:${PHP_FPM_SOCKET};

        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;

        include fastcgi_params;

    }

    location ~ /\. {

        deny all;

    }

}
EOF

success "Nginx site created."

###############################################################################
# Enable site
###############################################################################

ln -sf \
    "${NGINX_CONF}" \
    "/etc/nginx/sites-enabled/${NGINX_SITE}"

success "Site enabled."

###############################################################################
# Disable default site
###############################################################################

if [[ -e /etc/nginx/sites-enabled/default ]]; then

    rm -f /etc/nginx/sites-enabled/default

    success "Default site removed."

fi

###############################################################################
# Test configuration
###############################################################################

info "Testing Nginx configuration..."

nginx -t

success "Nginx configuration is valid."

###############################################################################
# Reload Nginx
###############################################################################

systemctl reload nginx

success "Nginx reloaded."

echo


###############################################################################
# SYSTEMD SERVICE
###############################################################################

info "Installing systemd service..."

SERVICE_FILE="/etc/systemd/system/${APP_NAME}-server.service"

###############################################################################

cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=Coirtx Server
Documentation=https://github.com/<your-org>/coirtx

After=network-online.target postgresql.service
Wants=network-online.target

[Service]
Type=simple

User=${SERVICE_USER}
Group=${SERVICE_GROUP}

ExecStart=${PREFIX}/sbin/zabbix_server \
    -c ${SYSCONFDIR}/zabbix_server.conf

ExecReload=/bin/kill -HUP \$MAINPID

Restart=on-failure
RestartSec=5

PIDFile=${RUNDIR}/zabbix_server.pid

LimitNOFILE=65535

NoNewPrivileges=true

PrivateTmp=true

ProtectSystem=full

ProtectHome=true

WorkingDirectory=${LIBDIR}

[Install]
WantedBy=multi-user.target
EOF

success "systemd service created."

echo


###############################################################################
# RELOAD SYSTEMD
###############################################################################

info "Reloading systemd..."

systemctl daemon-reload

success "systemd reloaded."

echo


###############################################################################
# ENABLE SERVICE
###############################################################################

info "Enabling service..."

systemctl enable "${APP_NAME}-server.service"

success "Service enabled."

echo


###############################################################################
# START SERVICE
###############################################################################

info "Starting server..."

systemctl restart "${APP_NAME}-server.service"

success "Service started."

echo


###############################################################################
# VERIFY
###############################################################################

sleep 2

if systemctl is-active --quiet "${APP_NAME}-server.service"; then

    success "Server is running."

else

    error "Server failed to start."

    echo
    journalctl -u "${APP_NAME}-server.service" -n 50 --no-pager
    echo

    exit 1

fi

echo


###############################################################################
# INSTALLATION SUMMARY
###############################################################################

IP_ADDRESS=$(
hostname -I \
| awk '{print $1}'
)

echo
echo "============================================================"
echo
success "Installation completed successfully."
echo
echo "------------------------------------------------------------"
echo
echo "Frontend"
echo "--------"
echo
echo "    http://${IP_ADDRESS}/"
echo
echo "Configuration"
echo "-------------"
echo
echo "    ${SYSCONFDIR}/zabbix_server.conf"
echo
echo "Database"
echo "--------"
echo
echo "    Host : ${DB_HOST}"
echo "    Name : ${DB_NAME}"
echo "    User : ${DB_USER}"
echo
echo "Service"
echo "-------"
echo
echo "    systemctl status ${APP_NAME}-server"
echo
echo "Logs"
echo "----"
echo
echo "    ${LOGDIR}"
echo
echo "============================================================"
echo
