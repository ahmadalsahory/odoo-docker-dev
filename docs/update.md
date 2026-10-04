# Update Odoo and Enterprise to the latest fixes

Odoo publishes fixes for each version almost every day, both in the Odoo image and in the Enterprise repository. Your setup does not update by itself: it keeps the code it downloaded first, until you update it.

Updating stays within your version: Odoo 19 gets the latest Odoo 19 fixes. To move to another version, see [Switch to another Odoo version](switch-version.md).

Update Odoo and Enterprise together, so they stay in step.

## 1. Enterprise only: get the latest Enterprise

```bash
git -C addons/enterprise pull
```

The command is the same on every system. Do the same for each repository in `addons/third_party`, e.g. `git -C addons/third_party/web pull`.

## 2. Get the latest Odoo image

```bash
docker compose build --pull
```

The command is the same on every system. It downloads the newest image of your Odoo version and rebuilds on top of it.

If you pinned an exact build with `ODOO_TAG` in `.env`, this keeps that build. Change `ODOO_TAG` to a newer one first ([list of tags](https://hub.docker.com/_/odoo/tags)), or remove it.

## 3. Restart Odoo with the new code

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh up` | `.\odoo.ps1 up` |
| `./odoo.sh restart` | `.\odoo.ps1 restart` |

`up` switches to the new image. `restart` makes sure Odoo also loads the new Enterprise code, in case `up` had nothing to change.

## 4. Update your databases

New code can change data and views, which only reach a database when its modules are updated. For each database you keep using, here `odoo`:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh update all odoo` | `.\odoo.ps1 update all odoo` |

This takes a few minutes per database. Not sure which databases you have? `dbs` lists them.

**If it fails**, the log shows which module failed and why. Often it is one of your own modules that relies on something that changed: fix it, then run the update again.

---

[Back to the list of guides](../README.md#what-do-you-want-to-do)
