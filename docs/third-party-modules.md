# Add OCA or other ready-made modules

Modules you did not write, for example from the [OCA](https://github.com/OCA) or the [Odoo Apps store](https://apps.odoo.com), go into `addons/third_party`. Odoo finds them by itself.

Always take the version of the module that matches your Odoo version.

## 1. Get the modules

**From a Git repository** (OCA and most others): clone the whole repository into its own folder. For example, the OCA `web` repository for Odoo 19:

```bash
git clone --branch 19.0 --depth 1 https://github.com/OCA/web.git addons/third_party/web
```

Change `19.0` to your Odoo version, and the address and the last folder name to the repository you want. The command is the same on every system.

**From a zip** (Odoo Apps store): unzip it into `addons/third_party`, so that you get `addons/third_party/<module>/__manifest__.py`.

Both layouts work and can be mixed:

```text
addons/third_party/
├── web/                  ← a cloned repository with many modules
│   ├── web_responsive/
│   └── web_timeline/
└── some_module/          ← a single module from a zip
```

**If `git clone` says `Remote branch 19.0 not found`**, that repository has no version for your Odoo yet. The OCA usually publishes it weeks or months after a new Odoo release.

## 2. Add the Python packages they need

Some modules need extra Python packages. They are listed under `external_dependencies` in the module's `__manifest__.py`. If there are any, follow [Add a Python package](python-packages.md) first.

## 3. Restart Odoo

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh restart` | `.\odoo.ps1 restart` |

Check that Odoo finds the new folder:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh status` | `.\odoo.ps1 status` |

The addons path now includes it, e.g. `/mnt/third-party-addons/web`.

## 4. Install the module

Use the module's folder name, not the repository's:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh install web_responsive` | `.\odoo.ps1 install web_responsive` |

**If it fails because a dependency is missing**, the module needs a module from another repository. Its `__manifest__.py` lists them under `depends`. Clone that repository too (step 1), then restart and install again.

## Keeping them in Git

`addons/third_party` is ignored by Git, because these are usually separate repositories. To share them with your team, either:

- add them as [Git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules), or
- copy the modules without their `.git` folder and remove the `addons/third_party/*` lines from `.gitignore`.

---

[Back to the list of guides](../README.md#what-do-you-want-to-do)
