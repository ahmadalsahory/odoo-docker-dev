# Update Odoo and Enterprise to the latest fixes

Odoo publishes fixes for each version almost every day, both for Odoo itself and in the Enterprise repository. Your setup does not update by itself: it keeps the code it downloaded first, until you update it.

Updating stays within your version: Odoo 19 gets the latest Odoo 19 fixes. To move to another version, see [Switch to another Odoo version](switch-version.md).

## 1. Get the latest code

**With Enterprise**, update the Enterprise clone:

```bash
git -C addons/enterprise pull
```

The command is the same on every system. Do the same for each repository in `addons/third_party`, e.g. `git -C addons/third_party/web pull`.

**Without Enterprise**, get the latest Odoo image instead:

```bash
docker compose build --pull
```

## 2. Start Odoo with the new code

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh up` | `.\odoo.ps1 up` |

**With Enterprise, `up` matches Odoo to it.** Enterprise relies on Odoo code from the same day, and the Odoo image is only published about once a week. So `up` looks up the date of your Enterprise code and installs the Odoo build of that day from [Odoo's nightly builds](https://nightly.odoo.com), the packages the official image is made of. This downloads about 230 MB each time Enterprise has moved to a new day, so it needs internet then. The log shows which build it picked:

```text
[odoo-docker-dev] Enterprise is from 20261003: replacing Odoo Community build 20260926 with 20261004.
```

Use `up` after every `git pull`, not `restart`: `restart` keeps the old Odoo code, and some Enterprise modules then fail to install with errors such as `ImportError: cannot import name ...`. The Odoo log warns when this happens. `status` shows the build in use:

```text
Odoo build:   19.0.20261004
```

## 3. Update your databases

New code can change data and views, which only reach a database when its modules are updated. For each database you keep using, here `odoo`:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh update all odoo` | `.\odoo.ps1 update all odoo` |

This takes a few minutes per database. Not sure which databases you have? `dbs` lists them.

**If it fails**, the log shows which module failed and why. Often it is one of your own modules that relies on something that changed: fix it, then run the update again.

---

[Back to the list of guides](../README.md#what-do-you-want-to-do)
