# Start, stop and check on Odoo

The everyday commands. Docker Desktop (or the Docker service on Linux) must be running for all of them.

## Start Odoo

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh up` | `.\odoo.ps1 up` |

When it is ready, it prints the address to open, usually <http://localhost:8069>.

Also run `up` after changing `.env` or `requirements.txt`: it applies the changes.

## Stop Odoo

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh down` | `.\odoo.ps1 down` |

Your databases and files are kept. If you turn off the computer without running `down`, Odoo starts again by itself the next time Docker starts.

## Restart Odoo

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh restart` | `.\odoo.ps1 restart` |

Restart after you change Python code, edit `config/odoo.conf`, or add a module folder. It returns once Odoo answers again.

## See what is going on

**Status**: whether Odoo runs, its version, where it finds modules, and your databases:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh status` | `.\odoo.ps1 status` |

```text
Odoo version: 19.0
Odoo build:   19.0.20261004
Addons path:  /mnt/enterprise-addons,/mnt/custom-addons
Default DB:   odoo
Databases:    odoo
```

**Log**: what Odoo is doing, and the full error when something fails. It keeps showing new lines; press `Ctrl+C` to stop watching (Odoo keeps running):

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh logs` | `.\odoo.ps1 logs` |

The PostgreSQL log, if you need it:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh logs db` | `.\odoo.ps1 logs db` |

## Look inside the database

**Odoo shell**: Python with `env` ready, like a server action. Changes are discarded when you leave, unless you run `env.cr.commit()`. Type `exit()` to leave.

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh shell` | `.\odoo.ps1 shell` |

```python
>>> env['res.partner'].search_count([])
```

**SQL** with `psql`. Type `\q` to leave.

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh psql` | `.\odoo.ps1 psql` |

Both use the database `odoo`. For another one, add its name, e.g. `shell mydb`.

**pgAdmin**, a database tool in the browser:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh tools` | `.\odoo.ps1 tools` |

Open the address it prints, usually <http://localhost:5050>. The first start takes up to a minute. In the list on the left, open **Servers > Odoo**. When it asks for a password, enter `POSTGRES_PASSWORD` from `.env` (`odoo` by default).

**Your own database tool** (DBeaver, DataGrip...): connect to host `localhost`, port `5433` (`POSTGRES_PORT` in `.env`), user and password from `POSTGRES_USER` and `POSTGRES_PASSWORD` in `.env` (`odoo` / `odoo` by default).

**A terminal inside the Odoo container**, for anything else. Type `exit` to leave.

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh bash` | `.\odoo.ps1 bash` |

---

All commands at a glance: [Commands](commands.md). [Back to the list of guides](../README.md#what-do-you-want-to-do)
