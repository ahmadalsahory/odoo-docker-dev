# Create a module and see your changes

Your own modules live in `addons/custom`, one folder per module. Odoo finds them by itself, and they are part of your Git repository.

Odoo must be running (`up`). The examples use the database `odoo`. For another one, add its name at the end of `install` and `update`.

## 1. Create the module

Replace `my_module` with your module's technical name (lowercase letters, digits and `_`):

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh scaffold my_module` | `.\odoo.ps1 scaffold my_module` |

**When it works**, it prints `Created addons/custom/my_module` and restarts Odoo. The folder contains a starting `__manifest__.py`, a model, views and security files.

**Already have a module?** Copy its folder into `addons/custom` instead, so that you get `addons/custom/my_module/__manifest__.py`, then restart Odoo:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh restart` | `.\odoo.ps1 restart` |

## 2. Install it

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh install my_module` | `.\odoo.ps1 install my_module` |

Several modules at once: `install my_module,my_other_module`.

**When it works**, Odoo restarts and the module is installed. Reload the browser to see it.

If the database `odoo` does not exist yet, `install` creates it, with the login `admin` and the password `admin`, and says so.

## 3. Change it and see the result

What to run after each change:

| You changed | Run |
|---|---|
| Python files (`.py`) | `restart` |
| XML views, data files, security, `__manifest__.py` | `update my_module` |
| JavaScript, SCSS or OWL templates in `static/` | Nothing. Reload the page, with `?debug=assets` in the address |

For example, after changing a view:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh update my_module` | `.\odoo.ps1 update my_module` |

**Tip: see view changes without `update`.** In `.env`, set:

```env
ODOO_DEV_MODE=xml
```

Then run `./odoo.sh up` (PowerShell: `.\odoo.ps1 up`) once. From then on, Odoo reads views from your files, and reloading the page is enough. Other options are in [Developer mode](configuration.md#developer-mode).

**Tip: `?debug=assets`.** Add it to the address, e.g. `http://localhost:8069/web?debug=assets`, so Odoo rebuilds JavaScript and CSS on every reload.

## 4. Test it

See [Run a module's tests](run-tests.md).

## The module does not appear

- The `__manifest__.py` must be directly in `addons/custom/<module>/`, not one folder deeper.
- If `addons/custom` was empty when Odoo started, run `./odoo.sh restart` (PowerShell: `.\odoo.ps1 restart`) once. `status` shows `/mnt/custom-addons` in the addons path when Odoo sees the folder.
- If the manifest `version` starts with an Odoo version, such as `19.0.1.0.0`, it must match the running Odoo.

More in [Fix an error](troubleshooting.md#my-module-does-not-appear).

---

[Back to the list of guides](../README.md#what-do-you-want-to-do)
