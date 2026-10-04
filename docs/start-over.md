# Delete everything and start over

`reset` deletes all databases and attachments of your current Odoo version, so the next `up` starts as if it were the first time.

It does **not** touch your files: your modules, `addons/enterprise`, `.env` and the `backups` folder stay as they are.

## 1. Keep what you need

Deleted databases cannot be recovered. To keep one, back it up first (here the database `odoo`), see [Back up and restore](backup-restore.md):

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh backup odoo` | `.\odoo.ps1 backup odoo` |

## 2. Delete

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh reset` | `.\odoo.ps1 reset` |

It asks for confirmation. Type `yes` and press Enter.

This only deletes the data of the Odoo version in `.env`. Databases of other versions are kept. To delete those too, [switch to each version](switch-version.md) and run `./odoo.sh reset` (PowerShell: `.\odoo.ps1 reset`) there.

## 3. Start again

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh up` | `.\odoo.ps1 up` |

Then create a database as in [Run Odoo for the first time](getting-started.md#5-create-your-first-database).

## Free disk space

Each Odoo version you used keeps its image, about 1 GB each. To see them and remove the ones you no longer need (the command is the same on every system):

```bash
docker image ls
docker image rm odoo:17 odoo-17-odoo
```

Replace `17` with the version to remove. `docker builder prune` clears the build cache as well.

## Remove the project completely

Run `./odoo.sh reset` (PowerShell: `.\odoo.ps1 reset`) for each version you used, then delete the project folder.

---

[Back to the list of guides](../README.md#what-do-you-want-to-do)
