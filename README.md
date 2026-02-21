_This project has been created as part of the 42 curriculum by edobele._

# Inception

## Description

Inception is a system administration project from the 42 curriculum. The goal is to build and orchestrate a small production-like web infrastructure entirely from custom Docker images, without using any pre-built service images from Docker Hub. Every service runs in its own dedicated container, wired together by a single `docker-compose.yml`.

The stack exposes a WordPress site served over HTTPS (TLS 1.2/1.3 only) by an Nginx reverse proxy, backed by a MariaDB database. All persistent data lives on the host under `/home/edobele/data/` through Docker bind mounts. Three custom images are built from Debian Bookworm: **Nginx** (reverse proxy, self-signed TLS), **WordPress** (PHP-FPM, bootstrapped via WP-CLI), and **MariaDB** (database, initialised from a custom entrypoint).

The full repository layout, environment variable reference, and detailed container/volume management commands are documented in [DEV_DOC.md](DEV_DOC.md). Instructions for accessing the site, the admin panel, and checking service health are in [USER_DOC.md](USER_DOC.md).

## Instructions

> For a complete step-by-step setup guide, see [DEV_DOC.md](DEV_DOC.md).

**Quick start:**

1. Install Docker Engine, Docker Compose v2, and Make.
2. Create host data directories: `mkdir -p /home/edobele/data/db /home/edobele/data/wp`
3. Create `srcs/.env` and fill in every variable (see the variable table in [DEV_DOC.md](DEV_DOC.md)).
4. Build and run: `make up`

```bash
make build    # Build images
make up       # Start the stack
make status   # Show running containers
make logs     # Follow live logs
make down     # Stop and remove containers (data kept)
make fclean   # Stop + wipe all data volumes
make re       # Full cold restart (fclean → build → up)
```

Configuration is injected entirely through `srcs/.env` (database credentials, WordPress admin account, site URL, Nginx server name). **Never commit the actual `.env` file.**

## Project Description

Docker is used to build and orchestrate three custom service containers (Nginx, WordPress PHP-FPM, MariaDB) from Debian Bookworm base images, wired by a user-defined bridge network and persisted through bind mounts. No pre-built service images from Docker Hub are used. Full architecture details, design choices, and the repository layout are described in [DEV_DOC.md](DEV_DOC.md).

### Comparisons

#### Virtual Machines vs Docker

A Virtual Machine emulates an entire hardware environment and runs a full guest OS (kernel included) on top of a hypervisor. This gives strong isolation but carries significant overhead: slow boot times, large disk images, and high memory usage per VM.

Docker containers share the host kernel and only package the application's userland. They start in milliseconds, layered images are cached and small, and dozens of containers run comfortably on hardware where only a handful of VMs would fit. The trade-off is a reduced (though still substantial) isolation boundary: a kernel vulnerability can affect all containers.

For this project containers are the right tool — lightweight, reproducible, and trivially composable.

#### Secrets vs Environment Variables

Environment variables are the simplest way to pass configuration into a container: they are set in `.env`, read by Docker Compose, and available to every process in the container. The downside is that they end up in the process environment table, Docker inspect output, and any log that accidentally prints `env` — all of which are visible to anyone with access to the host or the image.

Docker Secrets (or equivalent solutions such as HashiCorp Vault) mount sensitive values as in-memory files inside the container (`/run/secrets/<name>`), never placing them in environment variables. They are encrypted at rest in the Swarm state store and transmitted securely to workers.

The 42 subject mandates the use of an `.env` file, so this project uses environment variables — acceptable for a local learning environment, but **inappropriate for production** where Docker Secrets or a secrets manager should be used instead.

#### Docker Network vs Host Network

With `--network host` a container is not isolated at the network level: it shares the host's network stack, which means it sees all host interfaces and processes on the same port space. This removes NAT overhead and can improve raw throughput, but eliminates name-based service discovery, increases the attack surface, and makes port conflicts easy to create.

User-defined bridge networks (used here) provide a private virtual network for the containers. Each service is reachable under its service name (`mariadb`, `wordpress`, `nginx`) without any `/etc/hosts` hacks. Only explicitly published ports (`443:443` on Nginx) are reachable from the host. This is the standard and recommended approach for multi-container applications.

#### Docker Volumes vs Bind Mounts

|               | Docker Volumes                                  | Bind Mounts                        |
| ------------- | ----------------------------------------------- | ---------------------------------- |
| Path location | Managed by Docker in `/var/lib/docker/volumes/` | Any path on the host               |
| Portability   | High — path is abstracted                       | Low — host path is hardcoded       |
| Inspection    | Via `docker volume inspect`                     | Directly on the filesystem         |
| Use case      | Production, portable setups                     | Dev workflows, explicit host paths |

The 42 subject explicitly requires bind mounts under `/home/<login>/data/`, so this project uses bind mounts configured as named volumes with `driver_opts: {type: none, o: bind, device: ...}`. In a real production scenario, managed Docker volumes (or cloud-native storage) would be preferable.

## Resources

- Docker Engine documentation — https://docs.docker.com/engine/
- Docker Compose reference — https://docs.docker.com/compose/compose-file/
- MariaDB knowledge base — https://mariadb.com/kb/en/
- WP-CLI command reference — https://developer.wordpress.org/cli/commands/
- Nginx documentation — https://nginx.org/en/docs/
- OpenSSL man pages — https://www.openssl.org/docs/manmaster/man1/openssl.html
- PHP-FPM configuration — https://www.php.net/manual/en/install.fpm.configuration.php

### AI usage

AI assistance (GitHub Copilot / Claude) was used during this project for the following tasks:

- Learning and understanding Docker concepts: image layering, container lifecycle, networking, volumes, and Docker Compose orchestration.
- Drafting and iterating on Nginx TLS configuration and the `wordpress.conf.template`.
- Debugging the MariaDB init entrypoint script and the WordPress WP-CLI bootstrap sequence.
- Generating the first pass of this README and restructuring it to meet the requirements.
- Translating the original README, which was written in French, into English.

All AI-generated output was reviewed, tested, and adjusted manually to fit the project constraints (custom images, mandatory host paths, subject rules). No AI-written code was committed without understanding and validating it.
