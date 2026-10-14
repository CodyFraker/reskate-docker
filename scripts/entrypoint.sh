#!/bin/bash
set -euo pipefail

export HOME=/server
server="/server"

if [ ! -f "${server}/ReSkateServer" ]; then
    echo "Seeding ${server} from bundled server files..."
    mkdir -p "${server}"
    cp -a /opt/reskate-bundled/. "${server}/"
fi

mkdir -p "${server}/.steam/sdk64"
ln -sf ../../steamclient.so "${server}/.steam/sdk64/steamclient.so"

config="${server}/ReSkateServer.json"
if [ ! -f "${config}" ]; then
    listed="${LISTED:-true}"
    printf '{\n  "server": {\n    "listed": %s,\n    "port": %s,\n    "query_port": %s\n  }\n}\n' \
        "${listed}" "${SERVER_PORT:-27015}" "${QUERY_PORT:-27016}" > "${config}"
fi

patch_config() {
    local tmp
    tmp="$(mktemp)"
    jq "$1" "${config}" > "${tmp}"
    mv "${tmp}" "${config}"
}

if [ -n "${STEAM_TOKEN+x}" ]; then
    patch_config --arg token "${STEAM_TOKEN}" '.server.steam_token = $token'
fi

if [ -n "${LISTED+x}" ]; then
    case "${LISTED}" in
        true|false) listed_bool="${LISTED}" ;;
        *)
            echo "LISTED must be true or false, got: ${LISTED}" >&2
            exit 1
            ;;
    esac
    patch_config --argjson listed "${listed_bool}" '.server.listed = $listed'
fi

if [ -n "${SERVER_PORT+x}" ]; then
    patch_config --argjson port "${SERVER_PORT}" '.server.port = $port'
fi

if [ -n "${QUERY_PORT+x}" ]; then
    patch_config --argjson qport "${QUERY_PORT}" '.server.query_port = $qport'
fi

cd "${server}"
exec ./ReSkateServer
