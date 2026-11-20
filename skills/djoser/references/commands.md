# Djoser commands

Every command and option of `djoser`, from `djoser <command> --help`.

Inside a project folder, commands act on that project. `--project <name>` picks another one from anywhere, `--no-color` prints plain text, and `djoser <command> --help` lists a command's options. A command that needs the Engine offers to start it.

## Projects

| Command | What it does |
|---|---|
| `djoser init` | Ask the questions and write `djoser.yaml` in this folder |
| `djoser init <folder>` | The same for another folder |
| `djoser init --name shop --domain shop.localhost --root public --php 8.5` | Answer from the command line; any you leave out are asked |
| `djoser init -y` | Take every default without asking |
| `djoser up` | Start everything `djoser.yaml` asks for, downloading what is missing; again after an edit, apply it |
| `djoser down` | Stop the project's site, servers it alone uses, and workers |
| `djoser status` | Its address, services, workers, memory, failed jobs, and what changed in `djoser.yaml` |
| `djoser status -w` | The same, redrawn every 2 seconds until Ctrl+C |
| `djoser ps` | Running projects with their address, PHP and services |
| `djoser ps -a` | Stopped projects too |
| `djoser projects` | Every project Djoser knows, with its folder |
| `djoser remove` | Stop this project and forget it; files and data stay |
| `djoser remove <name> -y` | Another project, without asking |
| `djoser exec <project> <tool> [arguments]` | Run a tool inside a project from anywhere, such as `djoser exec shop artisan migrate` |
| `djoser which <tool>` | Which version a tool runs here, where it was chosen, and its path |
| `djoser config php` | List the project's PHP settings |
| `djoser config php memory_limit=1G,upload_max_filesize=200M` | Change them; a running project's PHP restarts |
| `djoser config php memory_limit=` | Remove one |
| `djoser env sync` | Compare `.env` with what Djoser runs, and update it after a typed `y` |
| `djoser deploy` | Write `deploy.sh` for an Ubuntu server (experimental); `--path <file\|folder>` elsewhere, `-y` replaces without asking |

## Tools

Each runs with the project's version, from any folder of the project, and passes everything after it to the tool.

| Command | What it does |
|---|---|
| `djoser php [arguments]` | PHP, with the project's extensions and `ini:` settings |
| `djoser artisan [arguments]` | `php artisan` in a Laravel project, such as `djoser artisan migrate --seed` |
| `djoser composer [arguments]` | Composer with the project's PHP |
| `djoser node`, `npm`, `npx` | Node.js tools with the project's version |
| `djoser mysql`, `mariadb`, `psql`, `mongosh`, `redis-cli` | Connect to the project's server and database by themselves |
| `djoser mysqldump`, `mariadb-dump`, `pg_dump` | Dump the project's database |

Name a host or port yourself, and the connection Djoser adds is left out. With the tools on `PATH` (an installer option), plain `php`, `composer`, `node` and the others do the same.

## Scripts and workers

| Command | What it does |
|---|---|
| `djoser run` | List the scripts in `djoser.yaml`; for a Laravel project without any, offer to add six |
| `djoser run <name> [arguments]` | Run one in the project's folder, such as `djoser run test --filter=OrderTest` |
| `djoser workers` | Every worker, its state, restarts and log |
| `djoser workers start <name>` | Start a worker, such as `dev`, until the next `up` |
| `djoser workers stop <name>` | Stop it until the next `up`; `queue` means every queue worker, `queue-2` one |
| `djoser workers restart <name>` | Stop and start it |
| `djoser workers start <name> --save` | Also write `startup: true` to `djoser.yaml` |
| `djoser workers stop <name> --save` | Also write `startup: false` |
| `djoser logs` | List the workers and their log files |
| `djoser logs <worker>` | The last 50 lines of its log |
| `djoser logs <worker> -n 200` | More lines |
| `djoser logs <worker> -f` | Keep printing new lines until Ctrl+C |
| `djoser jobs` | The newest 50 failed queue jobs of a Laravel project |
| `djoser jobs retry <id>` | Run one again |
| `djoser jobs retry all` | Run them all again |

## Databases

