# Commands

The helper scripts are thin shortcuts around Docker Compose:

- `./odoo.sh` for Linux, macOS and Git Bash on Windows
- `.\odoo.ps1` for Windows PowerShell

Both accept the same commands. Run `./odoo.sh help` for the list.

Anything that needs to run inside the container (install, test, backup...) is implemented once, in [`docker/odoo-docker.sh`](../docker/odoo-docker.sh), so it behaves the same on every operating system.

You do not have to use the scripts. Every command below shows its plain `docker compose` equivalent, run from the project folder. `$ODOO_DB` is the default database from `.env`.

## Stack

| Helper | Docker Compose |
|---|---|
| `up` | `docker compose up -d --build --wait` |
| `down` | `docker compose down` |
| `restart` | `docker compose restart odoo` |
| `logs [service]` | `docker compose logs -f --tail 200 odoo` |
| `status` | `docker compose ps` |
| `bash` | `docker compose exec odoo bash` |
| `tools` | `docker compose --profile tools up -d pgadmin` |
| `reset` | `docker compose --profile tools down -v` |

`up` also creates `.env` from `.env.example` on the first run, and creates the `addons/*` and `backups` folders. On Linux this matters: when Docker creates a missing folder for a mount, it is owned by `root`, and you then cannot clone into it.

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
| `scaffold <name>` | `docker compose exec odoo odoo-docker scaffold <name>` then `restart` |

### install / update

Runs `odoo -d <db> -i|-u <modules> --stop-after-init` in the running container, then restarts the server so it loads the new code. Installing into a database that does not exist yet creates it.

Use `update all` to update every installed module, for example after pulling new Odoo or Enterprise code.

### test

Creates a fresh database named `test_<modules>` (dropping the previous one), installs the modules into it, and runs their tests:

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

Creates `addons/custom/<name>` from Odoo's module template. On Linux the files are created with your user, not the container's, so you can edit them right away.

## Raw Odoo commands

For anything else, run the `odoo` command inside the container. The configuration file is already set, so database settings are picked up automatically:

```bash
docker compose exec odoo odoo --help
# Disable crons, outgoing mail servers, payment providers... in a copy of a production database
docker compose exec odoo odoo neutralize -d mydb
```
