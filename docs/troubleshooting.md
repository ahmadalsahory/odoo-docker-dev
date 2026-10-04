# Troubleshooting

Start here. Most problems explain themselves:

```bash
./odoo.sh status     # containers, Odoo version, addons path, databases
./odoo.sh logs       # Odoo log
./odoo.sh logs db    # PostgreSQL log
```

Lines starting with `[odoo-docker-dev] WARNING` at the top of the Odoo log point at a setup problem. They are explained [below](#warnings-in-the-log).

## Docker is not running

```text
failed to connect to the docker API ... dockerDesktopLinuxEngine
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

Start Docker Desktop (Windows and macOS) and wait until it says it is running. On Linux, run `sudo systemctl start docker`.

## "Odoo is not running. Start it first"

Every command except `up`, `down` and `reset` needs the stack running. Run `up` first.

## Port already in use

```text
ports are not available: exposing port TCP 127.0.0.1:8069
Bind for 127.0.0.1:8069 failed: port is already allocated
```

Something else is using the port. Usually it is one of these:

**Another version of this template that is still running.** This happens when `ODOO_VERSION` was changed without running `down` first. The helpers only see the version currently in `.env`, so stop the old one by name:

```bash
docker ps --format "{{.Names}}"     # e.g. odoo-20-odoo-1, odoo-20-db-1
docker compose -p odoo-20 down      # the part before "-odoo-1"
```

**Another Odoo or PostgreSQL**, installed directly on your machine or from another copy of this template. Stop it, or pick another port in `.env` and run `up` again:

```env
ODOO_PORT=8070
```

To see what is using a port:

| Windows (PowerShell) | Linux / macOS |
|---|---|
| `Get-Process -Id (Get-NetTCPConnection -LocalPort 8069).OwningProcess` | `sudo lsof -i :8069` |

The same applies to `POSTGRES_PORT` (5433) and `PGADMIN_PORT` (5050).

## PowerShell: "running scripts is disabled on this system"

Windows blocks scripts by default. Allow scripts for your user once:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Or run a single command without changing anything: `powershell -ExecutionPolicy Bypass -File .\odoo.ps1 up`.

## Git Bash: "the input device is not a TTY"

Interactive commands (`shell`, `psql`, `bash`) need a real terminal. `odoo.sh` uses `winpty` automatically in Git Bash when it is available. If you still see this message, use PowerShell with `odoo.ps1`, or run Git Bash inside Windows Terminal.

## My module does not appear

1. **Check the folder layout.** The module folder must be directly inside `addons/custom`, with a `__manifest__.py`: `addons/custom/my_module/__manifest__.py`.
2. **Restart.** If `addons/custom` was empty when Odoo started, it is not on the addons path yet. Run `restart`, then check the addons path with `status`.
3. **Check the database.** `install my_module` without a database name uses `ODOO_DB` (`odoo`). If your database has another name, pass it: `install my_module mydb`.
4. **Update the Apps list.** In Odoo, turn on developer mode (`?debug=1`), then go to **Apps > Update Apps List**. The `install` command does this for you.
5. **Check the version.** The `version` in `__manifest__.py`, if it starts with a series such as `19.0.1.0.0`, must match the running Odoo version.

## Changes to my code are not visible

See the table in [Developing a module](../README.md#developing-a-module). In short: Python changes need `restart`, XML and data changes need `update <module>`.

## Odoo keeps restarting, or `up` says "container is unhealthy"

Read `./odoo.sh logs`. Common causes:

- **Enterprise does not match `ODOO_VERSION`.** See [docs/enterprise.md](enterprise.md).
- **A broken module in one of the addons folders**, for example a syntax error in a manifest. Fix it or move it out, then `restart`.
- **An `odoo.conf` change with a typo.** Undo it and `restart`.
- **Database credentials changed** after the first start (`POSTGRES_USER` / `POSTGRES_PASSWORD`). PostgreSQL keeps the original ones. Put them back, or see [database credentials](configuration.md#env-reference).

## Warnings in the log

**`ODOO_VERSION in .env is '...' but the image runs Odoo ...`**
`ODOO_VERSION` must be just the major version (`20`, not `20.0`), and `ODOO_TAG`, if set, must belong to the same version.

**`The Enterprise folder is on branch 19.0 but Odoo is 20.0`**
The Enterprise branch and Odoo must be the same version. Clone the right branch, or change `ODOO_VERSION`. See [docs/enterprise.md](enterprise.md#getting-the-source).

**`The Enterprise folder looks like a full Odoo source tree`**
`addons/enterprise` holds a copy of all of Odoo instead of the `odoo/enterprise` repository. See [common mistakes](enterprise.md#common-mistakes).

## Everything is slow on Windows

Docker reads files from Windows drives (`C:\`, `D:\`) through a slow translation layer. With large folders such as Odoo Enterprise, page loads and module updates are noticeably slower.

For the best speed, keep the project inside WSL 2:

1. Install WSL 2 and Ubuntu: `wsl --install` in an administrator PowerShell.
2. In Docker Desktop, enable **Settings > Resources > WSL integration** for Ubuntu.
3. Open Ubuntu, clone the project there (for example into `~/odoo-docker-dev`) and use `./odoo.sh`.
4. Edit the files from Windows with VS Code: run `code .` inside the project in Ubuntu.

This also makes `ODOO_DEV_MODE=reload` work.

## Permission denied on Linux

The Odoo container runs as user `odoo` (uid 101). It only needs to **read** your addons. The exception is `backups/`, which `up` makes writable for it.

- **Cannot clone into `addons/enterprise`.** Docker created the folder as `root` because it did not exist when the stack was started with plain `docker compose`. Fix it with `sudo chown -R "$USER": addons` and clone again.
- **Odoo cannot read your modules.** Make sure they are readable by others: `chmod -R a+rX addons/custom`.
- **`backup` fails with a write error.** Run `chmod a+rwx backups` (`up` does this for you).

## `/bin/bash^M: bad interpreter` or `$'\r': command not found`

`odoo.sh` was saved with Windows line endings. The repository's `.gitattributes` prevents this for fresh clones, so it usually comes from a copy made another way, or an editor that converted the file. The simplest fix is to clone the repository again. Alternatively, save `odoo.sh` with LF line endings in your editor (in VS Code: click `CRLF` in the status bar and choose `LF`).

## Backup or restore fails

- **Master password changed in the web interface.** The helper sends the master password from the container's config file, and a password changed from the web is stored there only as a hash. Run `restart`: the config is rebuilt from `ADMIN_PASSWORD` in `.env` on every start.
- **`list_db = False`** in `config/odoo.conf` turns off the database manager that backups rely on.
- **Restore says the database already exists.** Give a new name: `./odoo.sh restore file.zip new_name`.

## Start over

To delete all databases and attachments of this project and start clean:

```bash
./odoo.sh reset
./odoo.sh up
```

This only affects the current `ODOO_VERSION` (and `PROJECT_NAME`). Your code, `.env` and `backups/` stay untouched.

To free disk space used by images you no longer need: `docker image ls` to see them, `docker image rm <name>` to remove one (for example `odoo:17` and `odoo-17-odoo`), or `docker image prune -a` to remove every image not used by a container. `docker builder prune` clears the build cache.
