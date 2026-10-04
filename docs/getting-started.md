# Run Odoo for the first time

At the end of this page, Odoo Community runs on your machine and you are logged in to your first database. It takes about 15 minutes, most of it waiting for downloads.

For Enterprise, do this page first, then [Add Odoo Enterprise](enterprise.md).

## 1. Install Docker and Git

| | Windows / macOS | Linux |
|---|---|---|
| Docker | [Docker Desktop](https://www.docker.com/products/docker-desktop/) | [Docker Engine](https://docs.docker.com/engine/install/) with the Compose plugin |
| Git | [git-scm.com](https://git-scm.com/downloads) | Your package manager, e.g. `sudo apt install git` |

On Windows, the Docker Desktop installer may ask to install WSL 2 and restart the computer. Accept both.

Start Docker Desktop and wait until it says **Engine running**. Then open a terminal (on Windows: **PowerShell**) and check that Docker works:

```bash
docker compose version
```

You should see `Docker Compose version v2.20` or newer. If you see `command not found` or `is not recognized`, Docker is not installed correctly, or the terminal was open before the installation: close it and open a new one.

## 2. Get this project

```bash
git clone https://github.com/ahmadalsahory/odoo-docker-dev.git
cd odoo-docker-dev
```

Every command in these guides is run from this `odoo-docker-dev` folder.

## 3. Choose the Odoo version

The project runs **Odoo 20** unless you choose otherwise. To keep 20, skip to step 4.

For another version, create your settings file:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `cp .env.example .env` | `Copy-Item .env.example .env` |

Open `.env` in any text editor and change this line to `17`, `18`, `19` or `20` (just the number, without `.0`):

```env
ODOO_VERSION=20
```

Leave everything else as it is. If you plan to add Enterprise later, remember this number: Enterprise must be the same version.

## 4. Start Odoo

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh up` | `.\odoo.ps1 up` |

The first start downloads about 1 GB and takes a few minutes. Later starts take seconds.

**When it works**, the last line is:

```text
Odoo is ready at http://localhost:8069
```

**If it stops with an error instead:**

| You see | What to do |
|---|---|
| `running scripts is disabled on this system` (PowerShell) | Run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` once, then try again |
| `Docker is not running` | Start Docker Desktop, wait until it says **Engine running**, then try again |
| `Port 8069 (ODOO_PORT) is used by ...` | Another program already uses that port, often an Odoo installed directly on Windows. The message names it and suggests a free port. See [Port already in use](troubleshooting.md#port-already-in-use) |
| `container ... is unhealthy` | Odoo started but crashed. See [Odoo keeps restarting](troubleshooting.md#odoo-keeps-restarting-or-up-says-container-is-unhealthy) |

Anything else: look up the message in [Fix an error](troubleshooting.md).

## 5. Create your first database

Open the address printed by `up`, usually <http://localhost:8069>. Odoo shows a form to create a database. Fill it in:

| Field | Value |
|---|---|
| Master Password | `admin` |
| Database Name | `odoo` |
| Email and Password | The login you want for this database, e.g. `admin` / `admin` |
| Language, Country, Phone Number | Anything. Country sets up local taxes and accounting |
| Demo Data | Tick it if you want sample customers, products and orders to play with |

Click **Create database**. After a minute or two you are logged in.

Why `odoo` as the name: the helper commands (`install`, `update`, `backup`...) use the database named `odoo` when you do not give a name. With another name, you add it to each command, e.g. `install sale mydb`.

## 6. Stop when you are done

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh down` | `.\odoo.ps1 down` |

Your databases are kept. Next time, run `up` again (step 4) and open the same address.

## What next

- [Add Odoo Enterprise](enterprise.md)
- [Create a module and see your changes](develop-a-module.md)
- [Start, stop and check on Odoo](start-stop.md): all the everyday commands

---

[Back to the list of guides](../README.md#what-do-you-want-to-do)
