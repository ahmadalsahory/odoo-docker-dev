# Change ports, or open Odoo from your phone

## The ports

| Setting in `.env` | Default | Used for |
|---|---|---|
| `ODOO_PORT` | `8069` | Odoo in your browser: `http://localhost:8069` |
| `POSTGRES_PORT` | `5433` | Database tools on your computer, such as DBeaver |
| `PGADMIN_PORT` | `5050` | pgAdmin, when started with `tools` |

## Change a port

Usually because another program already uses it. `up` tells you when that happens, and suggests a free port.

1. Open `.env` and change the port, for example:

   ```env
   ODOO_PORT=8070
   ```

2. Apply it:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh up` | `.\odoo.ps1 up` |

**When it works**, `up` prints the new address: `Odoo is ready at http://localhost:8070`. For `PGADMIN_PORT`, run `./odoo.sh tools` (PowerShell: `.\odoo.ps1 tools`) instead of `up`.

Each port must be a number between 1 and 65535, and the three must be different. `up` checks this.

## Open Odoo from your phone or another computer

By default, only your own computer can open Odoo. To open it from other devices on the same network:

1. In `.env`, let Odoo listen on the network, and choose a real master password, because the database manager will be reachable too:

   ```env
   BIND_ADDRESS=0.0.0.0
   ADMIN_PASSWORD=choose-a-strong-password
   ```

2. Apply it:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh up` | `.\odoo.ps1 up` |

3. Find your computer's address on the network:

| Windows | macOS | Linux |
|---|---|---|
| `ipconfig`, the line **IPv4 Address** | `ipconfig getifaddr en0` | `hostname -I`, the first address |

   It looks like `192.168.1.20`.

4. On the phone, connected to the **same Wi-Fi**, open `http://192.168.1.20:8069`, with your address and `ODOO_PORT`.

**If the phone cannot connect:** check that both are on the same network, and that your computer's firewall allows it. On Windows, allow Docker Desktop on private networks in **Windows Defender Firewall > Allow an app through firewall**.

Only Odoo is opened to the network this way. PostgreSQL and pgAdmin always stay reachable from your own computer only.

To close it again, set `BIND_ADDRESS=127.0.0.1` and run `./odoo.sh up` (PowerShell: `.\odoo.ps1 up`).

---

[Back to the list of guides](../README.md#what-do-you-want-to-do)
