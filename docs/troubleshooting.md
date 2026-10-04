# Troubleshooting

Start with the logs. Most problems explain themselves there:

```bash
./odoo.sh status     # are the containers running and healthy?
./odoo.sh logs       # Odoo log
./odoo.sh logs db    # PostgreSQL log
```

## Docker is not running

```text
failed to connect to the docker API ... dockerDesktopLinuxEngine
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

Start Docker Desktop (Windows and macOS) and wait until it says it is running. On Linux, run `sudo systemctl start docker`.

## Port already in use

```text
ports are not available: exposing port TCP 127.0.0.1:8069
Bind for 127.0.0.1:8069 failed: port is already allocated
```

Something else is using the port. Often it is another Odoo, either installed directly on your machine or from another copy of this template. Either stop it, or pick another port in `.env` and run `up` again:

```env
ODOO_PORT=8070
```

To see what is using the port:

| Windows (PowerShell) | Linux / macOS |
|---|---|
| `Get-Process -Id (Get-NetTCPConnection -LocalPort 8069).OwningProcess` | `sudo lsof -i :8069` |

The same applies to `POSTGRES_PORT` (5433), for example when PostgreSQL is installed on your machine as well.

## PowerShell: "running scripts is disabled on this system"

Windows blocks scripts by default. Allow scripts for your user once:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Or run a single command without changing anything: `powershell -ExecutionPolicy Bypass -File .\odoo.ps1 up`.

## My module does not appear

1. **Check the folder layout.** The module folder must be directly inside `addons/custom`, with a `__manifest__.py`: `addons/custom/my_module/__manifest__.py`.
2. **Restart.** If `addons/custom` was empty when Odoo started, it is not on the addons path yet. Run `./odoo.sh restart`, then check the `addons_path` line at the top of `./odoo.sh logs`.
3. **Update the Apps list.** In Odoo, turn on developer mode (`?debug=1`), then go to **Apps > Update Apps List**. The `install` command does this for you.
4. **Check the version.** The `version` in `__manifest__.py`, if it starts with a series such as `19.0.1.0.0`, must match the running Odoo version.

## Changes to my code are not visible

See the table in [Developing a module](../README.md#developing-a-module). In short: Python changes need `restart`, XML and data changes need `update <module>`.

## Odoo keeps restarting, or `up` says "container is unhealthy"

Read `./odoo.sh logs`. Common causes:

- **Enterprise branch does not match `ODOO_VERSION`.** See [docs/enterprise.md](enterprise.md).
- **A broken module in one of the addons folders**, for example a syntax error in a manifest. Fix it or move it out, then `restart`.
- **An `odoo.conf` change with a typo.** Undo it and `restart`.

## Everything is slow on Windows

Docker reads files from Windows drives (`C:\`, `D:\`) through a slow translation layer. With large folders such as Odoo Enterprise, page loads and module updates are noticeably slower.

For the best speed, keep the project inside WSL 2:

1. Install WSL 2 and Ubuntu: `wsl --install` in an administrator PowerShell.
2. In Docker Desktop, enable **Settings > Resources > WSL integration** for Ubuntu.
3. Open Ubuntu, clone the project there (for example into `~/odoo-docker`) and use `./odoo.sh`.
4. Edit the files from Windows with VS Code: run `code .` inside the project in Ubuntu.

This also makes `ODOO_DEV_MODE=reload` work.

## Permission denied on Linux

The Odoo container runs as user `odoo` (uid 101). It only needs to **read** your addons. The exception is `backups/`, which `up` makes writable for it.

- **Cannot clone into `addons/enterprise`.** Docker created the folder as `root` because it did not exist at start. Fix it with `sudo chown -R "$USER": addons` and clone again.
- **Odoo cannot read your modules.** Make sure they are readable by others: `chmod -R a+rX addons/custom`.

## `/bin/bash^M: bad interpreter` or `$'\r': command not found`

A script was saved with Windows line endings. The repository forces the correct endings through `.gitattributes`, so this only happens with copies made another way. Fix it with `git add --renormalize .`, or by saving the file with LF line endings in your editor.

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

This only affects the current `ODOO_VERSION` (or `PROJECT_NAME`). Your code, `.env` and `backups/` stay untouched.

To also remove the images and free disk space: `docker image prune` and `docker builder prune`.
