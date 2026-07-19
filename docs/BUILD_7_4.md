# Zabbix 7.4 (Git) Installation Guide
**Ubuntu 26.04 LTS + PostgreSQL + Nginx + PHP-FPM**

> This guide documents a clean installation of Zabbix built **from the Git repository**, not from a release tarball or distribution package.
>
> It serves as the reference installation for future Coirtx development.

---

# 1. Update the System

```bash
sudo apt update
sudo apt upgrade -y
sudo reboot
```

---

# 2. Install Build Tools

```bash
sudo apt install -y \
    git \
    gcc \
    g++ \
    make \
    cmake \
    pkg-config \
    autoconf \
    automake \
    libtool \
    bison \
    flex
```

---

# 3. Install Build Dependencies

## PostgreSQL

```bash
sudo apt install -y \
    postgresql \
    postgresql-contrib \
    libpq-dev
```

---

## SNMP

```bash
sudo apt install -y \
    snmp \
    snmpd \
    libsnmp-dev
```

---

## SSL / CURL / XML

```bash
sudo apt install -y \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libevent-dev \
    libpcre2-dev \
    libopenipmi-dev \
    libssh-dev \
    zlib1g-dev
```

---

## PHP Frontend

```bash
sudo apt install -y \
    nginx \
    php8.5 \
    php8.5-fpm \
    php8.5-pgsql \
    php8.5-gd \
    php8.5-bcmath \
    php8.5-mbstring \
    php8.5-xml \
    php8.5-curl \
    php8.5-ldap \
    php8.5-zip
```

---

# 4. Configure PostgreSQL

Create the database user.

```bash
sudo -u postgres psql
```

```sql

CREATE USER ktrix WITH PASSWORD 'change_me';

CREATE DATABASE ktrix
    OWNER ktrix
    ENCODING 'UTF8';

GRANT ALL PRIVILEGES ON DATABASE ktrix TO ktrix;

\q


CREATE USER coirtx WITH PASSWORD 'change_me';

CREATE DATABASE coirtx
    OWNER coirtx
    ENCODING 'UTF8';

GRANT ALL PRIVILEGES ON DATABASE coirtx TO coirtx;

\q



CREATE USER zabbix WITH PASSWORD 'change_me';

CREATE DATABASE zabbix
    OWNER zabbix
    ENCODING 'UTF8';

GRANT ALL PRIVILEGES ON DATABASE zabbix TO zabbix;

\q
```

Verify connectivity.

```bash


PGPASSWORD=change_me \
psql \
    -h localhost \
    -U ktrix \
    -d ktrix


PGPASSWORD=change_me \
psql \
    -h localhost \
    -U coirtx\
    -d coirtx



PGPASSWORD=change_me \
psql \
    -h localhost \
    -U zabbix \
    -d zabbix

```

---

# 5. Configure PHP

Edit:

```text
/etc/php/8.5/fpm/php.ini
```

Recommended values:

```ini
memory_limit = 256M
max_execution_time = 300
max_input_time = 300
post_max_size = 16M
upload_max_filesize = 2M
max_input_vars = 10000
date.timezone = Asia/Kolkata
```

Restart PHP.

```bash
sudo systemctl restart php8.5-fpm
```

---

# 6. Clone Zabbix

```bash
git clone git@github.com:oirtstut/coirtx.git
cd coirtx
git checkout branding/coirtx



git clone https://github.com/zabbix/zabbix.git
cd zabbix
git checkout release/7.4

```

Verify version.

```bash
git describe --tags
```

---

# 7. Bootstrap

The Git repository must be bootstrapped before configuring.

```bash
./bootstrap.sh
```

---

# 8. Configure

Example configuration.
Before configure, install go if not available

```bash

sudo apt install golang-go

./configure \
    --enable-server \
    --enable-agent \
    --with-postgresql \
    --with-net-snmp \
    --with-libcurl \
    --with-openssl




When building the server:


./configure \
    --prefix=/opt/ktrix \
    --sysconfdir=/etc/ktrix \
    --localstatedir=/var \
    --enable-server \
    --enable-agent2 \
    --enable-webservice \
    --with-postgresql \
    --with-net-snmp \
    --with-libcurl \
    --with-openipmi \
    --with-libxml2 \
    --with-ssh2 \
    --with-openssl


./configure \
    --prefix=/opt/coirtx \
    --sysconfdir=/etc/coirtx \
    --localstatedir=/var \
    --enable-server \
    --enable-agent2 \
    --enable-webservice \
    --with-postgresql \
    --with-net-snmp \
    --with-libcurl \
    --with-openipmi \
    --with-libxml2 \
    --with-ssh2 \
    --with-openssl


When building the proxy
./configure \
    --prefix=/opt/coirtx \
    --sysconfdir=/etc/coirtx \
    --localstatedir=/var \
    --enable-proxy \
    --enable-agent2 \
    --with-sqlite3 \
    --with-net-snmp \
    --with-libcurl \
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

Adjust options as needed.

---

# 9. Generate Database Schema

**Important**

The Git repository **does not contain**

```
schema.sql
data.sql
```

These files are generated during the build.

Generate them:

```bash
make dbschema
```

Verify:

```bash
ls database/postgresql
```

Expected:

```
schema.sql
images.sql
data.sql
```

---

# 10. Import Database

```bash

