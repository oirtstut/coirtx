## Step 1 — Fresh Ubuntu
```

sudo apt update
sudo apt upgrade -y
sudo reboot

```

## Step 2 — Install development tools
```

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

## Step 3 — Install PostgreSQL

```

sudo apt install -y \
    postgresql \
    postgresql-contrib \
    libpq-dev

```

## Verify:

```

systemctl status postgresql

```

## Step 4 — Install PHP + Nginx

```

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

## Step 5 — Install Zabbix build dependencies

```

sudo apt install -y \
    libevent-dev \
    libsnmp-dev \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libpcre2-dev \
    libopenipmi-dev \
    libssh-dev \
    zlib1g-dev

```


## Step 6 — Clone Zabbix

```

git clone https://github.com/zabbix/zabbix.git
cd zabbix
git checkout release/7.4

```

## Step 7 — Verify the SQL layout (important)

Before configuring or compiling, run:

```

find database -maxdepth 2 -type f

```

This is the first checkpoint.
