# DEVELOPMENT.md

# Developing COIRTX

This document describes the development workflow.

---

# Repository

```
master
```

Always tracks upstream Zabbix.

Never commit custom features directly to master.

---

# Feature Branches

Example:

```
branding/coirtx

feature/dashboard

feature/discovery

feature/maps
```

---

# Build

```
./bootstrap.sh

./configure ...

make -j$(nproc)

sudo make install
```

---

# Coding Style

COIRTX follows the upstream coding conventions whenever possible.

Additional rules:

- keep commits focused
- avoid unrelated formatting changes
- preserve upstream history
- minimize merge conflicts

---

# Syncing Upstream

```
git fetch upstream

git checkout master

git merge upstream/master
```

Then rebase feature branches.

---

# Commit Messages

Examples

```
branding: add product identity helper

ui: replace footer branding

server: rename runtime binary
```

---

# Pull Requests

Every PR should

- compile
- start successfully
- pass existing tests
- remain compatible with upstream unless intentionally diverging
