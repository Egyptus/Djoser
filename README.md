<div align="center">

<img src="assets/logo.png" alt="Djoser" width="128" height="128">

# Djoser

**A native, Windows-first developer environment manager for PHP and Laravel.**

Per-project PHP runtimes, local HTTPS sites and services, without Docker, WSL or touching the PHP already on your machine.

![Platform](https://img.shields.io/badge/platform-Windows%20x64-0078D4)
![C++](https://img.shields.io/badge/C%2B%2B-23-00599C)
[![Release](https://img.shields.io/github/v/release/Egyptus/Djoser?include_prereleases)](https://github.com/Egyptus/Djoser/releases)

[Download for Windows](https://github.com/Egyptus/Djoser/releases/latest)

</div>

> Djoser is at an early stage. Expect changes between versions.

## Quick start

Install Djoser from the [latest release](https://github.com/Egyptus/Djoser/releases/latest). It installs for your user only and needs no administrator rights. Then, inside your project:

```powershell
djoser init
djoser up
```

`init` asks a few questions and writes a `djoser.yaml`. `up` downloads what the project needs, starts it, and prints its address:

```text
shop is up on PHP 8.5.12 (6 workers, ports 19000-19005)
  https://shop.localhost
```

## Describe a project

Everything a project needs lives in one file, so it starts the same way on any machine:

```yaml
name: shop
domain: shop.localhost
web-root: public
services:
  php:
    version: 8.5.12
    extensions: [redis, imagick, xdebug]
  mysql: 8.4.13
  node: 22.23.4
```

Edit the file and run `djoser up` to apply it. `djoser status` shows what changed since the last `up`.

Databases are shared between projects by default, with one database per project, on `127.0.0.1` only. To give a project its own server and data folder:

```yaml
services:
  mysql:
    version: 8.4.13
    data: D:/Data/shop-mysql
```

## A Laravel project, start to finish

### 1. Get PHP and Composer

```powershell
djoser install php 8.5
djoser install composer latest
```

The first version of each becomes your default. Djoser prints a folder to add to `PATH`; add it once, then open a new terminal so `php` and `composer` work anywhere.

### 2. Create the project

```powershell
composer create-project laravel/laravel shop
cd shop
```

For an existing project, just `cd` into its folder.

### 3. Describe it

```powershell
djoser init --name shop --domain shop.localhost --root public --php 8.5 -y
```

Leave out the options and `init` asks for each one. Then open `djoser.yaml` and list what the project needs:

```yaml
name: shop
domain: shop.localhost
web-root: public
services:
  php:
    version: 8.5
    extensions: [redis]
  mysql: 8.4
  redis: 8.4
  node: 22.23.4
```

`extensions: [redis]` is the PHP extension that talks to Redis. `redis: 8.4` is the Redis server itself. You need both.

### 4. Start it

```powershell
djoser up
```

The first run downloads everything and may take a few minutes. It ends with the address and the connection details:

```text
shop is up on PHP 8.5.12 (6 workers, ports 19000-19005)
  https://shop.localhost
Note: mysql on 127.0.0.1:3306, database shop, user root, no password
Note: redis on 127.0.0.1:6379 (community Windows build)
```

Once per machine, trust the local certificate so browsers accept the site:

```powershell
djoser trust
```

### 5. Connect Laravel

Djoser does not edit `.env`. Copy the values `up` printed:

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

The database is named after the project, with `-` turned into `_`. To choose the name, add `database: my_db` under `mysql` in `djoser.yaml`. Projects using the same Redis version share one server, so give each project its own `REDIS_PREFIX`.

### 6. Prepare the app

```powershell
djoser artisan migrate
npm install
npm run build
```

Open `https://shop.localhost`.

### 7. Run the background work

Each of these stays open, so give it its own terminal:

```powershell
djoser artisan queue:work
djoser artisan schedule:work
npm run dev
```

### Day to day

| To | Run |
|---|---|
| Stop or start the project | `djoser down`, `djoser up` |
| See each service, its state, port and database, and what changed in `djoser.yaml` | `djoser status` |
| Run any Artisan command | `djoser artisan <command>` |
| Open the project's database | `mysql` |
| Back up the database | `mysqldump --result-file=backup.sql` |
| Open the project's Redis | `redis-cli` |
| Add a PHP extension | `djoser install php-ext imagick`, then `djoser up` |
| Change PHP | `djoser use php 8.4`, then `djoser up` |
| Run a tool from another folder | `djoser exec shop mysql` |
| See every running project | `djoser ps` |
| Forget the project; files and data stay | `djoser remove` |

## Commands

| Command | What it does |
|---|---|
| `djoser init` | Create `djoser.yaml` for a project |
| `djoser up` / `down` | Start or stop the project |
| `djoser remove` | Stop it and forget it; files and data stay |
| `djoser status` | This project's services, their state, ports and database, and pending changes |
| `djoser ps` | Every running project |
| `djoser exec <project> <tool>` | Run a tool inside a project, from anywhere |
| `djoser install <service> <version>` | Download a version |
| `djoser use <service> <version>` | Choose a version for this project; `--env` sets the default |
| `djoser list <service>` | What can be installed |
| `djoser runtimes` | What is installed |
| `djoser uninstall <service> <version>` | Remove a version; databases stay |
| `djoser install php-ext <name>` | Add a PHP extension to this project |
| `djoser trust` | Trust the local certificate for HTTPS |
| `djoser doctor` | Check this machine and explain how to fix problems |

## Your tools, in any folder

`php`, `composer`, `node`, `npm`, `npx`, `mysql`, `mysqldump` and `redis-cli` use the version your project asks for, and your default version elsewhere. Inside a running project, `mysql` and `redis-cli` connect to that project's services by themselves.

Add the folder Djoser tells you about to `PATH` once. Djoser never edits `PATH` for its tools.

## What runs today

| | |
|---|---|
| PHP | Official builds, one pool per version and set of extensions |
| PHP extensions | redis, imagick, memcached, xdebug, sqlsrv, pdo_sqlsrv, apcu, mongodb, amqp, and what ships with PHP |
| Composer, Node.js | Any folder, per-project versions |
| MySQL | 8.0, 8.4, 9.7 |
| Redis | 7.2, 7.4, 8.4, 8.10, from a community Windows build |
| Sites | Caddy, HTTPS on `*.localhost` |

Valkey, MariaDB, PostgreSQL, MongoDB, RustFS and Cloudflare tunnels are planned.

## This repository

It holds the installer in [Releases](https://github.com/Egyptus/Djoser/releases) and the tables in [`catalog/`](catalog), which list the versions Djoser may download and the SHA-256 of each file. Djoser reads them so that new versions can be added without a new release.
