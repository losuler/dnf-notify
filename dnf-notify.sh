#!/bin/bash

# Uncomment for debugging use
# set -o xtrace
set -o errexit
set -o pipefail
set -o nounset

CONFIG="/etc/dnf-notify/dnf-notify.conf"
LASTMESSAGE="/etc/dnf-notify/lastmessage"

usage() {
    cat << EOF
Usage: dnf-notify [OPTION]...
Check for and notify of new updates available.
  -c PATH       Path to the config file
  -h            Print help and exit
EOF
}

parse_args() { 
    while getopts "c:h" opt; do
        case "$opt" in
        c)  CONFIG="$OPTARG"
            ;;
        h)  usage
            exit 1
            ;;
        :)  echo "[ERROR] Required argument for option $OPTARG"
            exit 1
            ;;
        ?)  echo "[ERROR] Unrecognized option -$OPTARG"
            exit 1
            ;;
        esac
    done
    shift $((OPTIND-1))
}

matrix() {
    source /etc/os-release
    header="New $NAME updates available!"
    
    markdown_body="$header\n\`\`\`\n$updateinfo_json\n\`\`\`"
    html_body="<p>$header</p>\n<pre><code>$updateinfo_json</code></pre>\n"
    path="_matrix/client/r0/rooms/$MATRIX_ROOM:$MATRIX_DOMAIN/send/m.room.message"
    query="?access_token=$MATRIX_TOKEN"

    curl -X PUT --header 'Content-Type: application/json' \
        --header 'Accept: application/json' \
        -d "{\"msgtype\":\"m.text\",
        \"body\":\"$markdown_body\",
        \"format\":\"org.matrix.custom.html\",
        \"formatted_body\":\"$html_body\"}" \
        "https://$MATRIX_DOMAIN/$path/$(date +%s)$query" \
        --silent > /dev/null
}

parse_args "$@"

if [[ ! -f "$CONFIG" ]]; then
    echo "[ERROR] Config file does not exist."
    exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG"

# Ignore and capture exit code
dnf check-update --quiet > /dev/null && check_update=$? || \
    check_update=$? && true

if [[ $check_update != 100 ]]; then
    echo "[INFO] No updates available."
    exit 0
fi

updateinfo="$(dnf updateinfo --info --updates --quiet)"

# Not sure why this is empty sometimes, so fallback on check-update output
if [[ "$updateinfo" == "" ]]; then
    # Top line is empty for some reason
    updateinfo_json="$(dnf check-update --quiet | sed 1d | jq -Rs . | \
        # Escape double quotes in curl json input
        sed 's/\\"//g' | \
        # Remove leading double quote
        sed 's/^\"//g' | \
        # Remove trailing double quote
        sed 's/\"$//g' || true)"
else
    updateinfo_json="$(dnf updateinfo --info --updates --quiet | jq -Rs . | \
        # Escape double quotes in curl json input
        sed 's/\\"//g' | \
        # Remove leading double quote
        sed 's/^\"//g' | \
        # Remove trailing double quote
        sed 's/\"$//g')"
fi

if [[ -f "$LASTMESSAGE" ]]; then
    if [[ "$updateinfo_json" == "$(cat $LASTMESSAGE)" ]]; then
        echo "[INFO] Updateinfo unchanged. No notification required."
        exit 0
    fi
fi

if [[ "$MATRIX" == "enable" ]]; then
    matrix
    echo "[INFO] Updates available, notification sent."
    echo "$updateinfo_json" > "$LASTMESSAGE"
    exit 0
else
    echo "[ERROR] No notification service enabled."
    exit 1
fi
