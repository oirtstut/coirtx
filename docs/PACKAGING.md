# PACKAGING.md

# Packaging COIRTX

Future releases will provide native installation packages.

---

# Supported Formats

- Debian (.deb)
- RPM
- Docker
- OCI containers

---

# Package Layout

```
coirtx-server

coirtx-agent

coirtx-agent2

coirtx-proxy

coirtx-web

coirtx-common
```

---

# Installation Paths

```
/opt/coirtx

/etc/coirtx

/var/lib/coirtx

/var/log/coirtx
```

---

# systemd

Future packages will install

```
coirtx-server.service

coirtx-proxy.service

coirtx-agent.service

coirtx-web.service
```

---

# Package Signing

Release packages should be signed.

---

# Versioning

COIRTX follows semantic versioning.

Examples

```
8.0.0

8.1.0

9.0.0
```

Package revision

```
8.0.0-1

8.0.0-2
```

---

# Release Checklist

- build succeeds
- tests pass
- branding complete
- documentation updated
- packages signed
- release notes published
