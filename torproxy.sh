#!/usr/bin/env bash
#===============================================================================
#          FILE: torproxy.sh
#
#         USAGE: ./torproxy.sh
#
#   DESCRIPTION: Entrypoint for torproxy docker container
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: David Personette (dperson@gmail.com),
#  ORGANIZATION:
#       CREATED: 09/28/2014 12:11
#      REVISION: 1.0
#===============================================================================

set -o nounset                              # Treat unset variables as an error

### timezone: Set the timezone for the container
# Arguments:
#   timezone) for example EST5EDT
# Return: the correct zoneinfo file will be symlinked into place
timezone() {
    local timezone="${1:-EST5EDT}"

    [[ -e /usr/share/zoneinfo/$timezone ]] || {
        echo "ERROR: invalid timezone specified" >&2
        return
    }

    ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
}

### usage: Help
# Arguments:
#   none)
# Return: Help text
usage() {
    local RC=${1:-0}

    echo "Usage: ${0##*/} [-opt] [command]
Options (fields in '[]' are optional, '<>' are required):
    -h          This help
    -t \"\"       Configure timezone
                possible arg: \"[timezone]\" - zoneinfo timezone for container

The 'command' (if provided and valid) will be run instead of torproxy
" >&2
    exit $RC
}

while getopts ":ht:" opt; do
    case "$opt" in
        h) usage ;;
        t) timezone "$OPTARG" ;;
        "?") echo "Unknown option: -$OPTARG"; usage 1 ;;
        ":") echo "No argument value for option: -$OPTARG"; usage 2 ;;
    esac
done
shift $(( OPTIND - 1 ))

[[ "${TIMEZONE:-""}" ]] && timezone "$TIMEZONE"


if [[ $# -ge 1 && -x $(which $1 2>&-) ]]; then
    exec "$@"
elif [[ $# -ge 1 ]]; then
    echo "ERROR: command not found: $1"
    exit 13
else
    chmod 0777 /dev/stderr /dev/stdout
    chown -Rh debian-tor. /var/lib/tor
    service tor start
    /usr/sbin/privoxy --user privoxy --no-daemon /etc/privoxy/config
fi
