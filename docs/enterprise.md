# Using Odoo Enterprise

The template runs Community by default. Enterprise is switched on automatically when `addons/enterprise` contains the Enterprise modules. There is nothing else to configure.

## Licensing rules

> [!CAUTION]
> Odoo Enterprise is proprietary software licensed under the [Odoo Enterprise Edition License (OEEL-1)](https://www.odoo.com/documentation/master/legal/licenses.html). Publishing it, including in a public Git repository, breaks that license.

This template is set up so this cannot happen by accident:

- `addons/enterprise/` is listed in `.gitignore`, so Git never picks it up.
- `.dockerignore` keeps it out of the Docker build, so it never ends up in an image. It is only mounted into the running container, read-only.

Keep it that way:

- Keep Enterprise in `addons/enterprise`, or outside this repository entirely ([see below](#reusing-an-existing-checkout)). Any other folder inside the repository is not ignored.
- Do not remove the `.gitignore` entry.
- Do not copy Enterprise modules into `addons/custom`.

You need access to the private [odoo/enterprise](https://github.com/odoo/enterprise) repository. It is granted to Odoo partners and to customers with an Enterprise subscription. If you cannot open that link while logged in to GitHub, you do not have access. Use Community, or ask your Odoo partner.

## Getting the source

Clone the branch that matches `ODOO_VERSION` in `.env`: the same number followed by `.0`.

| `ODOO_VERSION` | Command |
|---|---|
| `20` | `git clone --branch 20.0 --depth 1 https://github.com/odoo/enterprise.git addons/enterprise` |
| `19` | `git clone --branch 19.0 --depth 1 https://github.com/odoo/enterprise.git addons/enterprise` |
| `18` | `git clone --branch 18.0 --depth 1 https://github.com/odoo/enterprise.git addons/enterprise` |
| `17` | `git clone --branch 17.0 --depth 1 https://github.com/odoo/enterprise.git addons/enterprise` |

**Logging in.** GitHub no longer accepts account passwords for Git. Use one of these:

- **Git for Windows** opens a browser window to log in. Nothing to prepare.
- **GitHub CLI**: run `gh auth login` once, then clone as above.
- **SSH key** [added to your GitHub account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh): replace the URL with `git@github.com:odoo/enterprise.git`.
- **Personal access token**: when Git asks for a password, paste a [token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) instead.

Then start Odoo with `up`, or run `restart` if it is already running (`up` leaves a running Odoo untouched when `.env` has not changed).

Check that it worked with `status`: the addons path should now start with `/mnt/enterprise-addons`.

The Enterprise branch and the Odoo image must be the **same version**. Mixing them, for example Odoo 20 with Enterprise 19.0, does not work and fails in confusing ways. When `addons/enterprise` is a Git clone on a branch named like a version, the Odoo log shows a warning if it does not match.

### Updating

Odoo publishes fixes every day, both in the image and in the Enterprise repository. To update both:

```bash
git -C addons/enterprise pull
docker compose build --pull  # optional: rebuild on the newest official image
./odoo.sh up
./odoo.sh restart            # needed if up did not recreate the container
./odoo.sh update all         # apply the changes to your database
```

### Switching versions

`--depth 1` keeps the download small but only contains one branch. To be able to switch, do a full clone once (without `--depth 1`). Then, to go to 19 for example:

```bash
./odoo.sh down                          # while .env still has the old version
git -C addons/enterprise checkout 19.0
# set ODOO_VERSION=19 in .env
./odoo.sh up
```

## Reusing an existing checkout

If Enterprise is already somewhere on your machine, point to it instead of cloning again. In `.env`:

```env
ENTERPRISE_ADDONS_PATH=../enterprise
```

Relative paths are relative to this folder. On Windows, paths like `C:/odoo/enterprise` work too (use forward slashes). The helper scripts refuse to start if the folder does not exist, so a typo cannot silently start Odoo without Enterprise.

## Common mistakes

**`addons/enterprise` contains `base`, `web`, `odoo-bin` or an `addons` folder**
That is a full Odoo source tree, for example a clone of `odoo/odoo` or a source archive from odoo.com, not the `odoo/enterprise` repository. The official image already ships Community, and two copies of the same module in different versions break things. The log shows a warning when this happens. Replace the folder with a clone of `odoo/enterprise`, which only contains Enterprise modules.

**The database still looks like Community**
Enterprise modules are only used once they are installed. On a new database this happens automatically. For a database created before you added Enterprise, install `web_enterprise`:

```bash
./odoo.sh install web_enterprise
```

## Subscription

A local Enterprise database works fully for 30 days without registering. After that, it asks for a subscription code. For development you can create a new database at any time, or register the database with your partner or subscription code.
