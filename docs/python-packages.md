# Add a Python package a module needs

When a module needs a Python package that Odoo does not include, it fails to install with an error such as `External dependency 'pandas' not installed` or `No module named 'pandas'`. Packages are added to the Odoo image through `requirements.txt`.

## 1. Add the package to `requirements.txt`

Open `requirements.txt` in the project folder and add one line per package, with the exact version:

```text
pandas==2.2.3
```

Fixing the version means everyone on your team gets the same one. To find the latest version, look up the package on [pypi.org](https://pypi.org).

The name to use is the one from `pip install`, which is not always the name the module imports. For example, `import dateutil` comes from the package `python-dateutil`. The module's `__manifest__.py` lists what it needs under `external_dependencies`.

## 2. Rebuild and restart

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh up` | `.\odoo.ps1 up` |

`up` sees that `requirements.txt` changed, rebuilds the Odoo image with the package, and restarts Odoo with it. This takes a minute or more, depending on the package.

**When it works**, it ends with `Odoo is ready at ...` as usual. You can now install the module that needed the package.

**If the build fails** with `No matching distribution found` or `Could not find a version`, the name or the version is wrong, or that version does not support the Python of your Odoo image. Fix the line and run `up` again.

## Check that a package is there

Open a terminal inside Odoo:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh bash` | `.\odoo.ps1 bash` |

Then, inside it:

```bash
pip3 show pandas
exit
```

## Remove a package

Delete its line from `requirements.txt` and run `./odoo.sh up` (PowerShell: `.\odoo.ps1 up`) again.

---

[Back to the list of guides](../README.md#what-do-you-want-to-do)
