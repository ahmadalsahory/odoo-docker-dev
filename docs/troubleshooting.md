# Fix an error

Find the message you see in the table, or the problem you have below it. For an error that is not listed, the Odoo log usually explains it:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh logs` | `.\odoo.ps1 logs` |

## Find your message

| Message | Section |
|---|---|
| `running scripts is disabled on this system` | [PowerShell blocks the script](#powershell-running-scripts-is-disabled-on-this-system) |
| `Docker is not running`, `failed to connect to the docker API`, `Cannot connect to the Docker daemon` | [Docker is not running](#docker-is-not-running) |
| `Docker is not installed`, `docker: command not found`, `docker is not recognized` | [Docker is not installed](#docker-is-not-installed) |
| `Port ... is used by ...`, `port is already allocated`, `ports are not available` | [Port already in use](#port-already-in-use) |
| `... must be a port number`, `... are both set to ...`, `BIND_ADDRESS ...` | [Wrong value in `.env`](#wrong-value-in-env) |
| `ODOO_VERSION must be a major version` | [Wrong value in `.env`](#wrong-value-in-env) |
| `..._ADDONS_PATH=... does not exist` | [Wrong value in `.env`](#wrong-value-in-env) |
| `Odoo is not running. Start it first` | [Odoo is not running](#odoo-is-not-running-start-it-first) |
| `container ... is unhealthy`, Odoo keeps restarting | [Odoo keeps restarting](#odoo-keeps-restarting-or-up-says-container-is-unhealthy) |
| `[odoo-docker-dev] WARNING` in the Odoo log | [Warnings in the log](#warnings-in-the-log) |
| `ImportError: cannot import name ...` from an Enterprise module | [Enterprise module fails to install](#enterprise-module-fails-to-install) |
| `cannot reach https://nightly.odoo.com/...`, `checksum mismatch` | [Enterprise module fails to install](#enterprise-module-fails-to-install) |
| `backup failed`, `restore failed`, `Access Denied` | [Backup or restore fails](#backup-or-restore-fails) |
| `the input device is not a TTY` | [Git Bash: not a TTY](#git-bash-the-input-device-is-not-a-tty) |
| `/bin/bash^M: bad interpreter`, `$'\r': command not found` | [Windows line endings](#binbashm-bad-interpreter-or-r-command-not-found) |
| `Permission denied` (Linux) | [Permission denied on Linux](#permission-denied-on-linux) |

Problems without a message: [my module does not appear](#my-module-does-not-appear), [my changes are not visible](#changes-to-my-code-are-not-visible), [everything is slow on Windows](#everything-is-slow-on-windows).

## PowerShell: "running scripts is disabled on this system"

Windows blocks scripts by default. Allow them for your user, once:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Or run a single command without changing anything: `powershell -ExecutionPolicy Bypass -File .\odoo.ps1 up`.

## Docker is not running

```text
Error: Docker is not running. Start Docker Desktop, wait until it says it is running, then try again.
failed to connect to the docker API ... dockerDesktopLinuxEngine
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

On Windows and macOS, start **Docker Desktop** and wait until it says **Engine running**. On Linux, run `sudo systemctl start docker`. Then run your command again.

## Docker is not installed

Install it as described in [Run Odoo for the first time](getting-started.md#1-install-docker-and-git). If you just installed it, close the terminal and open a new one.

## Port already in use

`up` and `tools` check their ports before starting. When one is taken, they say what holds it and suggest a free port:

```text
Error: Port 8069 (ODOO_PORT) is used by python (process 7252), Windows service 'odoo-server-19.0'.
  - Stop the service, as administrator: Stop-Service 'odoo-server-19.0'. Set it to Manual in services.msc so it does not start with Windows again.
  - Use another port: set ODOO_PORT=8070 in .env (free right now), then run the command again.
```

With plain `docker compose`, Docker reports the same problem in one of these forms:

```text
Bind for 127.0.0.1:8069 failed: port is already allocated
ports are not available: exposing port TCP 127.0.0.1:8069 -> ... bind: An attempt was made to access a socket in a way forbidden by its access permissions.
ports are not available: exposing port TCP 127.0.0.1:8069 -> ... bind: Only one usage of each socket address (protocol/network address/port) is normally permitted.
```

The same applies to `POSTGRES_PORT` (default 5433) and `PGADMIN_PORT` (default 5050). You have two choices: stop what uses the port, or [use another port](ports-and-network.md#change-a-port). Usually the port is held by one of these:

**Odoo installed directly on Windows.** The official Windows installer runs Odoo as a service, named like `odoo-server-19.0`, that starts with Windows and uses port 8069. Stop it in **services.msc** and set its startup type to **Manual**, or use another port.

**This project, on another Odoo version.** This happens when `ODOO_VERSION` was changed without running `down` first. The message names the container, for example `odoo-20-odoo-1`. Stop that version by its name, the part before `-odoo-1`:

```bash
docker compose -p odoo-20 down
```

**Another copy of this project**, or another Odoo or PostgreSQL on your machine. Stop it, or use another port. To run two copies on purpose, see [Run two Odoo setups at the same time](several-instances.md).

**A range Windows reserves for itself.** Hyper-V, WSL and Docker Desktop reserve blocks of ports, and the blocks can change after a restart. List them with `netsh int ipv4 show excludedportrange protocol=tcp` and use a port outside them.

To see what uses a port yourself (replace `8069` with your port):

| Windows (PowerShell) | Linux / macOS |
|---|---|
| `Get-Process -Id (Get-NetTCPConnection -LocalPort 8069).OwningProcess` | `sudo lsof -i :8069` |

## Wrong value in `.env`

`up` checks `.env` before starting, and names the setting that is wrong:

| Message | Fix |
|---|---|
| `ODOO_VERSION must be a major version such as 20 (no .0)` | Write just the number: `ODOO_VERSION=19`, not `19.0` |
| `ODOO_PORT must be a port number between 1 and 65535` | Use a number in that range |
| `ODOO_PORT and POSTGRES_PORT are both set to ...` | Give each port its own number |
| `BIND_ADDRESS must be an IP address` | Use `127.0.0.1`, or `0.0.0.0` to open Odoo to your network. Names such as `localhost` do not work here |
| `BIND_ADDRESS=... is not an address of this computer` | Same as above |
| `ENTERPRISE_ADDONS_PATH=... does not exist` (or another `_ADDONS_PATH`) | The folder is missing or the path has a typo. On Windows, use forward slashes: `C:/odoo/enterprise` |

All settings are explained in [Configuration](configuration.md#env-reference).

## "Odoo is not running. Start it first"

Every command except `up`, `down` and `reset` needs Odoo running. Start it:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh up` | `.\odoo.ps1 up` |

## Odoo keeps restarting, or `up` says "container is unhealthy"

Odoo started but stopped with an error. The log says which one:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh logs` | `.\odoo.ps1 logs` |

Common causes:

- **Enterprise is not the same version as Odoo.** See [Add Odoo Enterprise](enterprise.md).
- **A broken module** in one of the addons folders, for example a syntax error in a `__manifest__.py`. Fix it or move it out, then `./odoo.sh restart` (PowerShell: `.\odoo.ps1 restart`).
- **A typo in `config/odoo.conf`.** Undo the change, then `./odoo.sh restart` (PowerShell: `.\odoo.ps1 restart`).
- **`POSTGRES_USER` or `POSTGRES_PASSWORD` changed** after the first start. PostgreSQL keeps the original ones. Put them back. To really change them: `backup`, `reset`, `up`, `restore`.

## Warnings in the log

Lines starting with `[odoo-docker-dev] WARNING` at the top of the Odoo log point at a setup problem:

**`ODOO_VERSION in .env is '...' but the image runs Odoo ...`**
`ODOO_VERSION` must be just the major version (`20`, not `20.0`), and `ODOO_TAG`, if set, must belong to the same version.

**`The Enterprise folder is on branch 19.0 but Odoo is 20.0`**
Enterprise and Odoo must be the same version. Clone the right branch, or change `ODOO_VERSION`. See [Add Odoo Enterprise](enterprise.md#1-download-enterprise).

**`Enterprise changed since Odoo was built for it`** or **`Odoo was not matched to your Enterprise version`**
Enterprise was updated (`git pull`) and Odoo was restarted without `up`, or Odoo was started with plain `docker compose`. Run `up`. See [Update Odoo and Enterprise](update.md#2-start-odoo-with-the-new-code).

**`The Enterprise folder looks like a full Odoo source tree`**
`addons/enterprise` holds a copy of all of Odoo instead of the `odoo/enterprise` repository. See [common mistakes](enterprise.md#common-mistakes).

## Enterprise module fails to install

```text
File "/mnt/enterprise-addons/account_accountant/models/account_bank_statement.py", line 14, in <module>
ImportError: cannot import name '_ignore_tax_lock_date' from 'odoo.addons.account.models.account_move_line'
```

Your Enterprise code and the Odoo code in the image are from different days. Run `up`: it installs the Odoo build matching your Enterprise (see [Update Odoo and Enterprise](update.md#2-start-odoo-with-the-new-code)). If the error stays, `up` could not do that, and printed why:

- **`Git is not installed` / `cannot read the Enterprise commit`**: `up` reads the Enterprise date with Git. Install Git, and keep `addons/enterprise` a Git clone (a downloaded copy has no date to read).
- **`cannot reach https://nightly.odoo.com/...`**: the Odoo build is downloaded from there. Check the internet connection or proxy, then run `up` again.
- **`checksum mismatch`**: the download was damaged. Run `up` again.

## Backup or restore fails

- **The master password was changed in the browser.** The commands use `ADMIN_PASSWORD` from `.env`. Run `./odoo.sh restart` (PowerShell: `.\odoo.ps1 restart`): it sets the master password back to the one in `.env`. To change it for good, change `ADMIN_PASSWORD` in `.env` and run `up`.
- **`list_db = False`** in `config/odoo.conf` turns off the database manager that backups rely on. Set it back to `True` and `restart`.
- **Restore says the database already exists.** Give a new name: `restore file.zip new_name`.

## Git Bash: "the input device is not a TTY"

Interactive commands (`shell`, `psql`, `bash`) need a real terminal. `odoo.sh` uses `winpty` in Git Bash when it is available. If you still see this message, use PowerShell with `odoo.ps1`, or run Git Bash inside Windows Terminal.

## `/bin/bash^M: bad interpreter` or `$'\r': command not found`

`odoo.sh` was saved with Windows line endings. A fresh `git clone` prevents this, so it usually comes from a copy made another way, or an editor that converted the file. The simplest fix is to clone the project again. Or save `odoo.sh` with LF line endings: in VS Code, click `CRLF` in the status bar and choose `LF`.

## Permission denied on Linux

The Odoo container runs as user `odoo` (uid 101). It only needs to **read** your addons. The exception is `backups/`, which `up` makes writable for it.

- **Cannot clone into `addons/enterprise`.** Docker created the folder as `root` because the stack was started with plain `docker compose`. Fix it with `sudo chown -R "$USER": addons` and clone again.
- **Odoo cannot read your modules.** Make them readable by others: `chmod -R a+rX addons/custom`.
- **`backup` fails with a write error.** Run `chmod a+rwx backups` (`up` does this for you).

## My module does not appear

1. **Check the folder layout.** The module folder must be directly inside `addons/custom`, with a `__manifest__.py`: `addons/custom/my_module/__manifest__.py`.
2. **Restart.** If `addons/custom` was empty when Odoo started, it is not on the addons path yet. Run `./odoo.sh restart` (PowerShell: `.\odoo.ps1 restart`), then check with `status` that the addons path includes `/mnt/custom-addons`.
3. **Check the database.** `install my_module` without a database name uses `odoo`. If your database has another name, add it: `install my_module mydb`.
4. **Check the version.** If the `version` in `__manifest__.py` starts with an Odoo version, such as `19.0.1.0.0`, it must match the running Odoo.

## Changes to my code are not visible

Python changes need `restart`. XML views, data and `__manifest__.py` changes need `update <module>`. JavaScript and CSS need a page reload with `?debug=assets`. See [Create a module and see your changes](develop-a-module.md#3-change-it-and-see-the-result).

## Everything is slow on Windows

Docker reads files from Windows drives (`C:\`, `D:\`) through a slow translation layer. With large folders such as Odoo Enterprise, pages and module updates are noticeably slower.

For the best speed, keep the project inside WSL 2:

1. Install WSL 2 and Ubuntu: run `wsl --install` in a PowerShell opened as administrator.
2. In Docker Desktop, turn on **Settings > Resources > WSL integration** for Ubuntu.
3. Open Ubuntu, clone the project there (for example into `~/odoo-docker-dev`) and use `./odoo.sh`.
4. Edit the files from Windows with VS Code: run `code .` inside the project in Ubuntu.

This also makes `ODOO_DEV_MODE=reload` work.

## Still stuck?

[Delete everything and start over](start-over.md) fixes most broken setups. Back up the databases you need first.

---

[Back to the list of guides](../README.md#what-do-you-want-to-do)
