# Work on a copy of a production database

To reproduce a bug or test a change on real data, restore a backup of the live database on your machine.

> [!WARNING]
> A plain copy of a live database still sends emails to real customers, runs scheduled actions, fetches mail, and talks to payment providers and other services. Always restore it with `--neutralize`, as shown below. Neutralizing turns all of that off in the copy.

## Before you start

The copy only works when your setup matches production:

- **Same Odoo version.** A database from Odoo 18 does not open in Odoo 19. If production runs another version than yours, first [switch to that version](switch-version.md).
- **Enterprise**, if production uses it. See [Add Odoo Enterprise](enterprise.md).
- **Every module installed in production**: your own in `addons/custom`, the others in `addons/third_party` (see [Add OCA or other ready-made modules](third-party-modules.md)), with the Python packages they need.

## 1. Get a backup of production

You need a **zip that includes the filestore** (the attachments). Depending on where production runs:

- **Odoo.sh**: in the **Backups** tab of the production branch, download a backup with the filestore.
- **Odoo Online**: on odoo.com, go to **My Databases**, open the menu of the database and choose **Download**.
- **Your own server**: open `https://<your-server>/web/database/manager`, click **Backup** next to the database, enter the master password, and choose the **zip** format (not `pg_dump`, which leaves out the attachments). If the page is disabled on the server, ask whoever runs it for a zip backup.

Large databases give large files. The download and the restore can take a while.

## 2. Put the zip in the `backups` folder

Copy the file into the `backups` folder of this project. Give it a short name without spaces if you like, e.g. `production.zip`.

## 3. Restore it, neutralized

Odoo must be running (`up`). Here the copy is called `prod_copy`:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh restore production.zip prod_copy --neutralize` | `.\odoo.ps1 restore production.zip prod_copy --neutralize` |

**When it works**, it prints:

```text
Restored 'prod_copy', neutralized: no emails sent, scheduled actions and payment providers off.
```

If it did not print the word `neutralized`, the copy is not neutralized: delete it in the database manager (<http://localhost:8069/web/database/manager>) and restore again with `--neutralize`.

## 4. Log in

Open <http://localhost:8069/web?db=prod_copy>. The users and passwords are the ones from production.

**Do not know a password?** Set a new one for the administrator. Open the Odoo shell on the copy:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh shell prod_copy` | `.\odoo.ps1 shell prod_copy` |

Then type these lines. The administrator's login is shown, and their password becomes `admin`:

```python
admin = env.ref('base.user_admin')
admin.login
admin.password = 'admin'
env.cr.commit()
exit()
```

## If something is wrong

| What happens | Why, and what to do |
|---|---|
| The Odoo log shows `module ... not found` or `not installable`, or pages fail with errors | A module installed in production is missing here. Add it (see [Before you start](#before-you-start)), then restart Odoo: `./odoo.sh restart` (PowerShell: `.\odoo.ps1 restart`) |
| Odoo fails to load the database, or the log mentions a version | The copy comes from another Odoo version. [Switch to that version](switch-version.md) and restore again |
| `restore failed` | See [Backup or restore fails](troubleshooting.md#backup-or-restore-fails) |

---

[Back to the list of guides](../README.md#what-do-you-want-to-do)
