# Configuration

Reference of every setting. For step-by-step guides, see the [list of guides](../README.md#what-do-you-want-to-do).

On this page, `up`, `restart` and the other commands mean `./odoo.sh <command>` on Linux, macOS and Git Bash, or `.\odoo.ps1 <command>` in Windows PowerShell.

There are two places to configure things:

- **`.env`** for everything about the containers: Odoo version, passwords, ports, folders. It is created from [`.env.example`](../.env.example), and every option is explained there.
- **[`config/odoo.conf`](../config/odoo.conf)** for Odoo server options such as log level, workers or SMTP.

After changing `.env`, run `up`. After changing `odoo.conf`, run `restart`.

The one exception is `ODOO_VERSION`: run `down` **before** changing it. See [Switch to another Odoo version](switch-version.md).

Related guides: [ports and network](ports-and-network.md), [ready-made modules](third-party-modules.md), [Python packages](python-packages.md), [two setups at the same time](several-instances.md).

## `.env` reference

| Variable | Default | Purpose |
|---|---|---|
| `ODOO_VERSION` | `20` | Odoo major version: `17`, `18`, `19` or `20`, without `.0` |
| `ODOO_TAG` | same as `ODOO_VERSION` | Pin an exact image build. Must belong to `ODOO_VERSION`, e.g. `20.0-20260926` ([tags](https://hub.docker.com/_/odoo/tags)) |
| `ADMIN_PASSWORD` | `admin` | Master password of the database manager |
| `ODOO_DB` | `odoo` | Database used by helper commands when none is given |
| `ODOO_DEV_MODE` | empty | [Developer mode](#developer-mode) flags |
| `POSTGRES_VERSION` | `16` | PostgreSQL major version (13 to 17) |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` | `odoo` / `odoo` | Database credentials, applied when the database volume is first created |
| `BIND_ADDRESS` | `127.0.0.1` | Network interface Odoo listens on. PostgreSQL and pgAdmin always use `127.0.0.1` |
| `ODOO_PORT` | `8069` | Odoo in your browser |
| `POSTGRES_PORT` | `5433` | PostgreSQL for desktop tools (DBeaver, pgAdmin...) |
| `PGADMIN_PORT` | `5050` | pgAdmin, when started with `tools` |
| `ENTERPRISE_ADDONS_PATH` | `./addons/enterprise` | Folder with the Enterprise source |
| `THIRD_PARTY_ADDONS_PATH` | `./addons/third_party` | Folder with third-party modules |
| `CUSTOM_ADDONS_PATH` | `./addons/custom` | Folder with your modules |
| `PROJECT_NAME` | `odoo` | Prefix of the Compose project. Containers and volumes are named `<PROJECT_NAME>-<ODOO_VERSION>` |

**Writing values.** Use `NAME=value`, with no spaces around `=`. Keep passwords to letters, digits, `-` and `_`. Docker Compose treats `$` as the start of a variable (write `$$` for a literal `$`), and spaces or quotes can be cut off along the way.

**Database credentials.** PostgreSQL applies `POSTGRES_USER` and `POSTGRES_PASSWORD` only when it creates its data volume. Changing them afterwards makes Odoo fail to connect. To change them: `backup`, `reset`, `up`, `restore`.

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

Run `status` to see the resulting path. To take full control, set `addons_path` in `config/odoo.conf`. It then replaces the generated one. Use the paths inside the container: `/mnt/enterprise-addons`, `/mnt/third-party-addons` and `/mnt/custom-addons`.

The same rule applies to `admin_passwd`, `db_host`, `db_port`, `db_user` and `db_password`. They come from `.env` unless `config/odoo.conf` sets them.

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

## Email

There is no mail server in this stack. Emails that Odoo sends fail and stay in the outgoing queue (**Settings > Technical > Emails**), which keeps a local copy from emailing real people. A copy of a production database brings its own mail servers along, which is why it must be [neutralized](production-copy.md). To test sending, configure an outgoing mail server in Odoo, or set `smtp_*` options in `config/odoo.conf`.

## pgAdmin

How to open it: [Look inside the database](start-stop.md#look-inside-the-database). pgAdmin runs without a login screen, and only your own computer can reach it.

The server list is read from [`config/pgadmin-servers.json`](../config/pgadmin-servers.json) only the first time pgAdmin starts. If you use another `POSTGRES_USER`, edit `Username` in that file **before** the first `tools`, or change it later in pgAdmin itself.

---

[Back to the list of guides](../README.md#what-do-you-want-to-do)
