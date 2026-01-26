*This project has been created as part of the 42 curriculum by edobele.*

# Inception

## Description
Inception is a Docker-based stack that runs WordPress behind Nginx with MariaDB. The goal is to build and orchestrate custom images (no prebuilt Docker Hub images) using Docker Compose, with persistent data stored under `/home/edobele/data/`. The project demonstrates containerization basics, service isolation, TLS termination, and data persistence for a simple web app.

## Instructions
### Prerequisites
- Docker and Docker Compose installed
- Host folders exist: `/home/edobele/data/db` and `/home/edobele/data/wp`

### Environment variables (`srcs/.env`)
- Database: `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`
- WordPress: `WORDPRESS_DB_NAME`, `WORDPRESS_DB_USER`, `WORDPRESS_DB_PASSWORD`, `WORDPRESS_DB_HOST`, `WP_TITLE`, `WP_ADMIN_USER`, `WP_ADMIN_PASSWORD`, `WP_ADMIN_EMAIL`, `WP_URL`
- Nginx: `SERVER_NAME`

### Build & Run
From the project root (Makefile wrappers):
```bash
make build   # Build images
make up      # Start stack in background
make status  # Show container status
make logs    # Follow logs
```
Direct Compose (inside srcs/):
```bash
cd srcs
docker compose build
docker compose up -d
```

### Stopping & Cleaning
```bash
make down    # Stop and remove containers/network
make clean   # Same as down, keep volumes
make fclean  # Remove containers, network, and data under /home/edobele/data/{db,wp}
make re      # Full rebuild and restart
```

## Project Description
- **Docker usage:** Three custom images (MariaDB, WordPress PHP-FPM, Nginx) built from `srcs/requirements/*` and orchestrated with a single `docker-compose.yml`. Nginx terminates TLS on 443 and proxies PHP to WordPress on 9000; WordPress connects to MariaDB on 3306; both data and files persist via bind mounts under `/home/edobele/data/`.
- **Sources layout:**
  - `srcs/docker-compose.yml` – services, network, volumes
  - `srcs/requirements/mariadb` – DB image and init script
  - `srcs/requirements/wordpress` – PHP-FPM image and WP setup script
  - `srcs/requirements/nginx` – reverse proxy image, TLS self-signed at boot
  - `srcs/.env` – environment configuration
- **Main design choices:**
  - Build everything from Debian Bookworm base images (no prebuilt service images)
  - Use bind mounts under the mandated host path for persistence
  - Simple TLS: self-signed certificate generated at container start
  - WordPress bootstraps itself via WP-CLI; MariaDB initialized via a custom entrypoint

### Comparisons
- **Virtual Machines vs Docker:** VMs virtualize hardware and need full guest OS; Docker shares the host kernel, yielding lighter resource use, faster startup, and easier layering while still providing process-level isolation.
- **Secrets vs Environment Variables:** Secrets are preferable for sensitive data (mounted as files, not in env); here, the subject mandates `.env`, so credentials reside in environment variables—acceptable for a local learning stack but weaker than secrets in production.
- **Docker Network vs Host Network:** A user-defined bridge isolates services with internal DNS names and avoids port conflicts; host networking would expose services directly on the host stack and reduce isolation. We keep bridge for separation and predictable service discovery.
- **Docker Volumes vs Bind Mounts:** Managed volumes abstract host paths and are portable; bind mounts map explicit host directories for transparency and easy inspection. The subject requires bind mounts under `/home/edobele/data/`, so we use bind mounts for DB and WP data.

## Resources
- Docker Docs: https://docs.docker.com/
- Docker Compose: https://docs.docker.com/compose/
- MariaDB Docs: https://mariadb.com/kb/en/
- WordPress + WP-CLI: https://developer.wordpress.org/cli/commands/
- Nginx Docs: https://nginx.org/en/docs/

### AI Usage
- Used AI assistance to draft and refine Docker entrypoint scripts, Nginx/WordPress configs, and this README to ensure compliance with the stated requirements. All outputs were reviewed and adjusted manually to fit the 42 subject constraints (custom images, bind mounts, TLS self-sign, service wiring).

## Quick Usage Example
```bash
make up
curl -kI https://localhost/   # Expect 302 to /wp-admin/install.php on first run
```

---
If you need a fresh start: `make fclean && make up`.# Inception

Petit stack auto-hébergée WordPress/MariaDB/Nginx avec Docker Compose, volumes persistants dans `/home/edobele/data/` et images custom (pas d’images DockerHub pré-construites, conformément au sujet 42).

## Composition
- MariaDB (build `requirements/mariadb`) – DB WordPress
- WordPress PHP-FPM (build `requirements/wordpress`) – application
- Nginx (build `requirements/nginx`) – reverse proxy HTTPS 443
- Réseau: bridge `inception`
- Volumes: `/home/edobele/data/db` (MySQL), `/home/edobele/data/wp` (WordPress fichiers)

## Prérequis
- Docker + Docker Compose
- Dossiers de données présents: `/home/edobele/data/db`, `/home/edobele/data/wp`

## Variables d’environnement (fichier `srcs/.env`)
```
# DB
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=wp_password
MYSQL_ROOT_PASSWORD=root_password

# WordPress
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wpuser
WORDPRESS_DB_PASSWORD=wp_password
WORDPRESS_DB_HOST=mariadb
WP_TITLE=My WordPress
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=admin_password
WP_ADMIN_EMAIL=admin@example.com
WP_URL=https://localhost

# Nginx
SERVER_NAME=localhost
```

## Démarrage rapide
Depuis `srcs/` (ou via le Makefile à la racine):
```bash
cd srcs
docker compose build
docker compose up -d
docker compose logs -f
```
Ou avec le Makefile (à la racine):
```bash
make up      # build + up si nécessaire
make status  # état des services
make logs    # suivre les logs
```

## Accès
- Site: https://localhost (certificat auto-signé généré au démarrage)
- Admin WP après installation: https://localhost/wp-admin

## Persistance
- Base: `/home/edobele/data/db`
- Fichiers WP: `/home/edobele/data/wp`

## Cibles Make utiles
- `make build` : build des images
- `make up` : démarre les services en détaché
- `make down` : arrête et supprime conteneurs/réseau
- `make clean` : idem down (garde les volumes)
- `make fclean` : supprime aussi les données (`/home/edobele/data/db`, `/home/edobele/data/wp`)
- `make re` : fclean + build + up
- `make logs`, `make status`

## Dépannage rapide
- **WP ne se connecte pas à la DB**: vérifier `WORDPRESS_DB_*` dans `.env` et que MariaDB écoute (make logs). Un restart complet: `make re`.
- **Certificat TLS**: auto-signé généré au boot; régénéré à chaque clean si fichiers absents.
- **Permissions volumes**: s’assurer que `/home/edobele/data/db` et `/home/edobele/data/wp` sont accessibles en lecture/écriture pour Docker.

## Conformité sujet 42
- Images construites depuis `requirements/*`
- Volumes bindés sous `/home/edobele/data/`
- Réseau user-defined bridge
- Port exposé: 443 (Nginx). MariaDB/WordPress restent internes.
