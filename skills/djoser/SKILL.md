---
name: djoser
description: Work on a PHP, Laravel, Node.js or static project on Windows that Djoser runs. Use when the project has a djoser.yaml file, when the user mentions Djoser or the djoser command, or when you need to run php, composer, artisan, node, npm or a database client, start or stop the site, add a service (MySQL, MariaDB, PostgreSQL, MongoDB, Redis, S3, Mailpit), manage queue workers, read logs, back up a database or fix a local HTTPS site.
---

# Djoser

Djoser is a developer environment for Windows. A project's `djoser.yaml` says what it needs (PHP or Node.js version, databases, Redis, S3, mail, scripts, background workers), and `djoser up` makes it true. Each project gets its own versions and a site at `https://<name>.localhost`. A background service, the Engine, runs everything for the current user, with no administrator rights.

- Full command list: [references/commands.md](references/commands.md)
- Every `djoser.yaml` key, with examples: [references/djoser-yaml.md](references/djoser-yaml.md)

## Rules

1. **Run tools through Djoser.** Use `djoser php`, `djoser artisan`, `djoser composer`, `djoser node`, `djoser npm`, `djoser npx`, `djoser mysql`, `djoser psql` and the others. They pick the project's version, its PHP extensions and `ini:` settings, and connect to the project's database. Never call a PHP or Node found elsewhere on the machine, and never install one with another tool. Plain `php` or `npm` is the same only when the user installed the tools on `PATH`; `djoser which php` tells you.
2. **Change the environment through `djoser.yaml`.** To add a service, change a version, add a script or a worker, edit `djoser.yaml`, then run `djoser up`, then check `djoser status`. Do not start servers by hand, and do not edit files in Djoser's home folder (`%LOCALAPPDATA%\Djoser`).
3. **Exit codes.** `0` success, `1` error (read the message), `3` the Engine is not running. On `3`, run `djoser engine start` and try again.
4. **Your shell has no terminal, so Djoser never asks you a question.** A question Djoser would ask a person has a fixed answer instead:
   - `djoser env sync` only prints how `.env` differs and changes nothing. Show the user the differences and ask them to run `djoser env sync` themselves, or edit `.env` yourself if they agree.
   - `djoser trust` and the certificate step of `up` need the user; tell them to run `djoser trust` if the browser warns.
   - `djoser init` takes the defaults; pass `--name`, `--domain`, `--root`, `--php` to choose.
   - `djoser db restore`, `djoser uninstall` of a version in use, and `djoser self-update` stop with an error unless given `-y`.
5. **Ask the user before** `djoser remove` (it does not ask without a terminal), `djoser down` of a running project, any `-y` that replaces or removes something (`db restore -y`, `uninstall -y`, `deploy -y`, `self-update -y`), and `djoser deploy` when a `deploy.sh` already exists.
6. **Do not run commands that wait for Ctrl+C**: `djoser share`, `djoser logs <worker> -f`, `djoser status -w`, and a dev server such as `djoser npm run dev`. Use `djoser logs <worker>` (add `-n 200` for more), or start a worker with `djoser workers start dev`.
7. **Data is safe, keep it so.** `down`, `remove` and `uninstall` never delete databases or project files, and Djoser never deletes a backup. Before a destructive migration (`migrate:fresh`, a dropped column), run `djoser db backup` first.
8. **Inside the project, Djoser writes only `djoser.yaml`, `.env` (only after the user types yes in `env sync`) and `deploy.sh` (only from `djoser deploy`).** Commands like `use`, `install php-ext`, `config php` and `workers ... --save` edit `djoser.yaml` for you, keeping its comments.

## Everyday work

```powershell
djoser init --name shop --domain shop.localhost --root public --php 8.5   # write djoser.yaml (once)
djoser up                     # start the site, servers and workers; downloads what is missing
djoser status                 # address, services with ports and databases, workers, failed jobs, changes since up
djoser artisan migrate        # any artisan command
djoser composer require vendor/package
djoser npm install
djoser run                    # the scripts in djoser.yaml; djoser run <name> [arguments] runs one
djoser workers                # background workers; workers start|stop|restart <name>
djoser logs queue             # the last 50 lines of a worker's log
djoser jobs                   # failed Laravel queue jobs; jobs retry <id|all>
djoser down                   # stop the project
```

From outside the project folder, add `--project <name>` or use `djoser exec <project> <tool> [arguments]`. `djoser ps -a` lists projects.

## Adding a service

Add it under `services:` in `djoser.yaml` and run `djoser up`:

```yaml
services:
  php:
    version: 8.5
    extensions: [redis]
  mysql: 8.4
  redis: 8.4
  mailpit: 1.34
```

`up` prints how to reach each service (host `127.0.0.1`, port, database, user). For Laravel, the matching `.env` lines come from `djoser env sync` (rule 4). Servers are shared between projects, one database per project, named after the project with `-` turned into `_`. MySQL and MariaDB use user `root` with no password, PostgreSQL user `postgres` with no password.

Versions you can install: `djoser list php`, `djoser list mysql`, and so on. PHP extensions: `djoser list extensions`, then `djoser install php-ext <name>` inside the project.

## Scripts and workers

```yaml
scripts:
  queue: php artisan queue:work --memory=512 --max-time=3600
  schedule: php artisan schedule:work
  dev: npm run dev
  test: php artisan test {args}
  deploy: "!git pull && composer install"   # ! runs through cmd
workers:
  - queue: 2
  - schedule
  - dev:
      startup: false
```

A script starts with a Djoser tool (`php`, `artisan`, `composer`, `node`, `npm`, `npx`, a database client) or with `!` for a `cmd` line. `workers:` lists scripts that `up` keeps running and restarts when they stop.

## When something is wrong

| Sign | What to do |
|---|---|
| Exit code 3 | `djoser engine start`, then run the command again |
| The site will not open, or a service is missing | `djoser status`, then `djoser services` for the last error of a failed one |
| A worker keeps restarting | `djoser logs <worker>` |
| Laravel cannot reach the database, Redis or mail | `djoser env sync` and show the user the differences |
| A port is taken | `djoser ports`, then `djoser ports move <service>` (writes `port:` and runs `up`) |
| The site address has a port such as `:8443` | Another program holds port 443; `djoser ports` shows which |
| The browser warns about the certificate | Ask the user to run `djoser trust` and restart the browser |
| A tool runs the wrong version | `djoser which <tool>` says which version and where it was chosen |
| Anything else | `djoser doctor` |

`djoser <command> --help` lists a command's options.
