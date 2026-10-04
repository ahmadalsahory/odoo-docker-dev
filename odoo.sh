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
  status                   Show container status
  bash                     Open a shell inside the Odoo container
  tools                    Start pgAdmin on http://localhost:5050
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
  scaffold <name>          Create a new module in addons/custom
EOF
}

# Allocate a TTY only when there is one (keeps CI and pipes working).
TTY_FLAG=""
[ -t 0 ] && [ -t 1 ] || TTY_FLAG="-T"

compose() { docker compose "$@"; }
# shellcheck disable=SC2086 # TTY_FLAG is intentionally unquoted so it can be empty
compose_exec() { compose exec $TTY_FLAG "$@"; }
helper() { compose_exec odoo odoo-docker "$@"; }

# Restart Odoo and return only once it answers again.
restart_odoo() {
    compose restart odoo
    compose up -d --wait odoo
}

# Same precedence as Docker Compose: shell environment, then .env, then default.
env_value() {
    local value="${!1:-}"
    [ -n "$value" ] || value="$(sed -n "s/^$1=//p" .env 2>/dev/null | tail -n1 | tr -d '\r')"
    echo "${value:-$2}"
}

prepare() {
    if [ ! -f .env ]; then
        cp .env.example .env
        echo "Created .env from .env.example. Review it any time."
    fi
    # Create bind-mount folders ourselves; otherwise Docker creates them owned by root.
    mkdir -p addons/enterprise addons/third_party addons/custom backups
    # The container user (uid 101) writes backups here on Linux.
    chmod a+rwx backups 2>/dev/null || true
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
    status)   compose ps ;;
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
