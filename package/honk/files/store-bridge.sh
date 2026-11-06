#!/bin/sh
# store-bridge.sh - keep the configuration database in step with the file tree.
#
# In db mode the core owns the running configuration: the file tree is read
# once, at the first start, and every later change to the file reaches the
# database only through an import.  The upstream contract says so explicitly:
# "File edits reach the database only through import with replace:true".
#
# This helper performs that import, but only when the file actually changed
# since the last import, so a change made in the Doona panel - which lives in
# the database - is not reverted by a restart.
#
# usage: store-bridge.sh import <api-listen> [config]
#
# The administrator password is needed for the import call.  The
# initialization stored it in a root-only file; without that file the helper
# does nothing and the database keeps the revision it has.
set -u

CORE=${HONK_BRIDGE_CORE:-/usr/bin/honk-core}
CREDENTIAL=${HONK_BRIDGE_CREDENTIAL:-/etc/.honk-admin-credential}
MARKER=${HONK_BRIDGE_MARKER:-/etc/honk/.file-import-hash}
LOG=${HONK_BRIDGE_LOG:-/var/log/honk-store-bridge.log}
WAIT=${HONK_BRIDGE_WAIT:-60}

log() {
	[ -n "${HONK_BRIDGE_QUIET:-}" ] && return 0
	printf '%s store-bridge: %s\n' "$(date '+%F %T' 2>/dev/null)" "$1" >> "$LOG" 2>/dev/null || :
}

fail() {
	log "$1"
	exit "${2:-1}"
}

json_string() {
	# A JSON string body without the quotes.  The password never contains a
	# newline (the form cannot produce one), so dropping them is enough.
	printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\r/\\r/g' | tr -d '\n' | sed -e 's/\t/\\t/g'
}

[ "${1:-}" = "import" ] || fail "usage: store-bridge.sh import <api-listen> [config]" 64
LISTEN=${2:-}
CONFIG=${3:-/etc/honk/config.dae}

[ -n "$LISTEN" ] || fail "no api listen address" 64
[ -x "$CORE" ] || fail "the core is missing" 1
[ -f "$CONFIG" ] || fail "the configuration file is missing" 1

file_hash=$(sha256sum "$CONFIG" 2>/dev/null | awk '{print $1}')
[ -n "$file_hash" ] || fail "the configuration file cannot be read" 1

marker_hash=$(cat "$MARKER" 2>/dev/null)
if [ "$file_hash" = "$marker_hash" ]; then
	# The file did not change since the last import.  A revision made in the
	# panel stays in charge.
	log "the configuration file is unchanged, nothing to import"
	exit 0
fi

if [ ! -f "$CREDENTIAL" ] || [ -L "$CREDENTIAL" ]; then
	# No stored administrator credential: the import cannot be authenticated.
	# The running revision stays as it is.
	fail "no stored administrator credential, the file was not imported" 3
fi

url="http://$LISTEN"

# The core may still be starting; wait for the listener.
waited=0
until curl -fsS --noproxy '*' --connect-timeout 2 --max-time 5 -o /dev/null "$url/api" 2>/dev/null; do
	waited=$((waited + 2))
	[ "$waited" -ge "$WAIT" ] && fail "the api did not answer, the file was not imported" 5
	sleep 2
done

username=$(sed -n '1p' "$CREDENTIAL" 2>/dev/null)
password=$(sed -n '2p' "$CREDENTIAL" 2>/dev/null)
[ -n "$username" ] || fail "the stored credential has no user name" 3

body=$(printf '{"username":"%s","password":"%s"}' "$(json_string "$username")" "$(json_string "$password")")
login_file=$(mktemp /tmp/honk-store-bridge-login.XXXXXX) || fail "no temporary space" 1
code=$(printf '%s' "$body" | curl -sS --noproxy '*' --connect-timeout 3 --max-time 15 \
	-o "$login_file" -w '%{http_code}' -X POST "$url/api/v1/auth/login" \
	-H 'Content-Type: application/json' --data-binary @- 2>/dev/null)
session=$(grep -o '"token":"[^"]*"' "$login_file" 2>/dev/null | head -1 | cut -d'"' -f4)
rm -f "$login_file" 2>/dev/null
case "$code" in
	2*|3*) : ;;
	*) fail "the administrator login failed (http ${code:-000})" 4 ;;
esac
[ -n "$session" ] || fail "the administrator login returned no session" 4

# The key binds the request to one import.  The file hash keeps a different
# content apart, the timestamp keeps a repeated import of the same content
# apart as well.
key="file-${file_hash}-$(date +%s 2>/dev/null)"
response=$(mktemp /tmp/honk-store-bridge-import.XXXXXX) || fail "no temporary space" 1
code=$(curl -sS --noproxy '*' --connect-timeout 3 --max-time 30 \
	-o "$response" -w '%{http_code}' -X POST "$url/api/v1/x-honk/config/import" \
	-H "Authorization: Bearer $session" -H 'Content-Type: application/json' \
	-H "Idempotency-Key: $key" --data-binary '{"replace":true}' 2>/dev/null)
operation=$(grep -o '"operation_id":"[^"]*"' "$response" 2>/dev/null | head -1 | cut -d'"' -f4)
rm -f "$response" 2>/dev/null
case "$code" in
	202) : ;;
	409) fail "another import is in flight, the file waits for the next start" 5 ;;
	*) fail "the import was refused (http ${code:-000})" 6 ;;
esac
[ -n "$operation" ] || fail "the import returned no operation" 6

waited=0
while [ "$waited" -lt 90 ]; do
	sleep 2
	waited=$((waited + 2))
	status=$(curl -sS --noproxy '*' --connect-timeout 3 --max-time 10 \
		-H "Authorization: Bearer $session" "$url/api/v1/operations/$operation" 2>/dev/null |
		grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)
	case "$status" in
		succeeded)
			printf '%s' "$file_hash" > "$MARKER" 2>/dev/null || :
			chmod 0600 "$MARKER" 2>/dev/null || :
			log "the configuration file was imported and recorded as a revision"
			exit 0
			;;
		failed)
			fail "the import failed, the running revision is unchanged" 7
			;;
	esac
done

fail "the import did not finish in time, the running revision is unchanged" 8
