#!/bin/bash
# ReSkate dedicated server (Linux): download the release tarball named in launcher.json
# ("server_linux"), verify SHA-256, and unpack into SERVER_DIR.
# Derived from https://github.com/Dingo-Shenanigans/ReSkate/blob/main/contrib/pterodactyl/install.sh
set -euo pipefail

repo="https://github.com/Dingo-Shenanigans/ReSkate"
release="${RELEASE:-latest}"
server="${SERVER_DIR:?SERVER_DIR must be set}"

if [ -z "${release}" ] || [ "${release}" = "latest" ]; then
    base="${repo}/releases/latest/download"
else
    base="${repo}/releases/download/${release}"
fi

mkdir -p "${server}"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

echo "Reading ${base}/launcher.json"
curl -fsSL --retry 3 -o "${work}/launcher.json" "${base}/launcher.json"
url="$(jq -r '.server_linux.url // empty' "${work}/launcher.json")"
sha="$(jq -r '.server_linux.sha256 // empty' "${work}/launcher.json")"
version="$(jq -r '.server_linux.version // empty' "${work}/launcher.json")"
if [ -z "${url}" ] || [ -z "${sha}" ]; then
    echo "This release has no Linux server (no \"server_linux\" in launcher.json). Use 1.1.4 or newer."
    exit 1
fi
case "${url}" in
    asset:*) url="${base}/${url#asset:}" ;;
    https://*) ;;
    *) echo "launcher.json names no usable download: ${url}"; exit 1 ;;
esac

echo "Downloading the ReSkate Linux server ${version}"
curl -fSL --retry 3 -o "${work}/server.tar.gz" "${url}"
echo "${sha}  ${work}/server.tar.gz" | sha256sum -c -
tar -xzf "${work}/server.tar.gz" -C "${server}" --strip-components=1
chmod +x "${server}/ReSkateServer"

mkdir -p "${server}/.steam/sdk64"
ln -sf ../../steamclient.so "${server}/.steam/sdk64/steamclient.so"

echo "${version}" > "${server}/.reskate-bundled-version"
echo "Installed the ReSkate Linux server ${version}."
