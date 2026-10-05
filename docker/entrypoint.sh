#!/bin/bash
# Generates the effective Odoo configuration from config/odoo.conf and the
# environment, then hands over to the official image entrypoint.
#
# Values written here (addons_path, admin_passwd, db_*) are only added when
# config/odoo.conf does not already define them, so the file always wins.

set -euo pipefail

BASE_CONF=/etc/odoo/odoo.base.conf
TARGET_CONF="${ODOO_RC:-/etc/odoo/odoo.conf}"

# Mount points, in the order they should appear in addons_path.
ADDONS_ROOTS=(/mnt/enterprise-addons /mnt/third-party-addons /mnt/custom-addons)

log() { echo "[odoo-docker-dev] $*" >&2; }
trap 'log "ERROR: entrypoint failed at line $LINENO"' ERR

# A directory is an addons directory when one of its children is a module.
is_addons_dir() {
    compgen -G "$1/*/__manifest__.py" > /dev/null
}

collect_addons_paths() {
    local root sub
    for root in "${ADDONS_ROOTS[@]}"; do
        [ -d "$root" ] || continue
        if is_addons_dir "$root"; then
            echo "$root"
        fi
        # Also accept one level of repositories, e.g. third_party/<oca-repo>/<module>.
        for sub in "$root"/*/; do
            sub="${sub%/}"
            if [ -d "$sub" ] && [ ! -f "$sub/__manifest__.py" ] && is_addons_dir "$sub"; then
                echo "$sub"
            fi
        done
    done
    return 0
}

# ODOO_VERSION inside the container is set by the official image (e.g. 20.0).
# EXPECTED_ODOO_VERSION is the value from .env (e.g. 20).
warn_on_version_mismatch() {
    local expected="${EXPECTED_ODOO_VERSION:-}"
    [ -n "$expected" ] && [ -n "${ODOO_VERSION:-}" ] || return 0
    if [ "$expected.0" != "$ODOO_VERSION" ]; then
        log "WARNING: ODOO_VERSION in .env is '$expected' but the image runs Odoo $ODOO_VERSION."
        log "WARNING: ODOO_VERSION must be a major version such as 20 (no .0), and ODOO_TAG,"
        log "WARNING: if set, must start with the same version (e.g. $expected.0-20260926)."
    fi
}

# These checks only warn: a wrong guess must never stop Odoo from starting.
warn_on_suspicious_enterprise() {
    local dir=/mnt/enterprise-addons head branch

    # A full Odoo source tree (odoo/odoo clone or source archive) instead of odoo/enterprise.
    if compgen -G "$dir/base/__manifest__.py" > /dev/null \
        || compgen -G "$dir/*/web/__manifest__.py" > /dev/null \
        || compgen -G "$dir/web/__manifest__.py" > /dev/null \
        || compgen -G "$dir/odoo-bin" > /dev/null \
        || compgen -G "$dir/*/odoo-bin" > /dev/null; then
        log "WARNING: The Enterprise folder looks like a full Odoo source tree, not the"
        log "WARNING: odoo/enterprise repository. Community modules from the image may be"
        log "WARNING: shadowed by a different version. See docs/enterprise.md."
    fi

    # Compare the checked-out branch with the server version. Only branches named like
    # a version are checked, so custom branches and archives without .git are left alone.
    [ -f "$dir/.git/HEAD" ] || return 0
    head="$(tr -d '\r' < "$dir/.git/HEAD" 2> /dev/null)" || return 0
    branch="${head#ref: refs/heads/}"
    if [ "$branch" != "$head" ] && [[ "$branch" =~ ^[0-9]+\.[0-9]+$ ]] \
        && [ "$branch" != "${ODOO_VERSION:-$branch}" ]; then
        log "WARNING: The Enterprise folder is on branch $branch but Odoo is $ODOO_VERSION."
        log "WARNING: Use the $ODOO_VERSION branch of odoo/enterprise, or set ODOO_VERSION in .env"
        log "WARNING: to ${branch%.0}. See docs/enterprise.md."
    fi
    return 0
}

# Prints the commit checked out in a Git folder, without needing Git in the image.
git_head() {
    local git="$1/.git" head ref
    [ -f "$git/HEAD" ] || return 0
    head="$(tr -d '\r' < "$git/HEAD")"
    case "$head" in
        "ref: "*)
            ref="${head#ref: }"
            if [ -f "$git/$ref" ]; then
                tr -d '\r' < "$git/$ref"
            elif [ -f "$git/packed-refs" ]; then
                awk -v ref="$ref" '{ sub(/\r$/, "") } $2 == ref { print $1; exit }' "$git/packed-refs"
            fi
            ;;
        *) echo "$head" ;;
    esac
}

# The image holds the Community build matching the Enterprise commit it was built for
# (see match-community.sh). After a git pull, only "up" installs the new match.
warn_on_unmatched_enterprise() {
    local current built
    current="$(git_head /mnt/enterprise-addons)"
    [ -n "$current" ] || return 0
    built="$(cat /etc/odoo/enterprise-commit 2> /dev/null)" || true
    [ "$current" != "$built" ] || return 0
    if [ -z "$built" ]; then
        log "WARNING: Odoo was not matched to your Enterprise version, so some Enterprise"
        log "WARNING: modules may fail to install. Start Odoo with ./odoo.sh up (or .\\odoo.ps1 up)."
    else
        log "WARNING: Enterprise changed since Odoo was built for it, so some Enterprise"
        log "WARNING: modules may fail to install. Run ./odoo.sh up (or .\\odoo.ps1 up) to match them."
    fi
    log "WARNING: See docs/update.md."
    return 0
}

has_option() {
    [ -f "$BASE_CONF" ] && grep -qE "^\s*$1\s*=" "$BASE_CONF"
}

build_config() {
    local generated=() addons_path

    if ! has_option addons_path; then
        addons_path="$(collect_addons_paths | paste -sd, -)"
        if [ -n "$addons_path" ]; then
            generated+=("addons_path = $addons_path")
        fi
        log "addons_path: ${addons_path:-<community modules only>}"
    fi
    has_option admin_passwd || generated+=("admin_passwd = ${ADMIN_PASSWORD:-admin}")
    has_option db_host      || generated+=("db_host = ${DB_HOST:-db}")
    has_option db_port      || generated+=("db_port = ${DB_PORT:-5432}")
    has_option db_user      || generated+=("db_user = ${POSTGRES_USER:-odoo}")
    has_option db_password  || generated+=("db_password = ${POSTGRES_PASSWORD:-odoo}")

    local extra
    extra="$(printf '%s\n' "${generated[@]}")"

    {
        echo "; Generated by odoo-docker-dev at container start. Edit config/odoo.conf instead."
        if [ -f "$BASE_CONF" ]; then
            # Insert generated options right after the [options] header.
            # ENVIRON is used instead of -v so the multi-line value is passed verbatim.
            EXTRA="$extra" awk '
                { sub(/\r$/, "") }
                { print }
                /^\[options\]/ && !done { print ENVIRON["EXTRA"]; done = 1 }
                END { if (!done) { print "[options]"; print ENVIRON["EXTRA"] } }
            ' "$BASE_CONF"
        else
            echo "[options]"
            echo "$extra"
        fi
    } > "$TARGET_CONF"
}

# Used by the odoo-docker-dev helper to pick up addons folders created after start.
if [ "${1:-}" = "--configure-only" ]; then
    build_config
    exit 0
fi

warn_on_version_mismatch
warn_on_suspicious_enterprise
warn_on_unmatched_enterprise
build_config

# Enable developer mode for the main server process only.
if [ "$#" -eq 1 ] && [ "$1" = "odoo" ] && [ -n "${ODOO_DEV_MODE:-}" ]; then
    set -- odoo "--dev=${ODOO_DEV_MODE}"
fi

exec /entrypoint.sh "$@"
