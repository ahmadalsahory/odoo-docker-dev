# Back up and restore a database

A backup is one zip file with the database and its attachments (the filestore). It is the same format as the **Backup** button of Odoo's database manager, so zips work in both directions: made here and restored in the browser, or the other way round.

Odoo must be running (`up`). Backups are saved in the `backups` folder of the project, which Git ignores.

## Back up

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh backup` | `.\odoo.ps1 backup` |

This backs up the database `odoo`. For another one, add its name, e.g. `backup mydb`.

**When it works**, it prints where the file is:

```text
Saved backups/odoo_20261004_131909.zip
```

## Restore

1. Put the zip in the `backups` folder, if it is not there already.
2. Restore it under a name that is not used yet. Here the new database is called `copy1`:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh restore odoo_20261004_131909.zip copy1` | `.\odoo.ps1 restore odoo_20261004_131909.zip copy1` |

Give only the file name, not `backups/...`. Without a database name, it restores as `odoo`, if that name is free.

**When it works**, it prints `Restored 'copy1'.` Open Odoo and choose `copy1` on the database selector, or go to <http://localhost:8069/web?db=copy1>.

The restored database gets a new unique ID, so Odoo treats it as a copy (for example for the Enterprise subscription), not as the original.

**Restoring a backup from a live system?** Use [Work on a copy of a production database](production-copy.md) instead. It stops the copy from sending emails to real customers.

## In the browser

The same is possible from Odoo's database manager at <http://localhost:8069/web/database/manager>, with the master password `admin` (`ADMIN_PASSWORD` in `.env`). It is also the place to **delete** or **duplicate** a database, which the helper commands do not do.

## If it fails

| You see | What to do |
|---|---|
| `database 'copy1' already exists` | Choose another name, or delete that database in the database manager first |
| `file not found: backups/...` | The zip is not in the `backups` folder, or the name has a typo. Check with `ls backups` (PowerShell: `dir backups`) |
| `backup failed` or `restore failed` | See [Backup or restore fails](troubleshooting.md#backup-or-restore-fails) |

---

[Back to the list of guides](../README.md#what-do-you-want-to-do)
