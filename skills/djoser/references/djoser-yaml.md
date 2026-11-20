# djoser.yaml


Edit the file and run `djoser up` to apply it; `djoser status` says when the file changed since the last `up`. You only write what you need: `mysql: 8.4` alone is enough. A key that has no effect where it is written is reported by `up`, and an unknown one is a warning.

## The project

```yaml
name: shop                     # default: the folder's name
domain: shop.localhost         # default: <name>.localhost
aliases: [www, api]            # more subdomains of the domain; "*" serves any, for multi-tenant apps
web-root: public               # default: public for Laravel, else the folder holding index.php or index.html
tls:                           # default: Djoser's local certificate
  cert: certs/shop.pem         # your own certificate and key, relative to the project; they must cover the aliases
  key: certs/shop-key.pem
backups: D:/Backups/shop       # default: Documents\Djoser\Backups\<name>; relative to the project or absolute
services:                      # see below
scripts:                       # see below
workers:                       # see below
```

A version is a line such as `8.5` or an exact one such as `8.5.12`. Servers are shared by projects, with one database per project, on `127.0.0.1` only; `port:`, `data:`, `dedicated: true` or `settings:` give a project its own server, which starts with empty data.

## php

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

`ini` takes any `php.ini` setting except `extension`, `zend_extension`, `extension_dir`, `curl.cainfo` and `openssl.cafile`. Extensions Djoser can download: `djoser list extensions`.

## node

```yaml
node: 22                       # a line such as 22, or an exact 22.23.4
```

Without `node:`, Djoser reads the project's `.nvmrc`, then `.node-version`, as nvm and fnm do: `22`, `v22.11.0`, `lts/*`, `lts/iron` or `node`. A version they name that is not installed is an error that names the file; Djoser never runs another one instead.

## mysql and mariadb

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

## postgres

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

User `postgres`, no password, `127.0.0.1` only. Djoser sets `port`, `listen_addresses`, `data_directory` and `hba_file` itself. For Laravel, `env sync` sets `DB_CONNECTION=pgsql`.

## mongodb

```yaml
mongodb:
  version: 8.0                 # 7.0, 8.0, 8.2, 8.3; mongosh comes with it
  database: shop               # default: the project's name, - becomes _; made on first write
  port: 27017                  # default: shared server from 27017
  data: D:/Data/shop-mongo
  dedicated: true
  settings:                    # passed as --name value
    wiredTigerCacheSizeGB: 1
```

No authentication, `127.0.0.1` only. Djoser sets `dbpath`, `port`, `bind_ip` and `bind_ip_all` itself. For Laravel, add the `mongodb` PHP extension and `composer require mongodb/laravel-mongodb`; `env sync` sets `MONGODB_URI` and `MONGODB_DATABASE`.

## redis

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

No password. Djoser sets `port`, `bind` and `dir` itself.

## rustfs

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

Djoser sets `address`, `console_address`, `volumes` and `check_update` itself. For Laravel, `composer require league/flysystem-aws-s3-v3`; `env sync` sets every `AWS_*` value, including `AWS_USE_PATH_STYLE_ENDPOINT=true`.

## mailpit

```yaml
mailpit:
  version: 1.33
  port: 1025                   # SMTP; default: shared server from 1025, inbox from 8025
  data: D:/Data/shop-mail
  dedicated: true
  settings:                    # passed as --name=value
    max: 2000                  # messages kept; default 500
```

Djoser sets `smtp`, `listen` and `database` itself. Nothing leaves the machine.

`settings` gives the project its own server, because one shared server cannot follow two projects' options. Changing `settings` and running `djoser up` restarts it. Djoser does not check option names against each server's list: a misspelt one stops that server, and `djoser services` shows it failed.

## scripts

```yaml
scripts:
  queue: php artisan queue:work --memory=512 --max-time=3600
  test: php artisan test {args}             # arguments go where {args} stands, or at the end
  dev: npm run dev
  deploy: "!git pull && composer install && php artisan migrate --force"
```

