<div align="center">

<img src="assets/overview.webp" alt="Djoser: from config to running services" width="760">

**A native, Windows-first developer environment manager for PHP and Laravel.**

Per-project PHP, local HTTPS sites, MySQL and Redis, without Docker, WSL or touching the PHP already on your machine.

![Platform](https://img.shields.io/badge/platform-Windows%20x64-0078D4)
![C++](https://img.shields.io/badge/C%2B%2B-23-00599C)
[![Release](https://img.shields.io/github/v/release/Egyptus/Djoser?include_prereleases)](https://github.com/Egyptus/Djoser/releases)

### [Download for Windows](https://github.com/Egyptus/Djoser/releases/latest)

</div>

> Djoser is at an early stage. Expect changes between versions.

## Why Djoser

- **One file per project.** `djoser.yaml` says what a project needs, and `djoser up` makes it true.
- **Versions side by side.** Every project uses its own PHP, MySQL and Redis versions.
- **Real HTTPS.** Each project gets its own `https://name.localhost` address.
- **No administrator rights.** Djoser installs for your user only, and everything it downloads stays in one folder.
- **Your data stays.** `down`, `remove` and `uninstall` never delete a database.

## Install

Download the installer from the [latest release](https://github.com/Egyptus/Djoser/releases/latest) and run it. It offers two options:

| Option | Default | What it does |
|---|---|---|
| Add Djoser to `PATH` | On | `djoser` works in any new terminal |
| Add the tools to `PATH` | Off | `php`, `composer`, `node`, `mysql` and the others work in any new terminal. If another copy is already on `PATH`, the one listed first is used |

The installer is not signed yet, so Windows or your antivirus may warn before running it. Choose **More info**, then **Run anyway**, and compare the file with the SHA-256 in the release notes.

To update, run the new installer. It stops Djoser first and keeps your projects and databases.

## Create a Laravel project

This goes from nothing to a running site. To add Djoser to a project you already have, start at step 3 inside its folder.

### 1. Get PHP, Composer and Node.js

```powershell
djoser install php 8.5
djoser install composer latest
djoser install node 22
```

### 2. Create the project

```powershell
djoser composer create-project laravel/laravel shop
cd shop
```

### 3. Describe it

```powershell
djoser init --name shop --domain shop.localhost --root public --php 8.5 -y
```

Leave out the options and `init` asks for each one. With PHP it also writes a few PHP settings you can change. Then open `djoser.yaml` and add what the project needs:

```yaml
name: shop
domain: shop.localhost
web-root: public
services:
  php:
    version: 8.5
    extensions: [redis]
    ini:
      memory_limit: 512M
      upload_max_filesize: 64M
      post_max_size: 64M
      max_execution_time: 120
  mysql:
    version: 8.4
    database: shop
  redis: 8.4
```

`extensions: [redis]` is the PHP extension that talks to Redis. `redis: 8.4` is the Redis server itself. You need both.

### 4. Start it

```powershell
djoser up
```

The first run downloads what is missing, starts it, and offers to trust the local certificate so browsers accept the site.

<img src="assets/djoser-up.webp" alt="djoser up downloading PHP, MySQL and Redis" width="720">

It ends with the address and the connection details:

```text
shop is up on PHP 8.5.12 (6 workers, ports 19000-19005)
  https://shop.localhost
Note: mysql on 127.0.0.1:3306, database shop, user root, no password
Note: redis on 127.0.0.1:6379 (community Windows build)
```

### 5. Connect Laravel

Let Djoser check `.env` against what it runs:

```powershell
djoser env sync
```

Each difference shows the line you have, commented out in red, and the line Djoser expects in green under it, so you can copy either:

```text
#DB_CONNECTION=sqlite
DB_CONNECTION=mysql
#DB_PORT (missing)
DB_PORT=3306
```

It then asks `Update .env? [y/N]`. Only `y` or `yes` changes the file, and only those lines. Or set the values yourself:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=shop
DB_USERNAME=root
DB_PASSWORD=

REDIS_CLIENT=phpredis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379

CACHE_STORE=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
```

Projects using the same Redis version share one server, so give each project its own `REDIS_PREFIX`.

### 6. Prepare the app

```powershell
djoser artisan migrate
djoser npm install
djoser npm run build
```

Open `https://shop.localhost`.

### 7. Run the background work

Each of these stays open, so give it its own terminal:

```powershell
djoser artisan queue:work
djoser artisan schedule:work
djoser npm run dev
```

## See what is running

```powershell
djoser status
```

<img src="assets/djoser-status.webp" alt="djoser status listing each service, its state, port and database" width="720">

`djoser status` also shows what changed in `djoser.yaml` since the last `up`. `djoser ps` lists every running project.

## Describe a project

<img src="assets/djoser-yaml.webp" alt="A djoser.yaml file" width="560">

Edit the file and run `djoser up` to apply it. A version can be a line such as `8.5` or an exact one such as `8.5.12`.

| Key under a service | What it does |
|---|---|
| `version` | The version to run |
| `extensions` | PHP extensions, such as `[redis, imagick, xdebug]` |
| `database` | The database name; by default the project's name, with `-` turned into `_` |
| `bucket` | The S3 bucket name for `rustfs`; by default the project's name |
| `port` | Run a separate server for this project on this port |
| `data` | Run a separate server with its data in this folder, which must exist |
| `dedicated: true` | Run a separate server for this project |
| `ini` | PHP settings for this project, one per line, such as `memory_limit: 1G` |
| `settings` | The server's own options, one per line; gives the project its own server |

To change PHP settings from the terminal:

```powershell
djoser config php memory_limit=1G,upload_max_filesize=200M
djoser config php
```

The first writes them to `djoser.yaml` and restarts the project's PHP if it is running; an empty value, such as `memory_limit=`, removes one. The second lists them.

Servers are shared between projects by default, with one database per project, on `127.0.0.1` only. A separate server starts with empty data.

At the top of the file, `backups: D:/Backups/shop` sends this project's backups to that folder, relative to the project or absolute. By default they go to `Documents\Djoser\Backups\<project>`.

## Every option, service by service

Each block shows every key Djoser reads, with the value it uses when the key is left out. You only write what you want to change; `mysql: 8.4` alone is enough. A key that has no effect where it is written is reported by `up`, and an unknown one is a warning.

### The project

```yaml
name: shop                     # default: the folder's name
domain: shop.localhost         # default: <name>.localhost
web-root: public               # default: public for Laravel, else the folder holding index.php or index.html
tls:                           # default: Djoser's local certificate
  cert: certs/shop.pem         # your own certificate and key, relative to the project
  key: certs/shop-key.pem
```

### php

```yaml
php:
  version: 8.5                 # a line such as 8.5, or an exact 8.5.12
  extensions: [redis, xdebug]  # default: none beyond what ships with PHP
  ini:                         # default: PHP's own values; djoser init writes these four
    memory_limit: 512M
    upload_max_filesize: 64M
    post_max_size: 64M
    max_execution_time: 120
```

`ini` takes any `php.ini` setting except `extension`, `zend_extension`, `extension_dir`, `curl.cainfo` and `openssl.cafile`. Change it from the terminal with `djoser config php memory_limit=1G`.

### node

```yaml
node: 22                       # a line such as 22, or an exact 22.23.4
```

### mysql and mariadb

```yaml
mysql:                         # or mariadb:
  version: 8.4                 # mysql: 8.0, 8.4, 9.7   mariadb: 10.11, 11.4, 11.8, 12.3, 13.0
  database: shop               # default: the project's name, - becomes _
  port: 3306                   # default: shared server from 3306; setting it gives the project its own
  data: D:/Data/shop-mysql     # default: <home>\data\mysql-8.4; the folder must exist
  dedicated: true              # default: false
  settings:                    # passed as --name=value; gives the project its own server
    max_connections: 500
    sql_mode: STRICT_TRANS_TABLES,NO_ZERO_DATE
    innodb_buffer_pool_size: 512M
    character_set_server: utf8mb4
```

User `root`, no password, `127.0.0.1` only. Djoser sets `datadir`, `port`, `bind_address`, `socket`, `console`, `mysqlx` and `no_defaults` itself.

### postgres

```yaml
postgres:
  version: 17                  # 15, 16, 17, 18
  database: shop               # default: the project's name, - becomes _
  port: 5432                   # default: shared server from 5432
  data: D:/Data/shop-pg
  dedicated: true
  settings:                    # passed as -c name=value
    max_connections: 200
    shared_buffers: 256MB
    work_mem: 16MB
    log_min_duration_statement: 500
```

User `postgres`, no password, `127.0.0.1` only. Djoser sets `port`, `listen_addresses`, `data_directory` and `hba_file` itself.

### mongodb

```yaml
mongodb:
  version: 8.0                 # 7.0, 8.0, 8.2, 8.3; mongosh comes with it
  database: shop               # default: the project's name, - becomes _; made on first write
  port: 27017                  # default: shared server from 27017
  data: D:/Data/shop-mongo
  dedicated: true
  settings:                    # passed as --name value
    wiredTigerCacheSizeGB: 1
    setParameter: diagnosticDataCollectionEnabled=false
```

No authentication, `127.0.0.1` only. Djoser sets `dbpath`, `port`, `bind_ip` and `bind_ip_all` itself. For Laravel, add the `mongodb` PHP extension and `composer require mongodb/laravel-mongodb`; `djoser env sync` sets `MONGODB_URI` and `MONGODB_DATABASE`.

### redis

```yaml
redis:
  version: 8.4                 # 7.2, 7.4, 8.4, 8.10
  port: 6379                   # default: shared server from 6379
  data: D:/Data/shop-redis
  dedicated: true
  settings:                    # passed as --name value
    maxmemory: 256mb
    maxmemory-policy: allkeys-lru
    appendonly: "yes"
```

No password. Djoser sets `port`, `bind` and `dir` itself. Projects sharing a server share keys, so give each its own `REDIS_PREFIX`.

### rustfs

```yaml
rustfs:
  version: 1.0
  bucket: shop                 # default: the project's name
  port: 9000                   # default: shared server from 9000; the console takes the next free port
  data: D:/Data/shop-s3
  dedicated: true
  settings:                    # passed as RUSTFS_<NAME> environment variables
    access_key: rustfsadmin    # default key and secret: rustfsadmin
    secret_key: rustfsadmin
    region: us-east-1
```

Djoser sets `address`, `console_address`, `volumes` and `check_update` itself.

### mailpit

```yaml
mailpit:
  version: 1.33
  port: 1025                   # SMTP; default: shared server from 1025, inbox from 8025
  data: D:/Data/shop-mail
  dedicated: true
  settings:                    # passed as --name=value
    max: 2000                  # messages kept; default 500
    smtp-max-recipients: 100
```

Djoser sets `smtp`, `listen` and `database` itself.

`settings` gives the project its own server, because one shared server cannot follow two projects' options; that server starts with empty data. Changing `settings` and running `djoser up` restarts it. Djoser does not check option names against each server's list: a misspelt one stops that server, and `djoser services` shows it failed.

## Store files in S3

```yaml
services:
  rustfs: 1.0
```

`up` starts an S3-compatible server on `127.0.0.1`, makes a bucket named after the project, and prints the address, the web console and the keys. For Laravel, install `league/flysystem-aws-s3-v3` and set:

```env
FILESYSTEM_DISK=s3
AWS_ACCESS_KEY_ID=rustfsadmin
AWS_SECRET_ACCESS_KEY=rustfsadmin
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=shop
AWS_ENDPOINT=http://127.0.0.1:9000
AWS_USE_PATH_STYLE_ENDPOINT=true
```

Use the port `up` printed if it is not 9000.

## Catch mail

```yaml
services:
  mailpit: 1.33
```

Every message your app sends lands in an inbox at `http://127.0.0.1:8025` instead of a real mailbox. For Laravel, `djoser env sync` sets `MAIL_MAILER=smtp`, `MAIL_HOST=127.0.0.1` and `MAIL_PORT` (1025 unless `up` printed another port).

## Open the database

```powershell
djoser tool db
```

Opens [HeidiSQL](https://www.heidisql.com/) on this project's database, downloading it the first time. In the terminal, `djoser mysql`, `djoser mariadb`, `djoser psql` and `djoser redis-cli` connect to the project's services by themselves.

## Back up the database

```powershell
djoser db backup
djoser db list
djoser db restore
```

`backup` writes one file for each database in `djoser.yaml` (mysql, mariadb, postgres, mongodb), such as `my_shop-mysql-20261114-153005.sql`, to `Documents\Djoser\Backups\<project>`. They stay after Djoser is uninstalled, and Djoser never deletes them. The server must be running; `--service mysql` backs up only one.

`restore` loads the newest backup of each database, or the file you name, such as `djoser db restore my_shop-mysql-20261114-153005.sql`. It first backs up what is there now (a file ending in `-before-restore`), shows what it will replace, and goes on only when you type `y`. Without a terminal it needs `-y`.

`djoser uninstall` of a database version offers to back up the projects that use it first. MongoDB backups need the MongoDB Database Tools, which Djoser downloads the first time.

## Share your site

```powershell
djoser share
```

Prints a temporary public address through Cloudflare, with no account needed, while the command runs. Anyone with the address can open the site. Press Ctrl+C to stop.

For Laravel, set `APP_URL` to that address and trust proxies, or styles and links may break.

## Commands

| Project | |
|---|---|
| `djoser init` | Create `djoser.yaml` |
| `djoser up` / `down` | Start or stop the project |
| `djoser status` | Its services and pending changes |
| `djoser config php key=value,...` | Show or change the project's PHP settings |
| `djoser env sync` | Compare `.env` with what Djoser runs, and update it after a typed yes |
| `djoser remove` | Stop it and forget it; files and data stay |
| `djoser ps` | Running projects; `-a` adds stopped ones |
| `djoser projects` | Every project Djoser knows, with its folder |
| `djoser exec <project> <tool>` | Run a tool inside a project, from anywhere |
| `djoser tool db` | Open HeidiSQL on the project's database |
| `djoser db backup` / `restore` / `list` | Back up the project's databases, restore one after a typed yes, list the backups |
| `djoser share` | A temporary public address, until Ctrl+C |

| Tools | |
|---|---|
| `djoser php`, `composer`, `artisan` | Run with the project's PHP |
| `djoser node`, `npm`, `npx` | Run with the project's Node.js |
| `djoser mysql`, `mysqldump`, `mariadb`, `mariadb-dump`, `psql`, `pg_dump`, `mongosh`, `redis-cli` | Connect to the project's services |

| Versions | |
|---|---|
| `djoser list <service>` | What can be installed; `--all` adds archived PHP builds |
| `djoser install <service> <version>` | Download a version, such as `php 8.5`, `mysql 8.4`, `redis 8.4`, `node 22` |
| `djoser install composer latest` | Download Composer |
| `djoser add php <folder>` | Use a PHP already on this machine, where it is |
| `djoser install heidisql`, `cloudflared`, `mongosh`, `mongodb-tools` | Download a helper program ahead of time |
| `djoser install php-ext <name>` | Add a PHP extension to this project |
| `djoser use <service> <version>` | Choose a version for this project; `--env` sets the default |
| `djoser runtimes` | What is installed |
| `djoser uninstall <service> <version>` | Remove a version, offering a backup first; databases stay |

| Machine | |
|---|---|
| `djoser trust` | Trust the local certificate for HTTPS |
| `djoser doctor` | Check this machine and explain how to fix problems |
| `djoser engine start` / `stop` / `status` | Control Djoser's background service; other commands start it when needed |
| `djoser services` | Every process Djoser runs, with its state and port |
| `djoser operations` | Recent downloads and checks; `operations cancel <id>` stops one |

Run `djoser <command> --help` for every option.

## What runs today

| | |
|---|---|
| PHP | Official builds, one pool per version and set of extensions |
| PHP extensions | redis, imagick, memcached, xdebug, sqlsrv, pdo_sqlsrv, apcu, mongodb, amqp, and what ships with PHP |
| Composer, Node.js | Per-project versions, in any folder |
| MySQL | 8.0, 8.4, 9.7 |
| MariaDB | 10.11, 11.4, 11.8, 12.3, 13.0 |
| PostgreSQL | 15, 16, 17, 18 |
| MongoDB | 7.0, 8.0, 8.2, 8.3, with mongosh |
| Redis | 7.2, 7.4, 8.4, 8.10, from a community Windows build |
| RustFS (S3) | 1.0, with a web console and a bucket per project |
| Mailpit | 1.33, catches the mail your app sends |
| Sites | Caddy, HTTPS on `*.localhost` |
| Helpers | HeidiSQL, cloudflared |

Database backups are planned.

## This repository

It holds the installer in [Releases](https://github.com/Egyptus/Djoser/releases) and the tables in [`catalog/`](catalog), which list the versions Djoser may download and the SHA-256 of each file. Djoser reads them so that new versions can be added without a new release.

The tables are written by the scripts in [`scripts/`](scripts), which need PowerShell 7:

```powershell
pwsh scripts/update-services.ps1     # services and helper programs
pwsh scripts/update-extensions.ps1   # PHP extensions
```

A version already listed keeps its hash; a new one is downloaded once and hashed.

<div align="center">

<img src="assets/banner.webp" alt="The Djoser banner" width="560">

</div>
