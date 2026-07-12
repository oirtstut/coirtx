# INSTALL.md

# Installing COIRTX

This document describes how to install COIRTX on a clean Linux server.

## Supported Platform

Reference platform:

- Ubuntu Server 26.04 LTS
- PostgreSQL
- Nginx
- PHP 8.5

---

# Installation Methods

COIRTX supports multiple installation methods.

## Method 1 — Build from Source

See:

```
BUILD.md
```

Recommended for:

- developers
- contributors
- testing
- branding work

---

## Method 2 — Native Packages

(Not yet available.)

Future releases will provide:

- Debian (.deb)
- RPM
- Container images

---

# Runtime Architecture

```
           Browser
               │
            Nginx
               │
          PHP-FPM 8.5
               │
          COIRTX Frontend
               │
      COIRTX Server
               │
          PostgreSQL
```

---

# Installation Layout

Future layout:

```
/opt/coirtx
    bin/
    sbin/
    ui/
    database/
    share/

/etc/coirtx

/var/lib/coirtx

/var/log/coirtx
```

---

# First Login

Default credentials:

```
Username: Admin
Password: zabbix
```

Future releases may change the default password during installation.

---

# Next Steps

- Configure the database
- Add the first host
- Configure email
- Configure users
- Configure discovery

See the Administrator Guide.


# Create the service

Create the service:

sudo nano /etc/systemd/system/coirtx-server.service

Paste this:

[Unit]
Description=COIRTX Server
Documentation=https://www.zabbix.com/documentation/
After=network-online.target mariadb.service
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/opt/coirtx/sbin/zabbix_server -c /etc/coirtx/zabbix_server.conf -f
Restart=on-failure
RestartSec=5

# Optional hardening
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target

Then enable and start it:

sudo systemctl daemon-reload
sudo systemctl enable coirtx-server
sudo systemctl start coirtx-server

Verify:

systemctl status coirtx-server

You should see something like:

● coirtx-server.service - COIRTX Server
     Loaded: loaded (/etc/systemd/system/coirtx-server.service; enabled)
     Active: active (running)

You can also confirm it's enabled for boot:

systemctl is-enabled coirtx-server

Expected output:

enabled
