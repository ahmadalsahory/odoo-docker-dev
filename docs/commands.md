# Commands

Reference of every helper command, and what it does with Docker. For step-by-step guides, see the [list of guides](../README.md#what-do-you-want-to-do).

Run each command with the script for your system, from the project folder:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh <command>` | `.\odoo.ps1 <command>` |

For example `./odoo.sh install sale` or `.\odoo.ps1 install sale`. Both scripts accept the same commands; `help` lists them.

`[db]` is optional and defaults to `ODOO_DB` in `.env` (`odoo`). Odoo must be running (`up`) for every command except `up`, `down`, `reset` and `help`.

## Overview

| Command | What it does | Guide |
|---|---|---|
| `up` | Build and start everything. Also applies changes to `.env` and `requirements.txt` | [Start, stop](start-stop.md) |
| `down` | Stop and remove the containers. Data is kept | [Start, stop](start-stop.md) |
| `restart` | Restart Odoo, e.g. after changing Python code or `config/odoo.conf` | [Start, stop](start-stop.md) |
| `logs [service]` | Follow the Odoo log (`logs db` for PostgreSQL) | [Start, stop](start-stop.md) |
| `status` | Containers, Odoo version, addons path and databases | [Start, stop](start-stop.md) |
| `bash` | Terminal inside the Odoo container | [Start, stop](start-stop.md) |
| `shell [db]` | Odoo Python shell, with `env` ready | [Start, stop](start-stop.md) |
| `psql [db]` | PostgreSQL command line | [Start, stop](start-stop.md) |
| `tools` | Start pgAdmin | [Start, stop](start-stop.md) |
| `dbs` | List databases | |
| `install <modules> [db]` | Install comma-separated modules, then restart. Creates the database if needed | [Create a module](develop-a-module.md) |
| `update <modules> [db]` | Update comma-separated modules (or `all`), then restart | [Create a module](develop-a-module.md) |
| `scaffold <name>` | Create a new module in `addons/custom`, then restart | [Create a module](develop-a-module.md) |
| `test <modules>` | Run module tests in a fresh throwaway database | [Run tests](run-tests.md) |
| `backup [db]` | Save database and attachments to `backups/` as a zip | [Back up and restore](backup-restore.md) |
| `restore <file> [db] [--neutralize]` | Restore a zip from `backups/` as a new database | [Back up and restore](backup-restore.md), [production copy](production-copy.md) |
| `reset` | Delete the containers **and all data** of the current version (asks first) | [Start over](start-over.md) |

## What each command runs

You do not have to use the scripts. Each command below shows its plain `docker compose` equivalent, run from the project folder.

| Command | Docker Compose |
|---|---|
| `up` | `docker compose up -d --build --wait` (see the checks below) |
| `down` | `docker compose down` |
| `restart` | `docker compose restart odoo` then `docker compose up -d --wait odoo` |
| `logs [service]` | `docker compose logs -f --tail 200 odoo` |
| `status` | `docker compose ps` then `docker compose exec odoo odoo-docker-dev info` |
| `bash` | `docker compose exec odoo bash` |
| `tools` | `docker compose --profile tools up -d pgadmin` |
| `reset` | `docker compose --profile tools down -v` |
| `install sale,crm [db]` | `docker compose exec odoo odoo-docker-dev install sale,crm [db]` then `restart` |
| `update sale,crm [db]` | `docker compose exec odoo odoo-docker-dev update sale,crm [db]` then `restart` |
| `test my_module` | `docker compose exec odoo odoo-docker-dev test my_module` |
| `shell [db]` | `docker compose exec odoo odoo-docker-dev shell [db]` |
| `psql [db]` | `docker compose exec odoo odoo-docker-dev psql [db]` |
| `dbs` | `docker compose exec odoo odoo-docker-dev dbs` |
| `backup [db]` | `docker compose exec odoo odoo-docker-dev backup [db]` |
| `restore <file> [db]` | `docker compose exec odoo odoo-docker-dev restore <file> [db]` |
| `scaffold <name>` | `docker compose exec -u "$(id -u):$(id -g)" odoo odoo-docker-dev scaffold <name>` then `restart` (on Windows, leave out `-u ...`) |

Everything that runs inside the container is written once, in [`docker/odoo-docker-dev.sh`](../docker/odoo-docker-dev.sh), so it behaves the same on every system.

### Checks before starting

Before starting, `up` does what plain `docker compose up` does not:

1. Checks that Docker is installed and running (every command does this).
2. Creates `.env` from `.env.example` if it is missing.
3. Checks the values in `.env`: `ODOO_VERSION` is a plain major version (`20`, not `20.0`), the ports are valid and different, and `BIND_ADDRESS` is an IP address.
4. Checks that `ODOO_PORT` and `POSTGRES_PORT` are free. If not, it names the program or container that uses them and suggests a free port. `tools` does the same for `PGADMIN_PORT`.
5. Creates the default `addons/*` and `backups` folders, and stops with an error if a custom `*_ADDONS_PATH` does not exist. Without this, Docker creates missing folders itself: empty, so Odoo silently starts without those modules, and on Linux owned by `root`, so you cannot clone into them.
6. On Linux, makes `backups/` writable for the container user. Without it, `backup` fails.

### Details

**`install` / `update`** run `odoo -d <db> -i|-u <modules> --stop-after-init` in the running container, then restart the server so it loads the new code. `install` into a database that does not exist yet creates it, with the login `admin` / password `admin`. `update` refuses to run on a database that does not exist and lists the existing ones.

**`test`** creates a fresh database named `test_<modules>`, dropping the previous one even if a browser tab still has it open, installs the modules into it, and runs their tests on a separate HTTP port. Browser tests (tours) need Chrome, which is not in the official image, so they are skipped.

**`backup` / `restore`** use Odoo's database manager, with the master password from `ADMIN_PASSWORD`, so they need `list_db = True` in `config/odoo.conf` (the default). The zips are the same format as its **Backup** button. A restored database gets a new UUID, so it cannot be confused with the original. `--neutralize` runs Odoo's neutralization on the restored copy: outgoing mail servers, scheduled actions, payment providers and other connections to the outside are turned off.

**`scaffold`** creates `addons/custom/<name>` from Odoo's module template, then restarts Odoo so the module can be installed right away. On Linux, it creates the files with your user rather than the container's, so you can edit them.

## Raw Odoo commands

For anything else, run the `odoo` command inside the container. The configuration file is already set, so database settings are picked up automatically:

```bash
docker compose exec odoo odoo --help
docker compose exec odoo odoo db --help          # database manager on the command line
docker compose exec odoo odoo neutralize -d mydb # neutralize an existing database
```

---

[Back to the list of guides](../README.md#what-do-you-want-to-do)
