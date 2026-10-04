# Switch to another Odoo version

Each Odoo version keeps its own databases. Switching from 19 to 18 does not touch your Odoo 19 databases: they are still there when you switch back.

## 1. Stop Odoo, before changing anything

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh down` | `.\odoo.ps1 down` |

Do this **before** step 2. The commands always act on the version written in `.env`, so once you change it, they can no longer stop the old one. If you forgot, see [Port already in use](troubleshooting.md#port-already-in-use).

## 2. Set the new version

Open `.env` and change `ODOO_VERSION` to `17`, `18`, `19` or `20` (just the number):

```env
ODOO_VERSION=18
```

## 3. Enterprise only: get the matching Enterprise

Enterprise must be the same version. Delete the `addons/enterprise` folder, then clone the new version. For 18:

```bash
git clone --branch 18.0 --depth 1 https://github.com/odoo/enterprise.git addons/enterprise
```

Use the version you set in step 2. Details and login help: [Add Odoo Enterprise](enterprise.md#1-download-enterprise).

Modules in `addons/third_party` must match too: clone their branch for the new version in the same way.

## 4. Start Odoo

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh up` | `.\odoo.ps1 up` |

The first start of a version downloads its image, about 1 GB.

**When it works**, `status` shows the new version:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh status` | `.\odoo.ps1 status` |

```text
Odoo version: 18.0
```

The first time you use a version, it has no databases yet: Odoo shows the form to create one, as in [Run Odoo for the first time](getting-started.md#5-create-your-first-database).

## Good to know

- **Switching back** is the same steps with the old number. Your databases of that version are where you left them.
- **A database cannot move to another version** by switching. Opening an Odoo 18 database requires Odoo 18. Moving a database to a newer version is an upgrade, done with [Odoo's upgrade service](https://upgrade.odoo.com).
- **Two versions at the same time?** See [Run two Odoo setups at the same time](several-instances.md).

---

[Back to the list of guides](../README.md#what-do-you-want-to-do)
