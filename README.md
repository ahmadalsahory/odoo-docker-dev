# odoo-docker-dev

Run **Odoo 17, 18, 19 or 20** on your own machine with Docker, in **Community** or **Enterprise** edition, on Windows, macOS or Linux.

It is meant for local development and testing: write modules, try features, reproduce bugs.

> [!WARNING]
> **Not for production.** Do not use this project to run a live Odoo on a server. Its settings are chosen for convenience on your own machine, and are unsafe anywhere else:
>
> - Known default passwords (`admin` for the database manager, `odoo` for PostgreSQL).
> - The database manager is open, so anyone who reaches Odoo can download or delete databases.
> - pgAdmin has no login.
> - Odoo runs as a single process, without HTTPS, automatic backups or a mail server.

- One command to start, one URL to open
- Community out of the box. Enterprise is used automatically as soon as you add its source code
- Your modules in `addons/custom`, picked up without editing any config
- Helper commands for everyday tasks: install, update, test, shell, backup, restore
- Same commands on Windows (PowerShell) and Linux/macOS (bash)

> [!IMPORTANT]
> This repository does **not** contain Odoo Enterprise code, and you must never commit it.
> Enterprise is licensed under OEEL-1 and is only available to Odoo partners and subscribers.
> See [Add Odoo Enterprise](docs/enterprise.md).

## What do you want to do?

**New here? Start with [Run Odoo for the first time](docs/getting-started.md).** Every page below is a list of steps with commands you can copy, what you should see, and what to do when something else happens.

### Get started

- [Run Odoo for the first time](docs/getting-started.md): install Docker, get this project, open Odoo (Community)
- [Add Odoo Enterprise](docs/enterprise.md): to a new setup, or to a Community setup that is already running

### Everyday work

- [Start, stop and check on Odoo](docs/start-stop.md): start, stop, restart, logs, status, look inside the database
- [Create a module and see your changes](docs/develop-a-module.md)
- [Add OCA or other ready-made modules](docs/third-party-modules.md)
- [Add a Python package a module needs](docs/python-packages.md)
- [Run a module's tests](docs/run-tests.md)
- [Back up and restore a database](docs/backup-restore.md)
- [Work on a copy of a production database](docs/production-copy.md): safely, without sending emails to real customers

### Change the setup

- [Switch to another Odoo version](docs/switch-version.md)
- [Run two Odoo setups at the same time](docs/several-instances.md)
- [Change ports, or open Odoo from your phone](docs/ports-and-network.md)
- [Update Odoo and Enterprise to the latest fixes](docs/update.md)
- [Delete everything and start over](docs/start-over.md)

### Something went wrong

- [Fix an error](docs/troubleshooting.md): look up the message you see

## Reference

For when you want the details rather than steps:

- [All commands](docs/commands.md), and what each one does with Docker
- [All settings](docs/configuration.md): `.env`, `config/odoo.conf`, how modules are found, developer mode

## Project structure

```text
odoo-docker-dev/
├── addons/
│   ├── custom/            Your modules (committed)
│   ├── enterprise/        Odoo Enterprise source (never committed)
│   └── third_party/       OCA or other ready-made modules (ignored by default)
├── backups/               Backup zips (ignored)
├── config/
│   ├── odoo.conf          Odoo server options
│   └── pgadmin-servers.json
├── docker/
│   ├── entrypoint.sh      Builds the final Odoo config at container start
│   └── odoo-docker-dev.sh The helper behind install, update, test, backup...
├── docs/                  The guides linked above
├── .env.example           All settings, documented. Copied to .env on first run
├── docker-compose.yml
├── Dockerfile             Official Odoo image + your extra Python packages
├── requirements.txt       Extra Python packages for your modules
├── odoo.sh                Helper for Linux, macOS and Git Bash
└── odoo.ps1               Helper for Windows PowerShell
```

## License

The files in this repository are released under the [MIT License](LICENSE).

Odoo Community is licensed under LGPL-3 and is pulled from the [official Docker image](https://hub.docker.com/_/odoo). Odoo Enterprise is licensed under OEEL-1, is not included here, and must be obtained from Odoo S.A.

This project is not affiliated with or endorsed by Odoo S.A.