cat \
    database/postgresql/schema.sql \
    database/postgresql/images.sql \
    database/postgresql/data.sql \
| PGPASSWORD=change_me \
    psql \
        -h localhost \
        -U ktrix \
        -d ktrix


cat \
    database/postgresql/schema.sql \
    database/postgresql/images.sql \
    database/postgresql/data.sql \
| PGPASSWORD=change_me \
    psql \
        -h localhost \
        -U coirtx\
        -d coirtx

cat \
    database/postgresql/schema.sql \
    database/postgresql/images.sql \
    database/postgresql/data.sql \
| PGPASSWORD=change_me \
    psql \
        -h localhost \
        -U zabbix \
        -d zabbix


```

Verify:

```bash


PGPASSWORD=change_me \
psql \
    -h localhost \
    -U ktrix \
    -d ktrix \
    -c "\dt"



PGPASSWORD=change_me \
psql \
    -h localhost \
    -U coirtx \
    -d coirtx \
    -c "\dt"



PGPASSWORD=change_me \
psql \
    -h localhost \
    -U zabbix \
    -d zabbix \
    -c "\dt"


```

Numerous tables should be listed.

---

# 11. Compile

```bash
make -j$(nproc)
```

---

# 12. Install

```bash
sudo make install
```

```

# 13. Configure Zabbix Server

Edit:

```
sudo vi /etc/ktrix/zabbix_server.conf

sudo vi /etc/coirtx/zabbix_server.conf

sudo vi /etc/zabbix/zabbix_server.conf
```

Example:

```ini

DBHost=localhost
DBPort=5432 ; generally not required if db and server are same
DBName=ktrix
DBUser=ktrix
DBPassword=change_me


DBHost=localhost
DBPort=5432 ; generally not required if db and server are same
DBName=zabbix
DBUser=zabbix
DBPassword=change_me
```

---

# 14. Frontend

## Install the frontend

I recommend copying it to a standard web location rather than into /opt/zabbix. (However, this gives error, need to recheck it, till that time, ignore this step)

```

sudo mkdir -p /var/www/coirtx
sudo cp -a ~/coirtx/ui/. /var/www/coirtx/



sudo mkdir -p /var/www/zabbix
sudo cp -a ~/zabbix/ui/. /var/www/zabbix/

```

Set ownership

```
sudo chown -R www-data:www-data /var/www/coirtx


sudo chown -R www-data:www-data /var/www/zabbix

```

In next step, change

```

root /opt/coirtx/ui;
to
root /var/www/coirtx;


root /opt/zabbix/ui;
to
root /var/www/zabbix;


```

Test:

```

sudo nginx -t

```

Reload:

```

sudo systemctl reload nginx

```


### Reasons:

```

Standard Linux web layout.
Independent of the build tree.
You can safely delete or update the source repository later.
Matches how distribution packages deploy the frontend.

```

That gives you a cleaner separation:

```

Binaries: /opt/zabbix
Configuration: /etc/zabbix
Runtime data: /var
Web frontend: /var/www/zabbix

```

This is a much more maintainable layout for both upstream Zabbix and your future Coirtx distribution.


# 14a. Configure Nginx

Document root should point to the installed frontend.


cat /etc/nginx/sites-available/ktrix

cat /etc/nginx/sites-available/coirtx

```
server {
    listen 80;
    server_name _;

    root /opt/coirtx/ui;
    index index.php;

    access_log /var/log/nginx/coirtx.access.log;
    error_log  /var/log/nginx/coirtx.error.log;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;

        fastcgi_pass unix:/run/php/php8.5-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;

        include fastcgi_params;
    }

    location ~ /\.(ht|git) {
        deny all;
    }
}
```
Next, enable it with:
```


sudo ln -s /etc/nginx/sites-available/ktrix \
           /etc/nginx/sites-enabled/


sudo ln -s /etc/nginx/sites-available/coirtx \
           /etc/nginx/sites-enabled/



sudo ln -s /etc/nginx/sites-available/zabbix \
           /etc/nginx/sites-enabled/

```

Disable the default site if desired:

```
sudo rm /etc/nginx/sites-enabled/default

```
Reload or restart nginx

```
sudo systemctl restart nginx
or
sudo systemctl reload nginx

```

Configure PHP-FPM socket:

