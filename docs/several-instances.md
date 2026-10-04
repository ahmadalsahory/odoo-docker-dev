# Run two Odoo setups at the same time

One project folder runs one Odoo. To run two at once, for example Odoo 18 and Odoo 20, or two client projects on the same version, use a second copy of the project with its own ports.

If you only want to go back and forth between versions, not run them together, [switching versions](switch-version.md) is simpler.

## 1. Make a second copy of the project

Clone it again into another folder, next to the first one:

```bash
git clone https://github.com/<owner>/odoo-docker-dev.git odoo-docker-dev-18
cd odoo-docker-dev-18
```

## 2. Give it its own settings

Create its `.env`:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `cp .env.example .env` | `Copy-Item .env.example .env` |

Open the new `.env` and change these lines, so the two setups do not use the same ports:

```env
ODOO_VERSION=18
ODOO_PORT=8070
POSTGRES_PORT=5434
PGADMIN_PORT=5051
```

**If both copies use the same `ODOO_VERSION`**, also give this one its own name. Otherwise both copies share the same databases, and starting one replaces the other:

```env
PROJECT_NAME=client-b
```

For Enterprise, this copy needs its own `addons/enterprise` on its version, see [Add Odoo Enterprise](enterprise.md).

## 3. Start it

In the new folder:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh up` | `.\odoo.ps1 up` |

**When it works**, it prints its own address: `Odoo is ready at http://localhost:8070`. The first copy keeps running at <http://localhost:8069>.

Each copy is controlled from its own folder: run `down`, `logs`, `install`... in the folder of the setup you mean.

## Logged out all the time?

Browsers share the login between `localhost:8069` and `localhost:8070`, so logging in to one logs you out of the other. Open the second one as <http://127.0.0.1:8070> instead: to the browser, that is a different site, with its own login.

---

[Back to the list of guides](../README.md#what-do-you-want-to-do)
