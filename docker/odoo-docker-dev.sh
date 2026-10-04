#!/bin/bash
# In-container helper used by odoo.sh / odoo.ps1.
# Keeping the logic here means it is written once and behaves the same on every host OS.

set -euo pipefail

CONF="${ODOO_RC:-/etc/odoo/odoo.conf}"

# psql is a Perl wrapper on Ubuntu and warns when en_US.UTF-8 is not generated.
export LC_ALL=C.UTF-8
BACKUP_DIR=/mnt/backups
CUSTOM_DIR=/mnt/custom-addons
HTTP_URL="http://localhost:8069"

die() { echo "Error: $*" >&2; exit 1; }

conf_get() {
    sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" "$CONF" | tail -n1 | tr -d '\r'
}

PGHOST="$(conf_get db_host)"
PGPORT="$(conf_get db_port)"
PGUSER="$(conf_get db_user)"
PGPASSWORD="$(conf_get db_password)"
export PGHOST PGPORT PGUSER PGPASSWORD

# The plain master password. Not read from $CONF: when the password is "admin", the
# database manager replaces it there with a hash, which it then rejects as a password.
master_password() {
    local value
    value="$(sed -n "s/^[[:space:]]*admin_passwd[[:space:]]*=[[:space:]]*//p" /etc/odoo/odoo.base.conf 2> /dev/null \
        | tail -n1 | tr -d '\r')"
    echo "${value:-${ADMIN_PASSWORD:-admin}}"
}

default_db() {
    echo "${1:-${ODOO_DB:-odoo}}"
}

# The server may still be starting, e.g. right after `up` or a restart.
wait_for_http() {
    local i
    for i in $(seq 1 60); do
        curl -fs -o /dev/null "$HTTP_URL/web/health" && return 0
        [ "$i" -eq 1 ] && echo "Waiting for Odoo to accept requests..."
        sleep 1
    done
    die "Odoo is not responding. Check the Odoo logs (the logs command)."
}

db_exists() {
    # Passed as a psql variable (via stdin, as -c does not expand them) to avoid quoting issues.
    echo "SELECT 1 FROM pg_database WHERE datname = :'db'" \
        | psql -d postgres -Atq -v db="$1" | grep -q 1
}

list_dbs() {
    psql -d postgres -Atc \
        "SELECT datname FROM pg_database WHERE NOT datistemplate AND datname <> 'postgres' ORDER BY 1"
}

usage() {
    cat <<'EOF'
Usage: odoo-docker-dev <command> [arguments]

Database commands (DB defaults to ODOO_DB from .env):
  install <modules> [db]   Install comma-separated modules (creates the database if needed)
  update <modules> [db]    Update comma-separated modules
  test <modules>           Run module tests in a fresh throwaway database
  shell [db]               Open an interactive Odoo shell
  psql [db]                Open psql connected to the database
  dbs                      List databases
  backup [db]              Save a backup zip into backups/ (restorable from the web UI too)
  restore <file> [db]      Restore a zip from backups/ as a new database
                           (add --neutralize for a copy of a production database)

Development:
  scaffold <name>          Create a new module skeleton in addons/custom
EOF
}

cmd="${1:-help}"
shift || true

# Refresh addons_path so modules added since the container started are found.
case "$cmd" in
    install|update|test|shell) odoo-docker-dev-entrypoint --configure-only ;;
esac

