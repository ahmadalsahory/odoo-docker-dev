#!/usr/bin/env bash
# Helper for Linux, macOS and Git Bash on Windows. Run ./odoo.sh help for usage.
# Windows PowerShell users: use .\odoo.ps1 with the same commands.

set -euo pipefail
cd "$(dirname "$0")"

# Stop Git Bash from rewriting container paths such as /mnt/... into Windows paths.
export MSYS_NO_PATHCONV=1

usage() {
    cat <<'EOF'
Usage: ./odoo.sh <command> [arguments]

Stack:
  up                       Build and start Odoo and PostgreSQL
  down                     Stop and remove the containers (data is kept)
  restart                  Restart Odoo (after Python or config changes)
  logs [service]           Follow logs (default: odoo)
  status                   Show containers, Odoo version and addons path
  bash                     Open a shell inside the Odoo container
  tools                    Start pgAdmin (PGADMIN_PORT, default 5050)
  reset                    Delete the containers AND all data of this project

Odoo (DB defaults to ODOO_DB from .env):
  install <modules> [db]   Install comma-separated modules, then restart
  update <modules> [db]    Update comma-separated modules, then restart
  test <modules>           Run module tests in a fresh throwaway database
  shell [db]               Odoo Python shell
  psql [db]                PostgreSQL shell
  dbs                      List databases
  backup [db]              Save a backup zip into backups/
  restore <file> [db]      Restore a zip from backups/ as a new database
                           (add --neutralize for a copy of a production database)
  scaffold <name>          Create a new module in addons/custom
EOF
}

die() { echo "Error: $*" >&2; exit 1; }

# Allocate a TTY only when there is one (keeps CI and pipes working).
TTY_FLAG=""
[ -t 0 ] && [ -t 1 ] || TTY_FLAG="-T"

# Git Bash's default terminal (mintty) is not a real Windows console, so interactive
# docker commands need winpty there.
WINPTY=""
if [ -z "$TTY_FLAG" ] && [ -n "${MSYSTEM:-}" ] && command -v winpty > /dev/null 2>&1; then
    WINPTY="winpty"
fi

compose() { docker compose "$@"; }

# shellcheck disable=SC2086 # WINPTY and TTY_FLAG are intentionally unquoted so they can be empty
compose_exec() {
    [ -n "$(compose ps --status running -q odoo 2> /dev/null)" ] \
        || die "Odoo is not running. Start it first: ./odoo.sh up"
    $WINPTY docker compose exec $TTY_FLAG "$@"
}

helper() { compose_exec odoo odoo-docker "$@"; }

# Restart Odoo and return only once it answers again.
restart_odoo() {
    compose restart odoo
    compose up -d --wait odoo
}

# Same precedence as Docker Compose: shell environment, then .env, then default.
env_value() {
    local value="${!1:-}"
    if [ -z "$value" ] && [ -f .env ]; then
        # Strip CR, a trailing " # comment" and surrounding quotes, like Compose does.
        value="$(sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" .env | tail -n1 \
            | tr -d '\r' | sed -e 's/[[:space:]]#.*$//' -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/")"
    fi
    echo "${value:-$2}"
}

# Creates the default folders, and refuses custom paths that do not exist (Docker would
# silently create an empty folder and Odoo would start without those modules).
check_addons_path() {
    local var="$1" default="$2" path
    path="$(env_value "$var" "$default")"
    if [ "$path" = "$default" ]; then
        mkdir -p "$default"
    elif [ ! -d "$path" ]; then
        die "$var=$path does not exist. Fix the path in .env."
    fi
}

prepare() {
    if [ ! -f .env ]; then
        cp .env.example .env
        echo "Created .env from .env.example. Review it any time."
    fi

    local version
    version="$(env_value ODOO_VERSION 20)"
    [[ "$version" =~ ^[0-9]+$ ]] \
        || die "ODOO_VERSION must be a major version such as 20 (no .0), got '$version'."

    # Create bind-mount folders ourselves; otherwise Docker creates them owned by root.
    check_addons_path ENTERPRISE_ADDONS_PATH ./addons/enterprise
    check_addons_path THIRD_PARTY_ADDONS_PATH ./addons/third_party
    check_addons_path CUSTOM_ADDONS_PATH ./addons/custom
    mkdir -p backups
    # The container user (uid 101) writes backups here on Linux.
    chmod a+rwx backups 2> /dev/null || true
}

cmd="${1:-help}"
shift || true

case "$cmd" in
    up)
        prepare
        echo "Starting... the first run downloads images and can take a few minutes."
        compose up -d --build --wait "$@"
        echo "Odoo is ready at http://localhost:$(env_value ODOO_PORT 8069)"
        ;;
    down)     compose down "$@" ;;
    restart)  restart_odoo ;;
    logs)     compose logs -f --tail 200 "${1:-odoo}" ;;
    status)
        compose ps
        if [ -n "$(compose ps --status running -q odoo 2> /dev/null)" ]; then
            helper info
        fi
        ;;
    bash)     compose_exec odoo bash ;;
    tools)
        compose --profile tools up -d pgadmin
        echo "pgAdmin is at http://localhost:$(env_value PGADMIN_PORT 5050)"
        ;;
    reset)
        read -r -p "Delete all containers, databases and filestore of this project? Type 'yes': " answer
        [ "$answer" = "yes" ] || { echo "Cancelled."; exit 1; }
        compose --profile tools down -v
        ;;
    install|update)
        helper "$cmd" "$@"
        restart_odoo
        ;;
    scaffold)
        # Create files as the current user so they stay editable on Linux.
        compose_exec -u "$(id -u):$(id -g)" odoo odoo-docker scaffold "$@"
        # Restart so the server rescans addons/custom (it may have been empty until now).
        restart_odoo
        ;;
    test|shell|psql|dbs|backup|restore)
        helper "$cmd" "$@"
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        usage >&2
        exit 1
        ;;
esac