```
unix:/run/php/php8.5-fpm.sock
```

---

# 15. Start Zabbix


Create User as per point 13

```

sudo groupadd --system ktrix
sudo useradd \
    --system \
    --gid ktrix \
    --home-dir /var/lib/ktrix \
    --create-home \
    --shell /usr/sbin/nologin \
    ktrix


sudo groupadd --system coirtx
sudo useradd \
    --system \
    --gid coirtx \
    --home-dir /var/lib/coirtx \
    --create-home \
    --shell /usr/sbin/nologin \
    coirtx


verify:

id coirtx




sudo groupadd --system zabbix
sudo useradd \
    --system \
    --gid zabbix \
    --home-dir /var/lib/zabbix \
    --create-home \
    --shell /usr/sbin/nologin \
    zabbix


verify:

id zabbix



```

Editing done in point 13, now
Start Server:
```
sudo vi /etc/ktrix/zabbix_server.conf
uncomment User=zabbix
and change zabbix to ktrix, else server wont start


sudo vi /etc/coirtx/zabbix_server.conf
uncomment User=zabbix
and change zabbix to coirtx, else server wont start


sudo /opt/ktrix/sbin/zabbix_server -c /etc/ktrix/zabbix_server.conf -f


sudo /opt/coirtx/sbin/zabbix_server -c /etc/coirtx/zabbix_server.conf -f


sudo /opt/zabbix/sbin/zabbix_server -c /etc/zabbix/zabbix_server.conf -f

```


```bash
zabbix_server
```

or configure a systemd service.

Verify:

```bash
ps aux | grep zabbix_server
```

---

# 16. Open the Frontend

Navigate to:

```
http://<server-ip>/
```

Complete the web installer.

Database:

- PostgreSQL
- Host: localhost
- Port: 5432
- Database: zabbix
- User: zabbix

---

# 17. Verify Installation

Database:

```bash
PGPASSWORD=change_me \
psql \
    -h localhost \
    -U zabbix \
    -d zabbix \
    -c "SELECT COUNT(*) FROM users;"
```

Server:

```bash
zabbix_server -V
```

PHP:

```bash
php -v
```

PostgreSQL:

```bash
psql --version
```

---

# Notes

## Git Repository vs Release Tarball

The Git repository differs from release archives.

Release archives contain:

```
database/postgresql/
├── schema.sql
├── images.sql
└── data.sql
```

The Git repository only contains templates and generates these files during:

```bash
make dbschema
```

Do **not** attempt to import the database before running `make dbschema`.

---

## Reference Environment

| Component | Version |
|-----------|----------|
| Ubuntu | 26.04 LTS |
| PostgreSQL | 18.x |
| PHP | 8.5 |
| Nginx | Latest Ubuntu package |
| Zabbix | Git `release/7.4` |

---

## Next Step

Once this installation works completely, use it as the baseline for the Coirtx fork. Compare any differences in:

- configure options
- generated SQL
- installation prefix
- frontend assets
- branding
- database changes
- build scripts

This minimizes the risk of debugging issues caused by unrelated changes.


# Presently for icon updates
modify the icons in sass folder in mac.
push the modifications to github
pull from github.
make
make install

copy icons from sass/ folder to ui/assets/img
finally copy the ui folder to runtime folder.

```

sudo cp -rf ~/coirtx/ui /opt/coirtx/

```


# Make a systemctl service:

```
sudo vi /etc/systemd/system/coirtx-server.service
```

```

[Unit]
Description=Coirtx Server
Documentation=https://www.oirtsix.com/documentation/
After=network.target postgresql.service
Wants=network.target

[Service]
Type=forking
User=coirtx
Group=coirtx

ExecStart=/opt/coirtx/sbin/zabbix_server -c /etc/coirtx/zabbix_server.conf
ExecReload=/opt/coirtx/sbin/zabbix_server -R config_cache_reload
ExecStop=/bin/kill -SIGTERM $MAINPID

PIDFile=/run/coirtx/zabbix_server.pid

Restart=on-failure
RestartSec=10s

RuntimeDirectory=coirtx
RuntimeDirectoryMode=0755

LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

```

Then run:

```

sudo systemctl daemon-reload
sudo systemctl enable coirtx-server
sudo systemctl start coirtx-server

```

Useful commands:
```

sudo systemctl status coirtx-server
sudo journalctl -u coirtx-server -f
sudo systemctl restart coirtx-server
sudo systemctl stop coirtx-server

```

### Before using this service, verify two things
 - Your configuration should contain:

 ```

PidFile=/run/coirtx/zabbix_server.pid

```

The Linux user exists:

```

id coirtx

```

If it doesn't, create it:

```

sudo useradd --system --home /nonexistent --shell /usr/sbin/nologin coirtx

```

Also make sure the log and data directories are owned by coirtx.