| Command | What it does |
|---|---|
| `djoser db backup` | One file per database of the project (MySQL, MariaDB, PostgreSQL, MongoDB) |
| `djoser db backup --service mysql` | Only one server |
| `djoser db list` | The project's databases and its backups, newest first |
| `djoser db restore` | The newest backup of each database, after backing up the current data and a typed `y` |
| `djoser db restore <file>` | A file from `db list`, or its full path |
| `djoser db restore --service postgres -y` | One server, without asking |
| `djoser tool db` | Open HeidiSQL on the project's database (MySQL, MariaDB or PostgreSQL) |

## Sites

| Command | What it does |
|---|---|
| `djoser trust` | Trust Djoser's local certificate for this user, so browsers accept `https://` sites |
| `djoser share` | A temporary public address for the running site through Cloudflare, until Ctrl+C |
| `djoser ports` | Every port Djoser keeps, what it is for, and whether Djoser or another program holds it |
| `djoser ports move <service>` | Give the project's server the first free port after its usual one, through `port:` in `djoser.yaml` |
| `djoser ports move mysql 3307` | That port |

## Versions

| Command | What it does |
|---|---|
| `djoser list php` | PHP versions you can install; also `node`, `composer`, `mysql`, `mariadb`, `postgres`, `mongodb`, `redis`, `rustfs`, `mailpit` |
| `djoser list php --all` | Archived PHP builds too |
| `djoser list extensions` | PHP extensions Djoser can download for this project's PHP |
| `djoser install php 8.5` | The newest 8.5 patch; `8.5.12` an exact one |
| `djoser install php 8.3.10 --unverified` | An archived build with no published hash |
| `djoser install node 22`, `composer latest`, `mysql 8.4`, `postgres 17`... | Any service the same way |
| `djoser install php-ext redis` | A PHP extension; inside a project it is also added to `djoser.yaml` |
| `djoser install caddy`, `heidisql`, `cloudflared`, `mongosh`, `mongodb-tools` | A helper program ahead of time |
| `djoser add php C:\php` | Use a PHP already on this machine, where it is |
| `djoser use php 8.5` | Choose it for this project, writing the exact version to `djoser.yaml` |
| `djoser use php 8.5 --env` | The version used outside projects; any service the same way |
| `djoser update php` | Move this project to the newest patch of its PHP line, such as 8.5.12 to 8.5.14 |
| `djoser update php --env` | The same for the version used outside projects |
| `djoser runtimes` | Everything installed, and which is the default |
| `djoser uninstall php 8.5.12` | Remove a version; for a database server, offer a backup first |
| `djoser uninstall mysql 8.4.3 -y` | Without asking; data folders stay |

## Djoser itself

| Command | What it does |
|---|---|
| `djoser doctor` | Check this machine, say whether a newer Djoser is out, and explain how to fix what is wrong |
| `djoser self-update` | Install the newest release after a `[Y/n]`, checked against its SHA-256 |
| `djoser self-update --check` | Only say whether there is one |
| `djoser self-update -y` | Without asking |
| `djoser engine start` / `stop` / `status` | Control the background service; other commands start it when needed |
| `djoser services` | Every process Djoser runs, with its state, port and restarts |
| `djoser operations` | Recent downloads, backups and checks |
| `djoser operations cancel <id>` | Stop one |
| `djoser -v` | The version |

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success |
| `1` | Error; the message says what went wrong |
| `3` | The Engine is not running. At a terminal Djoser offers to start it; without one, run `djoser engine start` |

A tool such as `djoser php` or `djoser artisan` returns the tool's own exit code.

## Without a terminal

When input or output is not a terminal (scripts, agents, pipes), Djoser asks nothing:

| Command | Without a terminal |
|---|---|
| Any command needing the Engine | Exits `3` instead of offering to start it |
| `djoser init` | Takes the defaults, or the values given as options |
| `djoser env sync` | Prints the differences and changes nothing |
| `djoser trust`, the certificate step of `up` | Prints a note and changes nothing |
| `djoser run` in a Laravel project without scripts | Does not add the six Laravel scripts |
| `djoser remove` | Removes without asking: ask the user first |
| `djoser db restore`, `djoser self-update` | Stop with an error unless given `-y` |
| `djoser uninstall` of a version a project uses | Stops with an error unless given `-y` |
| `djoser deploy` when `deploy.sh` exists | Leaves it and exits `1` unless given `-y` |
