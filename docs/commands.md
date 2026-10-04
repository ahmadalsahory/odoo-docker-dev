# Commands

The helper scripts are thin shortcuts around Docker Compose:

- `./odoo.sh` for Linux, macOS and Git Bash on Windows
- `.\odoo.ps1` for Windows PowerShell

Both accept the same commands. Run `./odoo.sh help` for the list.

Anything that needs to run inside the container (install, test, backup...) is implemented once, in [`docker/odoo-docker.sh`](../docker/odoo-docker.sh), so it behaves the same on every operating system.

You do not have to use the scripts. Every command below shows its plain `docker compose` equivalent, run from the project folder.

## Stack

| Helper | Docker Compose |
|---|---|
| `up` | `docker compose up -d --build --wait` (see the extra steps below) |
| `down` | `docker compose down` |
| `restart` | `docker compose restart odoo` then `docker compose up -d --wait odoo` |
| `logs [service]` | `docker compose logs -f --tail 200 odoo` |
| `status` | `docker compose ps` then `docker compose exec odoo odoo-docker info` |
| `bash` | `docker compose exec odoo bash` |
| `tools` | `docker compose --profile tools up -d pgadmin` |
| `reset` | `docker compose --profile tools down -v` |

Before starting, `up` also does what plain `docker compose up` does not:

1. Creates `.env` from `.env.example` if it is missing.
2. Checks that `ODOO_VERSION` is a plain major version (`20`, not `20.0`).
3. Creates the default `addons/*` and `backups` folders, and stops with an error if a custom `*_ADDONS_PATH` does not exist. Without this, Docker creates missing folders itself: empty, so Odoo silently starts without those modules, and on Linux owned by `root`, so you cannot clone into them.
4. On Linux, makes `backups/` writable for the container user (`chmod a+rwx backups`). Without it, `backup` fails.

The second command of `restart` waits until Odoo answers again, so the next command does not hit a server that is still starting.

## Odoo

| Helper | Docker Compose |
|---|---|
| `install sale,crm [db]` | `docker compose exec odoo odoo-docker install sale,crm [db]` then `restart` |
| `update sale,crm [db]` | `docker compose exec odoo odoo-docker update sale,crm [db]` then `restart` |
| `test my_module` | `docker compose exec odoo odoo-docker test my_module` |
| `shell [db]` | `docker compose exec odoo odoo-docker shell [db]` |
| `psql [db]` | `docker compose exec odoo odoo-docker psql [db]` |
| `dbs` | `docker compose exec odoo odoo-docker dbs` |
| `backup [db]` | `docker compose exec odoo odoo-docker backup [db]` |
| `restore <file> [db]` | `docker compose exec odoo odoo-docker restore <file> [db]` |
| `scaffold <name>` | `docker compose exec -u "$(id -u):$(id -g)" odoo odoo-docker scaffold <name>` then `restart` (on Windows, leave out `-u ...`) |

### install / update

Runs `odoo -d <db> -i|-u <modules> --stop-after-init` in the running container, then restarts the server so it loads the new code.

`install` into a database that does not exist yet creates it, with the login `admin` / password `admin`, and prints a message saying so. `update` refuses to run on a database that does not exist and lists the existing ones.

Use `update all` to update every installed module, for example after pulling new Odoo or Enterprise code.

### test

Creates a fresh database named `test_<modules>` (dropping the previous one, even if a browser tab still has it open), installs the modules into it, and runs their tests:

```bash
./odoo.sh test my_module
./odoo.sh test my_module,my_other_module
```

Your normal databases are not touched. Browser tests (tours) need Chrome, which is not in the official image, so they are skipped.

### shell

Opens an interactive Python shell with `env` ready:

```python
>>> env['res.partner'].search_count([])
>>> env.cr.commit()   # changes are rolled back on exit unless you commit
```

### backup / restore

Backups are zip files with the database and its attachments (filestore), the same format as the **Backup** button of the database manager at `/web/database/manager`. They work in both directions: a zip made by the helper can be restored from the web page, and the other way round.

```bash
./odoo.sh backup                                   # backs up ODOO_DB
./odoo.sh backup mydb
./odoo.sh restore mydb_20260101_120000.zip         # restores as ODOO_DB, if that name is free
./odoo.sh restore mydb_20260101_120000.zip copy1   # restores under another name
```

Put zips you want to restore into `backups/` first. A restored database gets a new UUID, so it cannot be confused with the original (for example by the subscription check).

Both commands use the master password (`ADMIN_PASSWORD`) and need `list_db = True` in `config/odoo.conf`, which is the default.

### scaffold

Creates `addons/custom/<name>` from Odoo's module template, then restarts Odoo so the module can be installed right away. On Linux, the helper creates the files with your user rather than the container's (that is what `-u "$(id -u):$(id -g)"` does above), so you can edit them.

## Raw Odoo commands

For anything else, run the `odoo` command inside the container. The configuration file is already set, so database settings are picked up automatically:

```bash
docker compose exec odoo odoo --help
# Disable crons, outgoing mail servers, payment providers... in a copy of a production database
docker compose exec odoo odoo neutralize -d mydb
```
