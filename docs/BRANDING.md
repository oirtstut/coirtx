# BRANDING.md

# COIRTX Branding Architecture

COIRTX is designed so that branding is centralized rather than scattered throughout the codebase.

---

# Goals

- avoid hardcoded strings
- simplify future rebranding
- minimize upstream conflicts

---

# CBrandHelper

All frontend branding should be accessed through

```
CBrandHelper
```

Example

```php
CBrandHelper::getProductName()
```

instead of

```php
"Zabbix"
```

---

# Branding Configuration

```
local/conf/brand.conf.php
```

Example

```php
return [

    'BRAND_PRODUCT_NAME' => 'COIRTX',

    'BRAND_PRODUCT_FULL_NAME' => 'COIRTX Network Monitoring',

    'BRAND_COMPANY_NAME' => 'OIRT',

    'BRAND_VENDOR_URL' => 'https://example.com'

];
```

---

# Brand Assets

Future assets

```
logos/

favicon/

icons/

css/

themes/
```

---

# Backend Branding

Eventually all binaries should identify themselves as

```
coirtx_server

coirtx_proxy

coirtx_agentd

coirtx_agent2
```

instead of the upstream names.

---

# Philosophy

Branding should be isolated.

Business logic should never depend upon branding.
