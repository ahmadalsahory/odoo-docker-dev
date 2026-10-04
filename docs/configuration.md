# Configuration

There are two places to configure things:

- **`.env`** for everything about the containers: Odoo version, passwords, ports, folders. It is created from [`.env.example`](../.env.example) on the first `up`, and every option is explained there.
- **[`config/odoo.conf`](../config/odoo.conf)** for Odoo server options such as log level, workers or SMTP.

After changing `.env`, run `up`. After changing `odoo.conf`, run `restart`.

## `.env` reference

| Variable | Default | Purpose |
|---|---|---|
| `ODOO_VERSION` | `20` | Odoo major version: `17`, `18`, `19` or `20` |
| `ODOO_TAG` | same as `ODOO_VERSION` | Pin an exact image build, e.g. `20.0-20260926` ([tags](https://hub.docker.com/_/odoo/tags)) |
| `ADMIN_PASSWORD` | `admin` | Master password of the database manager |
| `ODOO_DB` | `odoo` | Database used by helper commands when none is given |
| `ODOO_DEV_MODE` | empty | [Developer mode](#developer-mode) flags |
| `POSTGRES_VERSION` | `16` | PostgreSQL major version (13 to 17) |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` | `odoo` / `odoo` | Database credentials |
| `BIND_ADDRESS` | `127.0.0.1` | Which network interface the ports listen on |
| `ODOO_PORT` | `8069` | Odoo in your browser |
| `POSTGRES_PORT` | `5433` | PostgreSQL for desktop tools (DBeaver, pgAdmin...) |
| `PGADMIN_PORT` | `5050` | pgAdmin, when started with `tools` |
| `ENTERPRISE_ADDONS_PATH` | `./addons/enterprise` | Folder with the Enterprise source |
| `THIRD_PARTY_ADDONS_PATH` | `./addons/third_party` | Folder with third-party modules |
| `CUSTOM_ADDONS_PATH` | `./addons/custom` | Folder with your modules |
| `PROJECT_NAME` | `odoo-<ODOO_VERSION>` | Docker Compose project name. Containers and volumes are named after it |

> [!NOTE]
> PostgreSQL 18 images store data in a different folder and are not supported by this template yet. Changing `POSTGRES_VERSION` on an existing project does not upgrade the data either: back up, `reset`, then restore.

## How the addons path is built

You never edit `addons_path` by hand. Each time Odoo starts, it scans these folders, in this order:

1. `addons/enterprise`
2. `addons/third_party`
3. `addons/custom`

A folder is added when it contains modules. Folders that contain **repositories of modules** one level down are added too, so this works:

```text
addons/third_party/
├── web/                   ← OCA repository, added to the path
│   ├── web_responsive/
│   └── web_timeline/
└── server-tools/          ← another repository, added too
```

The resulting path is printed at the top of the log (`./odoo.sh logs`). To take full control, set `addons_path` in `config/odoo.conf`. It then replaces the generated one. Use the paths inside the container: `/mnt/enterprise-addons`, `/mnt/third-party-addons` and `/mnt/custom-addons`.

The same rule applies to `admin_passwd`, `db_host`, `db_port`, `db_user` and `db_password`. They come from `.env` unless `config/odoo.conf` sets them.

## Third-party modules

Clone or copy them into `addons/third_party`, matching your Odoo version:

```bash
git clone --branch 20.0 --depth 1 https://github.com/OCA/web.git addons/third_party/web
./odoo.sh restart
```

`addons/third_party` is ignored by Git by default, because these are usually separate repositories. To commit them with your project, remove the `addons/third_party/*` lines from `.gitignore`.

## Extra Python packages

If a module needs a Python package that is not in the Odoo image, add it to [`requirements.txt`](../requirements.txt) and run `up`. The image is rebuilt with the package installed.

```text
pandas==2.2.3
```

Pin versions so everyone on your team gets the same build.

## Developer mode

`ODOO_DEV_MODE` passes `--dev` to the Odoo server. It takes a comma-separated list:

| Value | Effect |
|---|---|
| `xml` | Read views from the XML files, so view changes show up without an update |
| `qweb` | Break into the debugger on `t-debug` in QWeb templates |
| `werkzeug` | Show an interactive debugger in the browser on server errors |
| `reload` | Restart the server automatically when Python files change |
| `all` | All of the above |

`ODOO_DEV_MODE=xml` is a good everyday choice.

`reload` relies on file change notifications. Those do not reach containers from folders on a Windows drive, so it only works on Linux, or on Windows when the project lives inside WSL 2.

This is the server's developer mode. The developer mode of the web interface is turned on separately, by adding `?debug=1` to the URL.

## Running several instances

Each copy of this template is one Odoo instance. To run more than one at the same time, for example Odoo 18 and 20, or two projects on the same version:

1. Make a second copy of the template in another folder.
2. In its `.env`, change `ODOO_PORT`, `POSTGRES_PORT` and `PGADMIN_PORT` (e.g. `8070`, `5434`, `5051`).
3. If both copies use the same `ODOO_VERSION`, also give them different `PROJECT_NAME` values. Otherwise they share containers and data.

## Reaching Odoo from other devices

By default the ports only listen on `127.0.0.1`, so nothing outside your machine can connect. To open Odoo on a phone or another computer on your network, set `BIND_ADDRESS=0.0.0.0`, change `ADMIN_PASSWORD` to something stronger, run `up`, and browse to `http://<your-computer-ip>:8069`.

## Email

There is no mail server in this stack. Emails that Odoo sends fail and stay in the outgoing queue (**Settings > Technical > Emails**), which keeps a local copy from emailing real people. To test sending, configure an outgoing mail server in Odoo, or set `smtp_*` options in `config/odoo.conf`.

## pgAdmin

```bash
./odoo.sh tools
```

pgAdmin opens at <http://localhost:5050> without a login, and already has a server named **Odoo**. When it asks, the database password is `POSTGRES_PASSWORD` (`odoo` by default). If you changed `POSTGRES_USER`, update `Username` in [`config/pgadmin-servers.json`](../config/pgadmin-servers.json) as well.

You can also use any desktop client on `localhost:5433`.
