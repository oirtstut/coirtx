# BUILD.md

## Building COIRTX from Source

This document describes how to build COIRTX from source on a supported Linux distribution.

## Supported Build Environment

The reference development environment is:

* Ubuntu Server 26.04 LTS
* PostgreSQL
* Nginx
* PHP (distribution version)
* GCC (distribution version)
* Go (distribution version)

Other Linux distributions may work but are not officially verified.

---

## Git Clone

```
git clone git@github.com:oirtstut/coirtx.git
git checkout branding/coirtx


```
---

## Build Dependencies

### Core Build Tools

```bash
sudo apt update

sudo apt install -y \
    git \
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    flex \
    bison \
    gcc \
    g++ \
    make
```

### Development Libraries

```bash
sudo apt install -y \
    libpcre2-dev \
    libevent-dev \
    libssl-dev \
    libldap2-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libsnmp-dev \
    libopenipmi-dev \
    libssh2-1-dev \
    libpq-dev \
    zlib1g-dev \
    libsqlite3-dev
```

### Go Compiler

Agent2 requires Go.

```bash
sudo apt install golang-go
```

Verify:

```bash
go version
```

Install PostgreSQL, PHP and Nginx
```
sudo apt update

sudo apt install -y \
    postgresql \
    postgresql-contrib \
    nginx \
    php-fpm \
    php-cli \
    php-pgsql \
    php-gd \
    php-bcmath \
    php-mbstring \
    php-xml \
    php-ldap \
    php-curl \
    php-zip \
    php-intl
```

---

## Bootstrap

```bash
./bootstrap.sh
```

---

## Configure

Reference configure command:

```bash
./configure \
    --prefix=/opt/coirtx \
    --sysconfdir=/etc/coirtx \
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
```

---

## Build

```bash
make -j$(nproc)
```

---

## Install

```bash
sudo make install
```
---

# Configure PHP

Set the correct timezone in both CLI and FPM.

Example:

```bash
sudo vi /etc/php/8.5/fpm/php.ini
sudo vi /etc/php/8.5/cli/php.ini
```

Set:

```ini
; Maximum execution time of each script, in seconds
max_execution_time = 300

; Maximum amount of time each script may spend parsing input data
max_input_time = 300

; Maximum amount of memory a script may consume
memory_limit = 256M

; Maximum size of POST data
post_max_size = 16M

; Maximum allowed size for uploaded files
upload_max_filesize = 2M

; Maximum number of input variables
max_input_vars = 10000

; Timezone
date.timezone = Asia/Kolkata
```

Restart PHP-FPM:

```bash
sudo systemctl restart php8.5-fpm
```

---

# Create the PostgreSQL Database

Create the application user and database.

```bash
sudo -u postgres psql
```

```sql
CREATE USER coirtx WITH PASSWORD 'change_me';
CREATE DATABASE coirtx OWNER coirtx ENCODING 'UTF8';
GRANT ALL PRIVILEGES ON DATABASE coirtx TO coirtx;

\q
```

modifying zabbix_server.conf file
```
/etc/coirtx/zabbix_server.conf

DBHost=localhost
DBName=coirtx
DBUser=coirtx
DBPassword=change_me

```

---

# Initialize the Database

Import the generated database schema.

```bash
cat database/postgresql/schema.sql \
    database/postgresql/images.sql \
    database/postgresql/data.sql \
| PGPASSWORD=change_me \
    psql \
        -h localhost \
        -U coirtx \
        -d coirtx
```

---

# Configure the Server

Edit:

```text
/etc/coirtx/zabbix_server.conf
```

Configure the database connection:

```ini
DBHost=localhost
DBName=coirtx
DBUser=coirtx
DBPassword=change_me
```

---

# Create the Runtime User

The source build does not create the runtime account automatically.

```bash
sudo groupadd --system zabbix

sudo useradd \
    --system \
    --gid zabbix \
    --home /var/lib/zabbix \
    --shell /usr/sbin/nologin \
    --create-home \
    zabbix
```

---

# Verify the Installation

Check the installed server binary.

```bash
/opt/coirtx/sbin/zabbix_server --version
```

Example:

```
zabbix_server (Zabbix) 8.0.0rc1
```

---

# Start the Server

Run the server in the foreground.

```bash
sudo /opt/coirtx/sbin/zabbix_server \
    -c /etc/coirtx/zabbix_server.conf \
    -f
```

Expected output:

```
Starting Zabbix Server...
Press Ctrl+C to exit.
```

If the server starts successfully, the backend installation is complete.

---

# Frontend (Current Status)

At present, the upstream build system does **not** install the PHP frontend.

During development, the frontend can be served directly from the source tree or by creating a symbolic link.

Example:

```bash
sudo ln -s ~/wspace/coirtx/ui /opt/coirtx/ui
```

A future COIRTX release should install the frontend automatically under:

```
/opt/coirtx/ui
```

during `make install`.

---

# Nginx

Install:

```bash
sudo apt install nginx
```

The frontend should use PHP-FPM.

Typical socket:

```
/run/php/php8.5-fpm.sock
```

---

# Current Limitations

The project currently follows the upstream Zabbix installation layout.

Future COIRTX releases will:

- install the frontend automatically
- install SQL files automatically
- provide native systemd service files
- replace remaining upstream branding
- provide distribution packages

---

## Notes

* COIRTX currently follows the upstream Zabbix build system.
* Agent2 requires the Go compiler.
* PostgreSQL is the recommended database backend.
* Nginx is the recommended web server.
* This document should be updated whenever build dependencies or configure options change.


---

## Set up PostgresQL database

```
sudo -u postgres psql
psql (18.4 (Ubuntu 18.4-0ubuntu0.26.04.1))
Type "help" for help.

postgres=# CREATE USER coirtx WITH PASSWORD 'change_me';
CREATE DATABASE coirtx OWNER coirtx;
\q
CREATE ROLE
CREATE DATABASE
```

## Modify conf file

```
find /etc/coirtx -name "*.conf"

sudo vi /etc/coirtx/zabbix_server.conf

DBHost=localhost
DBName=coirtx
DBUser=coirtx
DBPassword=change_me
```


