# Add Odoo Enterprise

The project runs Community until you add the Enterprise source code to `addons/enterprise`. Then Odoo picks it up by itself. There is nothing to configure.

This page works both for a new setup and for a Community setup that is already running. If you have not started Odoo yet, do [Run Odoo for the first time](getting-started.md) first.

## Before you start

**You need access to the Enterprise source.** It is in the private GitHub repository [odoo/enterprise](https://github.com/odoo/enterprise). Only official Odoo partners get access, from the partner dashboard on odoo.com. If you cannot open that link while logged in to GitHub, you do not have access: ask your Odoo partner.

Customers with an Enterprise subscription do not get GitHub access: they download the source from [odoo.com/page/download](https://www.odoo.com/page/download) with their subscription code. That download contains all of Odoo, not only Enterprise, and these guides do not cover it yet.

**Know your Odoo version.** Enterprise must be the same version as Odoo. It is `ODOO_VERSION` in your `.env` file (20 if you have no `.env`). When Odoo is running, `status` shows it too:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh status` | `.\odoo.ps1 status` |

```text
Odoo version: 19.0
```

## 1. Download Enterprise

Run the line for your version. The command is the same on every system:

| Odoo version | Command |
|---|---|
| 20 | `git clone --branch 20.0 --depth 1 https://github.com/odoo/enterprise.git addons/enterprise` |
| 19 | `git clone --branch 19.0 --depth 1 https://github.com/odoo/enterprise.git addons/enterprise` |
| 18 | `git clone --branch 18.0 --depth 1 https://github.com/odoo/enterprise.git addons/enterprise` |
| 17 | `git clone --branch 17.0 --depth 1 https://github.com/odoo/enterprise.git addons/enterprise` |

Git asks you to log in to GitHub. Your GitHub password does not work there. Use one of these instead:

- **Git for Windows** opens a browser window to log in. Nothing to prepare.
- **GitHub CLI**: run `gh auth login` once, then the clone command.
- **SSH key** [added to your GitHub account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh): use `git@github.com:odoo/enterprise.git` instead of the `https://` address.
- **Personal access token**: when Git asks for a password, paste a [token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) instead.

**When it works**, Git counts up to 100% and stops without an error. `addons/enterprise` now contains about 800 folders, such as `web_enterprise` and `account_accountant`.

**If it stops with an error instead:**

| You see | What to do |
|---|---|
| `Repository not found` | Your GitHub account has no access. See [Before you start](#before-you-start) |
| `Remote branch 21.0 not found` | That version does not exist (yet). Check the number |
| `destination path 'addons/enterprise' already exists and is not an empty directory` | The folder has old content. Delete the `addons/enterprise` folder, then run the command again |

**Already have Enterprise somewhere else on your machine?** Skip the download and point to it instead. In `.env`:

```env
ENTERPRISE_ADDONS_PATH=../enterprise
```

The path is relative to the project folder, or absolute. On Windows use forward slashes, e.g. `C:/odoo/enterprise`. It must be on the branch of your Odoo version.

## 2. Start or restart Odoo

If Odoo is **not running** yet, start it:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh up` | `.\odoo.ps1 up` |

If Odoo is **already running**, restart it so it finds the new folder (`up` would leave it as it is):

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh restart` | `.\odoo.ps1 restart` |

Then check that Enterprise is found:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh status` | `.\odoo.ps1 status` |

**When it works**, the addons path starts with the Enterprise folder:

```text
Addons path:  /mnt/enterprise-addons
```

If it still says `<community modules only>`, Odoo does not see any modules in the folder. Check that `addons/enterprise` contains folders like `web_enterprise` directly, not inside another folder such as `addons/enterprise/enterprise`.

## 3. Turn Enterprise on in your database

**Databases you create from now on** are Enterprise automatically. Nothing to do.

**A database created before you added Enterprise** stays Community until you install the `web_enterprise` module in it. Replace `odoo` with your database name if it is different:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh install web_enterprise odoo` | `.\odoo.ps1 install web_enterprise odoo` |

**When it works**, reload Odoo in the browser: the home screen now shows the Enterprise app icons.

Not sure of your database names? `dbs` lists them:

| Linux / macOS / Git Bash | Windows PowerShell |
|---|---|
| `./odoo.sh dbs` | `.\odoo.ps1 dbs` |

## Good to know

**Subscription.** A local Enterprise database works fully for 30 days without registering. After that it asks for a subscription code. For development, create a new database at any time, or register it with your partner or subscription code.

**Versions must match.** Odoo 20 with Enterprise 19.0 does not work and fails in confusing ways. When `addons/enterprise` is a Git clone on a branch like `19.0`, the Odoo log shows a warning if it does not match. To change version later, see [Switch to another Odoo version](switch-version.md).

**Dates must match too, and `up` takes care of it.** Enterprise relies on Odoo code from the same day. `up` reads the date of your Enterprise clone and installs the Odoo build of that day (about 230 MB, downloaded once per Enterprise update). This needs `addons/enterprise` to be a Git clone and Git to be installed. After a `git pull`, run `up` again, not `restart`.

**Keeping it up to date.** See [Update Odoo and Enterprise](update.md).

**Never commit Enterprise.** Odoo Enterprise is licensed under the [Odoo Enterprise Edition License (OEEL-1)](https://www.odoo.com/documentation/master/legal/licenses.html). Publishing it, including in a public Git repository, breaks that license. The project is set up so this cannot happen by accident: `addons/enterprise/` is in `.gitignore`, and `.dockerignore` keeps it out of the Docker image. Keep it that way:

- Keep Enterprise in `addons/enterprise`, or outside the project with `ENTERPRISE_ADDONS_PATH`. Any other folder inside the project is not ignored by Git.
- Do not copy Enterprise modules into `addons/custom`.

## Common mistakes

**`addons/enterprise` contains `base`, `web`, `odoo-bin` or an `addons` folder.** That is a full Odoo source tree, for example a clone of `odoo/odoo` or a download from odoo.com, not the `odoo/enterprise` repository. Odoo already contains Community, and two copies of the same module in different versions break things. The Odoo log shows a warning `The Enterprise folder looks like a full Odoo source tree`. Delete the folder and do [step 1](#1-download-enterprise) again.

**The database still looks like Community.** See [step 3](#3-turn-enterprise-on-in-your-database).

---

[Back to the list of guides](../README.md#what-do-you-want-to-do)
