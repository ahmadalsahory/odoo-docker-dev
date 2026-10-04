# odoo-docker

Run **Odoo 17, 18, 19 or 20** on your own machine with Docker, in **Community** or **Enterprise** edition, on Windows, macOS or Linux.

It is meant for local development and testing: write modules, try features, reproduce bugs. It is not a production deployment.

- One command to start, one URL to open
- Community out of the box. Enterprise is used automatically as soon as you add its source code
- Your modules in `addons/custom`, picked up without editing any config
- Helper commands for everyday tasks: install, update, test, shell, backup, restore
- Same commands on Windows (PowerShell) and Linux/macOS (bash)

> [!IMPORTANT]
> This repository does **not** contain Odoo Enterprise code, and you must never commit it.
> Enterprise is licensed under OEEL-1 and is only available to Odoo partners and subscribers.
> See [docs/enterprise.md](docs/enterprise.md).

## Requirements

| | Windows / macOS | Linux |
|---|---|---|
| Docker | [Docker Desktop](https://www.docker.com/products/docker-desktop/) | [Docker Engine](https://docs.docker.com/engine/install/) with the Compose plugin |
| Git | [git-scm.com](https://git-scm.com/downloads) | your package manager |

Check that Docker works: `docker compose version` should print `v2.x` or newer.

## Quick start

**1. Get the template**

Click **Use this template** on GitHub to create your own copy, or clone it directly:

```bash
git clone https://github.com/<your-account>/odoo-docker.git
cd odoo-docker
```

**2. (Enterprise only) Add the Enterprise source**

Skip this step for Community. Otherwise use the branch that matches your Odoo version:

```bash
git clone --branch 20.0 --depth 1 https://github.com/odoo/enterprise.git addons/enterprise
```

**3. Start Odoo**

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh up` | `.\odoo.ps1 up` |

The first start downloads about 1 GB of images and takes a few minutes. A `.env` file with the default settings is created for you.

> [!NOTE]
> If PowerShell says that running scripts is disabled, run this once and try again:
> `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`

**4. Create a database**

Open <http://localhost:8069> and fill in the form. The **Master Password** is `admin` (`ADMIN_PASSWORD` in `.env`).

**5. Stop when you are done**

`./odoo.sh down` or `.\odoo.ps1 down`. Your databases are kept for next time.

## Everyday commands

Use `./odoo.sh <command>` on Linux, macOS and Git Bash, or `.\odoo.ps1 <command>` in PowerShell.

| Command | What it does |
|---|---|
| `up` | Build and start everything (also applies changes to `.env` and `requirements.txt`) |
| `down` | Stop and remove the containers. Data is kept |
| `restart` | Restart Odoo, e.g. after changing Python code or `config/odoo.conf` |
| `logs` | Follow the Odoo log (`logs db` for PostgreSQL) |
| `status` | Show whether the containers are running and healthy |
| `install <modules> [db]` | Install modules, e.g. `install sale,crm` |
| `update <modules> [db]` | Update modules after changing their code or data |
| `test <modules>` | Run a module's tests in a fresh, throwaway database |
| `scaffold <name>` | Create a new module skeleton in `addons/custom` |
| `shell [db]` | Interactive Odoo Python shell (`env` is ready to use) |
| `psql [db]` | PostgreSQL command line |
| `dbs` | List databases |
| `backup [db]` | Save database and attachments to `backups/` as a zip |
| `restore <file> [db]` | Restore a zip from `backups/` as a new database |
| `bash` | Open a terminal inside the Odoo container |
| `tools` | Start pgAdmin at <http://localhost:5050> |
| `reset` | Delete the containers **and all data** of this project (asks first) |

`[db]` is optional and defaults to `ODOO_DB` in `.env` (`odoo`). Prefer plain Docker commands? See [docs/commands.md](docs/commands.md) for the equivalent of each one.

## Developing a module

```bash
./odoo.sh scaffold my_module       # creates addons/custom/my_module
./odoo.sh install my_module
```

Then, after each change:

| You changed | Run |
|---|---|
| Python files | `restart` |
| XML views, data files, `__manifest__.py`, security | `update my_module` |
| Files in `static/` (JavaScript, SCSS, OWL templates) | reload the page, ideally with `?debug=assets` in the URL |

Tip: with `ODOO_DEV_MODE=xml` in `.env`, view changes show up on page reload without an update. See [developer mode](docs/configuration.md#developer-mode).

Modules copied into `addons/custom` by hand work too. If the folder was empty when Odoo started, run `restart` once so Odoo notices it.

## Switching Odoo version

1. Set `ODOO_VERSION` in `.env` (`17`, `18`, `19` or `20`).
2. Enterprise only: check out the matching branch in `addons/enterprise` (e.g. `git -C addons/enterprise checkout 19.0`, after a full clone).
3. Run `up`.

Every version gets its own containers and data volumes (`odoo-19`, `odoo-20`...), so switching never breaks the databases of another version. To run two versions at the same time, use two copies of this template with different ports. See [docs/configuration.md](docs/configuration.md#running-several-instances).

> [!NOTE]
> Odoo officially supports the three latest major versions. Odoo 17 images are still published but it no longer gets standard support.

## Project structure

```text
odoo-docker/
├── addons/
│   ├── custom/            Your modules (committed)
│   ├── enterprise/        Odoo Enterprise source (never committed)
│   └── third_party/       OCA or other community modules (ignored by default)
├── backups/               Output of the backup command (ignored)
├── config/
│   ├── odoo.conf          Odoo server options
│   └── pgadmin-servers.json
├── docker/
│   ├── entrypoint.sh      Builds the final Odoo config at container start
│   └── odoo-docker.sh     The helper behind install, update, test, backup...
├── docs/                  Detailed guides
├── .env.example           All settings, documented. Copied to .env on first run
├── docker-compose.yml
├── Dockerfile             Official Odoo image + your extra Python packages
├── requirements.txt       Extra Python packages for your modules
├── odoo.sh                Helper for Linux, macOS and Git Bash
└── odoo.ps1               Helper for Windows PowerShell
```

## Documentation

- [Configuration](docs/configuration.md): `.env`, `odoo.conf`, Python packages, third-party addons, ports, developer mode, pgAdmin
- [Enterprise](docs/enterprise.md): getting the source, keeping it in sync, licensing rules
- [Commands](docs/commands.md): every helper command and its plain Docker equivalent
- [Troubleshooting](docs/troubleshooting.md): common problems and how to fix them

## License

The files in this repository are released under the [MIT License](LICENSE).

Odoo Community is licensed under LGPL-3 and is pulled from the [official Docker image](https://hub.docker.com/_/odoo). Odoo Enterprise is licensed under OEEL-1, is not included here, and must be obtained from Odoo S.A.

This project is not affiliated with or endorsed by Odoo S.A.
