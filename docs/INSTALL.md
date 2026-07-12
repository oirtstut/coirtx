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
