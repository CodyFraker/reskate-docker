# reskate-docker

Unofficial Docker image for the [ReSkate](https://github.com/Dingo-Shenanigans/ReSkate) dedicated server (Linux). It bundles the official release tarball from GitHub (verified with `launcher.json` SHA-256), same approach as [ReSkate’s Pterodactyl egg](https://github.com/Dingo-Shenanigans/ReSkate/tree/main/contrib/pterodactyl).

Server settings and commands: [Server/README.txt](https://github.com/Dingo-Shenanigans/ReSkate/blob/main/Server/README.txt). Linux notes: [Server/README-linux.md](https://github.com/Dingo-Shenanigans/ReSkate/blob/main/Server/README-linux.md).

## Requirements

- **linux/amd64** host (Unraid x86_64 is fine)
- **Host networking** recommended ([why](https://skatemods.com/guides/host-a-reskate-server/))
- ~256 MB RAM, ~300 MB+ disk for the image; more for `Mods/` and logs
- Writable data directory mounted at `/server`

## Quick start

```sh
docker run -d \
  --name reskate \
  --restart unless-stopped \
  --network host \
  -v /path/to/reskate-data:/server \
  ghcr.io/<your-github-user>/reskate-docker:latest
```

On first start the container copies the bundled server into `/server`, writes `ReSkateServer.json` if needed, and starts `ReSkateServer`.

1. Edit `/path/to/reskate-data/ReSkateServer.json` — set `server.name` at minimum.
2. Open the container logs and run `role <your SteamID64> admin` in the server console (or edit `data/roles.json` while stopped). See [ROLES.md](https://github.com/Dingo-Shenanigans/ReSkate/blob/main/Server/ROLES.md).

Optional UDP **27015** and **27016** on the host improve browser ping and join speed; relay play works without opening ports.

## Unraid

1. **Docker** → **Add Container**
2. **Repository:** `ghcr.io/<your-github-user>/reskate-docker:latest`
3. **Network Type:** **Host**
4. **Path:** `/mnt/user/appdata/reskate-docker` → **Container path** `/server`
5. **Restart policy:** unless-stopped
6. Optional **Environment variables** (see table below), e.g. `STEAM_TOKEN` for a persistent Steam server ID

Configure the server via files under appdata (`ReSkateServer.json`, `Mods/`, `data/`).

## Environment variables

Applied on **each start** when the variable is set (merged into `ReSkateServer.json` with `jq`).

| Variable | Default | Description |
|----------|---------|-------------|
| `STEAM_TOKEN` | (unset) | Steam game server login token ([App ID 3354750](https://steamcommunity.com/dev/managegameservers)); empty string clears it |
| `LISTED` | `true` | `true` / `false` — browser listing |
| `SERVER_PORT` | `27015` | Game UDP port (meaningful with host network or direct UDP) |
| `QUERY_PORT` | `27016` | Query UDP port |

Build-time only (local `docker build` / CI): `RESKATE_RELEASE` = `latest` or a tag like `v2.0.2`.

## Custom maps

Copy map mod folders into `Mods/` on the volume. Every player needs the same mod. Link mods in `server.welcome_message` if you use custom maps.

## Updates

- **In-container (default):** `auto_update` in `ReSkateServer.json` lets the server install new releases when the lobby is empty (`curl` + `tar` in the image). The volume must be writable.
- **New image:** Pull a newer `ghcr.io/.../reskate-docker` tag when published; existing `/server` data is kept. To refresh binaries from the image, remove `ReSkateServer` on the volume and restart (back up config first), or rely on self-update.

## Build locally

```sh
docker build --build-arg RESKATE_RELEASE=latest -t reskate-docker:local .
docker compose up -d
```

## GitHub Actions → GHCR

Pushes to `main`, tags `v*`, manual **workflow dispatch**, and a weekly schedule can publish to:

`ghcr.io/<repository-owner>/reskate-docker`

Tags include `latest` (from `main` / dispatch / schedule) and the ReSkate `server_linux.version` (e.g. `2.0.2`).

After the first publish:

1. Enable **Actions** on the repo.
2. Under **Packages** → this image → **Package settings**, set visibility to **Public** if you want open pulls without auth.

## License

GPL-3.0 — see [LICENSE](LICENSE). ReSkate is a separate project; this repository only packages its published Linux server binary.