A command starts with one of Djoser's tools: `php`, `artisan`, `composer`, `node`, `npm`, `npx`, `mysql`, `mysqldump`, `mariadb`, `mariadb-dump`, `psql`, `pg_dump`, `mongosh` or `redis-cli`. A command that starts with `!` (in quotes) runs through `cmd`, so `git`, `&&` and pipes work, and `php`, `composer` and `npm` inside it are still the project's. Names use `a-z`, `0-9`, `_`, `-` and `:`.

## workers

```yaml
workers:
  - schedule                   # one, started by up
  - queue: 3                   # three of that script
  - dev:
      startup: false           # listed, but started only by: djoser workers start dev
  - mail:
      count: 2
      startup: false
```

Every name must be under `scripts:`. `startup` is true when left out, and a count goes from 1 to 16.

## Examples

### A large Laravel app

A shop with an admin and API subdomain, tenants on any subdomain, two databases, Redis, S3, mail, its own MySQL settings, and five kinds of background work.

```yaml
name: shop
domain: shop.localhost
aliases: [www, admin, api, "*"]
web-root: public
backups: D:/Backups/shop
services:
  php:
    version: 8.5
    extensions: [redis, imagick, xdebug]
    ini:
      memory_limit: 1G
      upload_max_filesize: 256M
      post_max_size: 256M
      max_execution_time: 300
      xdebug.mode: debug
      xdebug.start_with_request: trigger
  node: 22
  mysql:
    version: 8.4
    database: shop
    settings:
      max_connections: 500
      innodb_buffer_pool_size: 1G
      sql_mode: STRICT_TRANS_TABLES,NO_ZERO_DATE
  postgres:
    version: 17
    database: shop_reports
  redis:
    version: 8.4
    settings:
      maxmemory: 512mb
      maxmemory-policy: allkeys-lru
  rustfs:
    version: 1.0
    bucket: shop-media
  mailpit: 1.33
scripts:
  queue: php artisan queue:work redis --queue=high,default --memory=512 --max-time=3600
  mail: php artisan queue:work redis --queue=mail --memory=256 --max-time=3600
  schedule: php artisan schedule:work
  reverb: php artisan reverb:start
  dev: npm run dev
  build: npm run build
  test: php artisan test --parallel {args}
  fresh: php artisan migrate:fresh --seed
  deploy: "!git pull && composer install && php artisan migrate --force && npm run build"
workers:
  - queue: 3
  - mail
  - schedule
  - reverb
  - dev:
      startup: false
```

`up` serves `shop.localhost`, `www.`, `admin.`, `api.` and any `<tenant>.shop.localhost` from the same project, starts six worker processes, and leaves Vite until `djoser workers start dev`.

### Next.js

Djoser serves files from a folder; it does not yet stand in front of the Next.js server. Two ways work today, and the example uses both: a static export served by Djoser at `https://web.localhost`, and the dev server kept running as a worker at `http://localhost:3000`.

```powershell
djoser install node 22
djoser npx create-next-app@latest web
cd web
```

In `next.config.js`, set `output: 'export'` so `next build` writes a static site to `out`, then:

```powershell
djoser npm run build
djoser init --root out -y
```

```yaml
name: web
domain: web.localhost
web-root: out
services:
  node: 22
  postgres:
    version: 17
    database: web
  redis: 8.4
scripts:
  dev: npm run dev
  build: npm run build
  lint: npm run lint
  prisma: npx prisma {args}
workers:
  - dev
```

```powershell
djoser up                       # https://web.localhost serves out; the dev server runs on port 3000
djoser run prisma migrate dev
djoser logs dev -f
```

`DATABASE_URL=postgresql://postgres@127.0.0.1:5432/web` reaches the database; `djoser status` shows the port if it is not 5432. A version in `.nvmrc` works instead of `node:`.

### A plain HTML or PHP page

```powershell
cd D:\Sites\landing
djoser init -y
djoser up
```

```yaml
name: landing
domain: landing.localhost
web-root: .
```

A folder with only `index.html` gets no PHP. For PHP, add it:

```yaml
name: landing
domain: landing.localhost
web-root: .
services:
  php: 8.5
```
