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

helper() { compose_exec odoo odoo-docker-dev "$@"; }

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

# Prints "<hash> <unix time>" of the Enterprise checkout, so the image installs the
# matching Community build (see docker/match-community.sh). Prints nothing when there
# is no Enterprise Git clone.
enterprise_commit() {
    local path
    path="$(env_value ENTERPRISE_ADDONS_PATH ./addons/enterprise)"
    [ -e "$path/.git" ] || return 0
    if ! command -v git > /dev/null 2>&1; then
        echo "Warning: Git is not installed, so Odoo cannot be matched to your Enterprise version." >&2
        return 0
    fi
    # safe.directory: on Windows, folders on other drives often trip Git's ownership check.
    git -c safe.directory='*' -C "$path" log -1 --format='%H %ct' 2> /dev/null \
        || echo "Warning: cannot read the Enterprise commit in $path, so Odoo cannot be matched to it." >&2
}

check_docker() {
    command -v docker > /dev/null 2>&1 \
        || die "Docker is not installed. See https://docs.docker.com/get-started/get-docker/"
    docker info > /dev/null 2>&1 \
        || die "Docker is not running. Start Docker Desktop (Linux: sudo systemctl start docker), then try again.
See docs/troubleshooting.md#docker-is-not-running"
}

port_default() {
    case "$1" in
        ODOO_PORT) echo 8069 ;;
        POSTGRES_PORT) echo 5433 ;;
        PGADMIN_PORT) echo 5050 ;;
    esac
}

port_value() { env_value "$1" "$(port_default "$1")"; }

check_port_settings() {
    local name value other address
    for name in ODOO_PORT POSTGRES_PORT PGADMIN_PORT; do
        value="$(port_value "$name")"
        if ! [[ "$value" =~ ^[0-9]{1,5}$ ]] || [ "$value" -lt 1 ] || [ "$value" -gt 65535 ]; then
            die "$name must be a port number between 1 and 65535, got '$value'."
        fi
        for other in ODOO_PORT POSTGRES_PORT PGADMIN_PORT; do
            [ "$other" = "$name" ] && break
            if [ "$(port_value "$other")" -eq "$value" ]; then
                die "$other and $name are both set to $value in .env. Give each one its own port."
            fi
        done
    done
    address="$(env_value BIND_ADDRESS 127.0.0.1)"
    if ! [[ "$address" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ || "$address" == *:* ]]; then
        die "BIND_ADDRESS must be an IP address such as 127.0.0.1 or 0.0.0.0, got '$address'."
    fi
}

# Prints the PID listening on a TCP port, Windows (Git Bash) only. Matches the foreign
# address 0.0.0.0:0 rather than the state, which Windows translates.
windows_listener_pid() {
    netstat -ano -p tcp | tr -d '\r' | awk -v p=":$1" '
        $1 == "TCP" && $3 == "0.0.0.0:0" && substr($2, length($2) - length(p) + 1) == p { print $NF; exit }'
}

windows_port_reserved() {
    netsh int ipv4 show excludedportrange protocol=tcp | tr -d '\r' | awk -v p="$1" '
        $1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/ && p + 0 >= $1 + 0 && p + 0 <= $2 + 0 { found = 1 }
        END { exit !found }'
}

# Succeeds when something already listens on the port, or Windows reserves it.
port_taken() {
    if [ -n "${MSYSTEM:-}" ]; then
        # Git Bash: connecting to a closed port takes about two seconds on Windows.
        [ -n "$(windows_listener_pid "$1")" ] || windows_port_reserved "$1"
    else
        (exec 3<> "/dev/tcp/127.0.0.1/$1") 2> /dev/null
    fi
}

# Fails with a clear message when another program holds the port. Docker's own error
# for this is cryptic and differs between systems.
check_port_free() {
    local name="$1" port own id cname containers="" pid problem stop="" candidate other suggestion=""
    port="$(port_value "$name")"

    # Containers of this project may hold the port already: Compose reuses or replaces them.
    own=" $(compose ps -q 2> /dev/null | tr -d '\r' | tr '\n' ' ') "
    while read -r id cname; do
        [ -n "$id" ] || continue
        [[ "$own" != *" $id "* ]] || return 0
        containers="${containers:+$containers }$cname"
    done < <(docker ps --no-trunc --filter "publish=$port" --format '{{.ID}} {{.Names}}' | tr -d '\r')

    if [ -n "$containers" ]; then
        problem="is used by the Docker container $containers"
        stop="Stop it: docker stop $containers"
    elif ! port_taken "$port"; then
        return 0
    elif [ -n "${MSYSTEM:-}" ] && pid="$(windows_listener_pid "$port")" && [ -n "$pid" ]; then
        if [ "$pid" = 4 ]; then
            problem="is used by Windows itself (System process)"
        else
            problem="is used by $(tasklist /FI "PID eq $pid" /FO CSV /NH | tr -d '\r"' | cut -d, -f1) (process $pid)"
            stop="Close that program. If it is a Windows service, stop it in services.msc."
        fi
    elif [ -n "${MSYSTEM:-}" ]; then
        problem="is reserved by Windows (list: netsh int ipv4 show excludedportrange protocol=tcp)"
    else
        problem="is used by another program"
        stop="Close that program. To find it: sudo lsof -i :$port"
    fi

    # Windows reserves ports in blocks of 100, so look a bit further than that.
    for candidate in $(seq $((port + 1)) $((port + 200 > 65535 ? 65535 : port + 200))); do
        for other in ODOO_PORT POSTGRES_PORT PGADMIN_PORT; do
            [ "$(port_value "$other")" -eq "$candidate" ] && continue 2
        done
        if ! port_taken "$candidate"; then
            suggestion="$candidate"
            break
        fi
    done

    {
        echo "Error: Port $port ($name) $problem."
        [ -z "$stop" ] || echo "  - $stop"
        if [ -n "$suggestion" ]; then
            echo "  - Use another port: set $name=$suggestion in .env (free right now), then run the command again."
        else
            echo "  - Use another port: set another $name in .env, then run the command again."
        fi
        echo "Details: docs/troubleshooting.md#port-already-in-use"
    } >&2
    exit 1
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
    help|-h|--help) ;;
    *) check_docker ;;
esac

case "$cmd" in
    up)
        prepare
        check_port_settings
        check_port_free ODOO_PORT
        check_port_free POSTGRES_PORT
        read -r ENTERPRISE_COMMIT ENTERPRISE_COMMIT_TIME <<< "$(enterprise_commit)" || true
        export ENTERPRISE_COMMIT ENTERPRISE_COMMIT_TIME
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
        check_port_settings
        check_port_free PGADMIN_PORT
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
        compose_exec -u "$(id -u):$(id -g)" odoo odoo-docker-dev scaffold "$@"
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
