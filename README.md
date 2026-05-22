Pre-requisites for running a local instance of QuantImage v2
========================================================================

Software to install
************************************************************************
The following software needs to be installed in order to set up a local instance
of QuantImage v2:
    
- [Git](https://github.com/git-guides/install-git) for cloning the repositories
- [Docker](https://docs.docker.com/install) (Docker Desktop `>=3.4` 
or Docker Engine `>=v20.10`, with Compose V2 enabled) for running the containers

Hosts file configuration
************************************************************************
In order to run the platform locally, the following entry needs to be added to 
your "hosts" file (`/etc/hosts` on Linux, `C:\Windows\System32\drivers\etc\hosts` 
on Windows):

```127.0.0.1 keycloak```

If the line specifying `127.0.0.1 localhost` exists in the hosts file, `keycloak`
can simply be appended to the end of that line.

Browser configuration
************************************************************************
Because of restrictions regarding third-party cookies in modern browsers, 
especially for unsecured HTTP connections, problems can appear with the Keycloak
client library which checks for authentication state using an `iframe` and
cookies. To avoid issues while testing the platform on `localhost`, please use
**Firefox** as a browser and disable the **"Enhanced Tracking Protection"** 
feature for both `localhost` and `keycloak` hosts.

Ensure that the two following urls / ports have disabled enhanced tracking protection:
- `localhost:3000`
- `keycloak:8081`

MAC OSX Development
************************************************************************

On MAC OS there are a few items to be cognizant of:
- Matlab and the [qdldl](https://github.com/osqp/qdldl-python) python package do not seem to work on the M1 mac - so until this hase been fixed or these dependencies removed local dev on mac M1 is not possible.
- Mounted volumes on root (i.e `/data`) will not work due to the root folder not being writable (i.e we cannot create a new folder in `/`)
- When cloning the repos with [setup-quantimage2.sh](setup-quantimage2.sh) - the commands to clone use `--config core.autocrlf=true` option but we have
seen the line breaks not being correct everywhere when cloning on mac with this option. If you clone manually make sure to use this option.

Setting up the QuantImage v2 platform
========================================================================
Open a Terminal in the current directory, and run the following command:

```./setup-quantimage2.sh```

This will clone all the required repositories, generate secrets automatically
and ask for passwords for the Keycloak authentication platform and a sample
user for QuantImage v2 & Kheops.

It will then build all the necessary Docker images and create all the
containers required to run the platform.

The backend is started with `docker compose --profile dev up -d`. The `--profile dev`
flag is what enables the Keycloak service defined under
that profile in the compose file. Without it, Keycloak will not start.

### `DEV_MODE` option

At the top of [setup-quantimage2.sh](setup-quantimage2.sh) there is a `DEV_MODE`
variable that controls how the platform is brought up:

- `DEV_MODE=0` (local production-like setup): Kheops, the backend and the frontend
  are all started in Docker, using the base compose file together with
  `docker-compose.local.yml` (i.e. `-f docker-compose.yml -f docker-compose.local.yml`).
  This is the right mode if you just want to *use* the platform locally.
- `DEV_MODE=1` (development): Kheops and the backend are started with plain
  `docker compose up -d` (no `local` overrides), and the frontend container is
  **not** started. The frontend is expected to be run directly on the host with
  Node.js and Yarn, so you can develop against it with hot-reload. See the section
  below for installing Node and Yarn.

Installing Node.js and Yarn for frontend development
========================================================================

When running with `DEV_MODE=1`, the frontend is not started as a container —
you run it directly with Node.js and Yarn. The frontend targets **Node.js 18 LTS**.

The frontend already pins its Yarn version via the `packageManager` field in
`package.json` (currently `yarn@1.22.22`). The recommended setup is therefore:

1. Install Node.js 18.
2. Enable **Corepack** (ships with Node.js 16.9+) — it will read the
   `packageManager` field and automatically download / use the exact Yarn
   version the project expects.
3. Run `yarn install` in the frontend directory.

**Do not** run `yarn set version ...` — that would overwrite the project's
pinned version. And `npm install -g yarn` is no longer recommended; let
Corepack manage it.

### Linux

Install Node.js 18 via [nvm](https://github.com/nvm-sh/nvm) (recommended, no `sudo`
needed and easy to switch versions):

```
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
# restart your shell, then:
nvm install 18
nvm use 18
node -v  # Should print "v18.x"
```

Enable Corepack (Yarn will be installed automatically on first use, at the
version pinned in `package.json`):

```
corepack enable
```

### Windows

The standard practice on Windows is to use
[nvm-windows](https://github.com/coreybutler/nvm-windows) for Node.js and
**Corepack** for Yarn.

**1. Install nvm-windows**

Open PowerShell or Command Prompt. If `winget` is available, run:

```
winget install CoreyButler.NVMforWindows
```

(Alternatively, download and run `nvm-setup.exe` from the
[nvm-windows GitHub releases](https://github.com/coreybutler/nvm-windows/releases).)

Restart the terminal, then install Node.js 18 and set it as active:

```
nvm install 18
nvm use 18
```

**2. Enable Yarn via Corepack**

```
corepack enable
```

### Running the frontend

From the `quantimage2-frontend` directory:

```
yarn install
yarn start
```

The first `yarn` call will trigger Corepack to download Yarn `1.22.22` (the
version pinned in `package.json`) — subsequent calls are instant. Verify with:

```
node -v   # v18.x
yarn -v   # 1.22.22
```

Updating QuantImage v2
========================================================================

Open a Terminal in the current directory, and run the following command:

```./update-quantimage2.sh```

This will pull the latest versions of the QuantImage v2 repositories
and rebuild the Docker containers accordingly.