case "$cmd" in
    install|update)
        [ $# -ge 1 ] || die "missing module name. Example: $cmd sale,crm"
        db="$(default_db "${2:-}")"
        if ! db_exists "$db"; then
            existing="$(list_dbs | paste -sd, -)"
            [ "$cmd" = install ] || die "database '$db' does not exist. Existing: ${existing:-<none>}"
            echo "Database '$db' does not exist yet: creating it (login: admin, password: admin)."
        fi
        flag=$([ "$cmd" = install ] && echo -i || echo -u)
        exec odoo -d "$db" "$flag" "$1" --stop-after-init --no-http
        ;;

    test)
        [ $# -ge 1 ] || die "missing module name. Example: test my_module"
        db="test_${1//,/_}"
        tags="$(echo "$1" | sed 's/[^,]*/\/&/g')"
        echo "Running tests for '$1' in fresh database '$db'..."
        # --force closes connections left open, e.g. by a browser tab on that database.
        dropdb --if-exists --force "$db"
        # A separate HTTP port avoids clashing with the running server (needed by HttpCase).
        exec odoo -d "$db" -i "$1" --test-enable --test-tags "$tags" \
            --stop-after-init --http-port 8070 --log-level test
        ;;

    shell)
        exec odoo shell -d "$(default_db "${1:-}")" --no-http
        ;;

    psql)
        exec psql -d "$(default_db "${1:-}")"
        ;;

    dbs)
        list_dbs
        ;;

    info)
        paths="$(conf_get addons_path)"
        dbs="$(list_dbs | paste -sd, - | sed 's/,/, /g')"
        echo "Odoo version: ${ODOO_VERSION:-unknown}"
        echo "Addons path:  ${paths:-<community modules only>}"
        echo "Default DB:   $(default_db "")"
        echo "Databases:    ${dbs:-<none>}"
        ;;

    backup)
        db="$(default_db "${1:-}")"
        db_exists "$db" || die "database '$db' does not exist"
        wait_for_http
        file="$BACKUP_DIR/${db}_$(date +%Y%m%d_%H%M%S).zip"
        echo "Backing up '$db' (database + filestore)..."
        curl -sS --fail -o "$file" \
            --form-string "master_pwd=$(master_password)" \
            --form-string "name=$db" \
            --form-string "backup_format=zip" \
            "$HTTP_URL/web/database/backup"
        if [ "$(head -c2 "$file")" != "PK" ]; then
            rm -f "$file"
            die "backup failed. Check the master password (ADMIN_PASSWORD) and that list_db is enabled."
        fi
        echo "Saved backups/$(basename "$file")"
        ;;

    restore)
        # --neutralize may appear anywhere among the arguments.
        neutralize=()
        args=()
        for arg in "$@"; do
            if [ "$arg" = --neutralize ]; then
                # Odoo treats any value as true, so the field is only sent when wanted.
                neutralize=(--form-string "neutralize_database=true")
            else
                args+=("$arg")
            fi
        done
        set -- "${args[@]}"
        [ $# -ge 1 ] || die "missing file name. Example: restore mydb_20260101_120000.zip"
        file="$BACKUP_DIR/$(basename "$1")"
        [ -f "$file" ] || die "file not found: backups/$(basename "$1")"
        db="$(default_db "${2:-}")"
        db_exists "$db" && die "database '$db' already exists. Pass another name: restore $1 <new_db>"
        wait_for_http
        echo "Restoring backups/$(basename "$file") as '$db'..."
        curl -sS --fail -o /dev/null \
            --form-string "master_pwd=$(master_password)" \
            --form-string "name=$db" \
            --form-string "copy=true" \
            "${neutralize[@]}" \
            -F "backup_file=@$file" \
            "$HTTP_URL/web/database/restore"
        db_exists "$db" || die "restore failed. Check the master password and the Odoo logs."
        if [ ${#neutralize[@]} -gt 0 ]; then
            echo "Restored '$db', neutralized: no emails sent, scheduled actions and payment providers off."
        else
            echo "Restored '$db'."
        fi
        ;;

    scaffold)
        [ $# -ge 1 ] || die "missing module name. Example: scaffold my_module"
        [ -e "$CUSTOM_DIR/$1" ] && die "addons/custom/$1 already exists"
        odoo scaffold "$1" "$CUSTOM_DIR"
        echo "Created addons/custom/$1"
        ;;

    help|-h|--help)
        usage
        ;;

    *)
        usage >&2
        exit 1
        ;;
esac
