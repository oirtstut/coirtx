#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# KTRIX INSTALLER
#
# Builds and installs Ktrix from source on Ubuntu.
#
# Assumptions:
#   - Run from the Ktrix source root.
#   - PostgreSQL and nginx are already installed.
#
###############################################################################

APP_NAME="ktrix"

PREFIX="/opt/${APP_NAME}"
SYSCONFDIR="/etc/${APP_NAME}"

WEBROOT="${PREFIX}/ui"

DB_NAME="${APP_NAME}"
DB_USER="${APP_NAME}"
DB_PASSWORD="change_me"

SERVICE_USER="${APP_NAME}"
SERVICE_GROUP="${APP_NAME}"

PHP_VERSION="8.5"
TIMEZONE="Asia/Kolkata"

###############################################################################

echo "==========================================="
echo "Installing ${APP_NAME}"
echo "==========================================="

###############################################################################
echo
echo "Creating Linux user..."

if ! id "${SERVICE_USER}" >/dev/null 2>&1; then
    sudo groupadd --system "${SERVICE_GROUP}"

    sudo useradd \
        --system \
        --gid "${SERVICE_GROUP}" \
        --home-dir "/var/lib/${APP_NAME}" \
        --create-home \
        --shell /usr/sbin/nologin \
        "${SERVICE_USER}"
fi

###############################################################################
echo
echo "Creating directories..."

sudo mkdir -p "${PREFIX}"
sudo mkdir -p "${SYSCONFDIR}"

sudo mkdir -p "/var/log/${APP_NAME}"
sudo mkdir -p "/var/lib/${APP_NAME}"
sudo mkdir -p "/run/${APP_NAME}"

sudo chown -R "${SERVICE_USER}:${SERVICE_GROUP}" \
    "/var/log/${APP_NAME}" \
    "/var/lib/${APP_NAME}" \
    "/run/${APP_NAME}"

###############################################################################

echo
echo "Installing pre-requisites"


###############################################################################
echo
echo "Creating PostgreSQL database..."

sudo -u postgres psql <<EOF

DO \$\$
BEGIN
    IF NOT EXISTS (
        SELECT
        FROM pg_roles
        WHERE rolname='${DB_USER}'
    ) THEN
        CREATE ROLE ${DB_USER}
        LOGIN
        PASSWORD '${DB_PASSWORD}';
    END IF;
END
\$\$;

SELECT 'CREATE DATABASE ${DB_NAME}'
WHERE NOT EXISTS (
    SELECT
    FROM pg_database
    WHERE datname='${DB_NAME}'
)\gexec

ALTER DATABASE ${DB_NAME}
OWNER TO ${DB_USER};

EOF

###############################################################################
echo
echo "Bootstrapping..."

./bootstrap.sh

###############################################################################
echo
echo "Configuring..."

./configure \
    --prefix="${PREFIX}" \
    --sysconfdir="${SYSCONFDIR}" \
    --localstatedir=/var \
    --enable-server \
    --enable-proxy \
    --enable-agent \
    --enable-agent2 \
    --enable-webservice \
    --with-postgresql \
    --with-net-snmp \
    --with-libcurl \
    --with-openipmi \
    --with-libxml2 \
    --with-ssh2 \
    --with-openssl

###############################################################################
echo
echo "Building..."

make -j"$(nproc)"

###############################################################################
echo
echo "Generating database schema..."

make dbschema

###############################################################################
echo
echo "Importing database..."

cat \
    database/postgresql/schema.sql \
    database/postgresql/images.sql \
    database/postgresql/data.sql \
| PGPASSWORD="${DB_PASSWORD}" \
    psql \
        -h localhost \
        -U "${DB_USER}" \
        -d "${DB_NAME}"

###############################################################################
echo
echo "Installing..."

sudo make install

###############################################################################
echo
echo "Installing frontend..."

sudo mkdir -p "${WEBROOT}"

sudo cp -a ui/. "${WEBROOT}/"

###############################################################################
echo
echo "Writing server configuration..."

sudo tee "${SYSCONFDIR}/zabbix_server.conf" >/dev/null <<EOF
LogFile=/var/log/${APP_NAME}/server.log

PidFile=/run/${APP_NAME}/server.pid

DBHost=localhost
DBPort=5432

DBName=${DB_NAME}
DBUser=${DB_USER}
DBPassword=${DB_PASSWORD}

User=${SERVICE_USER}
EOF

###############################################################################
echo
echo "Fixing permissions..."

sudo chown -R root:root "${PREFIX}"

sudo chown -R "${SERVICE_USER}:${SERVICE_GROUP}" \
    "/var/log/${APP_NAME}" \
    "/var/lib/${APP_NAME}" \
    "/run/${APP_NAME}"

###############################################################################
echo
echo "Done."

echo
echo "Next steps:"
echo
echo "1. Configure nginx:"
echo
echo "       root ${WEBROOT}"
echo
echo "2. Configure PHP timezone:"
echo
echo "       ${TIMEZONE}"
echo
echo "3. Start:"
echo
echo "       sudo ${PREFIX}/sbin/zabbix_server -c ${SYSCONFDIR}/zabbix_server.conf -f"
echo
