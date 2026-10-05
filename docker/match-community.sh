#!/bin/bash
# Runs at image build time. Replaces the Community code of the official image with
# the Odoo nightly build that matches the Enterprise checkout.
#
# Enterprise (a Git clone) and the official image (published about once a week) move
# independently. When Enterprise relies on Community code newer or older than the
# image, modules fail with errors such as "cannot import name ...". Nightlies are the
# packages the official image is built from, published for nearly every day.
#
# Arguments, passed by odoo.sh / odoo.ps1 up:
#   $1  Enterprise commit hash   (stored in the image, checked by the entrypoint)
#   $2  Enterprise commit time   (Unix seconds)
# Without them (no Enterprise, or plain docker compose) the image is left as it is.

set -euo pipefail

commit="${1:-}"
commit_time="${2:-}"

log() { echo "[odoo-docker-dev] $*" >&2; }
die() { log "ERROR: $*"; exit 1; }

# Read by the entrypoint to notice an Enterprise checkout that moved after this build.
echo "$commit" > /etc/odoo/enterprise-commit

[ -n "$commit_time" ] || exit 0
[[ "$commit_time" =~ ^[0-9]+$ ]] || die "ENTERPRISE_COMMIT_TIME must be a Unix time, got '$commit_time'."

# ODOO_VERSION is set by the official image, e.g. 19.0.
base="https://nightly.odoo.com/$ODOO_VERSION/nightly/deb"
enterprise_day="$(date -u -d "@$commit_time" +%Y%m%d)"
installed="$(dpkg-query -W -f='${Version}' odoo)"
installed="${installed##*.}"

listing="$(curl -fsSL --retry 3 "$base/")" \
    || die "cannot reach $base to download the Odoo build matching Enterprise. Check the internet connection."
days="$(grep -oE "odoo_${ODOO_VERSION//./\\.}\.[0-9]{8}_all\.deb" <<< "$listing" \
    | grep -oE '[0-9]{8}_all' | cut -c1-8 | sort -u)" || true
[ -n "$days" ] || die "no Odoo $ODOO_VERSION builds found at $base."

# Nightlies are built early in the morning (UTC) from the code of that moment, so the
# first one after the day of the Enterprise commit contains all the Community code it
# relies on. For an Enterprise commit made today, the latest one is the closest match.
target="$(awk -v day="$enterprise_day" '$1 > day { print; exit }' <<< "$days")"
target="${target:-$(tail -n1 <<< "$days")}"

if [ "$target" = "$installed" ]; then
    log "Odoo Community build $installed already matches Enterprise from $enterprise_day."
    exit 0
fi
log "Enterprise is from $enterprise_day: replacing Odoo Community build $installed with $target."

deb="odoo_${ODOO_VERSION}.${target}_all.deb"
sha="$(curl -fsSL --retry 3 "$base/odoo_${ODOO_VERSION}.${target}_amd64.changes" \
    | awk -v file="$deb" '$3 == file && length($1) == 64 { print $1; exit }')" || true
[ -n "$sha" ] || die "no checksum published for $deb."

curl -fSL --retry 3 -o /tmp/odoo.deb "$base/$deb" || die "download of $base/$deb failed."
echo "$sha  /tmp/odoo.deb" | sha256sum -c --quiet - || die "checksum mismatch for $deb."

# New builds may need extra Ubuntu packages, hence apt-get rather than dpkg. Keep the
# image's odoo.conf, and allow going back to an older build for older Enterprise.
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --allow-downgrades \
    -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold /tmp/odoo.deb
rm -rf /var/lib/apt/lists/* /tmp/odoo.deb

[ "$(dpkg-query -W -f='${Version}' odoo)" = "$ODOO_VERSION.$target" ] \
    || die "Odoo build $target was not installed."
