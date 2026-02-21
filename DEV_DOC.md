# Developer Documentation — Inception

## Environment setup from scratch

### 1. System prerequisites

Make sure the following are installed on the host:

```bash
docker --version          # Docker Engine 20.10+
docker compose version    # Docker Compose v2 (plugin, not standalone)
make --version
```

On Debian/Ubuntu, install them with:

```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-plugin make
sudo usermod -aG docker $USER   # add yourself to the docker group, then re-login
```

### 2. Clone the repository

```bash
git clone <repo-url> Inception
cd Inception
```

### 3. Create the host data directories

The bind mounts require these directories to exist before the containers start:

```bash
mkdir -p /home/edobele/data/db /home/edobele/data/wp
```

### 4. Configure environment variables

Create the file and fill in every value:

```bash
touch srcs/.env
$EDITOR srcs/.env
```

> `srcs/.env` is listed in `.gitignore` and must **never** be committed. It contains all service credentials.

Key variables to set:

| Variable                | Description                                   |
| ----------------------- | --------------------------------------------- |
| `MYSQL_DATABASE`        | WordPress database name                       |
| `MYSQL_USER`            | MariaDB application user                      |
| `MYSQL_PASSWORD`        | Password for the application user             |
| `MYSQL_ROOT_PASSWORD`   | MariaDB root password                         |
| `WORDPRESS_DB_NAME`     | Must match `MYSQL_DATABASE`                   |
| `WORDPRESS_DB_USER`     | Must match `MYSQL_USER`                       |
| `WORDPRESS_DB_PASSWORD` | Must match `MYSQL_PASSWORD`                   |
| `WORDPRESS_DB_HOST`     | Set to `mariadb` (Docker DNS name)            |
| `WP_TITLE`              | WordPress site title                          |
| `WP_ADMIN_USER`         | WordPress admin login                         |
| `WP_ADMIN_PASSWORD`     | WordPress admin password                      |
| `WP_ADMIN_EMAIL`        | WordPress admin email                         |
| `WP_USER`               | Secondary WordPress user (editor)             |
| `WP_USER_PASSWORD`      | Secondary user password                       |
| `WP_USER_EMAIL`         | Secondary user email                          |
| `WP_URL`                | Full public URL, e.g. `https://edobele.42.fr` |
| `SERVER_NAME`           | Nginx `server_name`, e.g. `edobele.42.fr`     |

For local testing, set both `WP_URL` and `SERVER_NAME` to `localhost`, and add an entry to `/etc/hosts` if needed:

```
127.0.0.1  localhost
```

---

## Building the project

### Using the Makefile (recommended)

From the repository root:

```bash
make build    # Build all three Docker images
make up       # Start the full stack in detached mode
make status   # List containers and their state
make logs     # Tail all container logs (Ctrl+C to stop)
```

### Using Docker Compose directly

```bash
cd srcs
docker compose build              # Build images
docker compose build --no-cache   # Force full rebuild (no layer cache)
docker compose up -d              # Start in background
docker compose ps                 # Status
docker compose logs -f            # Logs
docker compose down               # Stop and remove containers + network
```

---

## Makefile reference

| Target        | Effect                                                                |
| ------------- | --------------------------------------------------------------------- |
| `make build`  | Build all images from `srcs/requirements/`                            |
| `make up`     | Start all containers in detached mode                                 |
| `make down`   | Stop and remove containers and the `inception` network (volumes kept) |
| `make logs`   | Follow logs from all services                                         |
| `make status` | Print container status                                                |
| `make fclean` | `down` + wipe `/home/edobele/data/{db,wp}` + remove named volumes     |
| `make re`     | `fclean` → `build` → `up` (full cold restart)                         |

---

## Container and volume management

### Execute a shell inside a running container

```bash
docker exec -it nginx    /bin/bash
docker exec -it wordpress /bin/bash
docker exec -it mariadb   /bin/bash
```

### Inspect a specific container

```bash
docker inspect nginx
docker inspect wordpress
docker inspect mariadb
```

### View image layers and sizes

```bash
docker image ls
docker image history nginx
```

### Manage volumes manually

```bash
docker volume ls                     # List all volumes
docker volume inspect srcs_db_data   # Detail for the DB volume
docker volume inspect srcs_wp_data   # Detail for the WP volume
```

Volume names are prefixed with the Compose project name (`srcs` by default, derived from the directory name).

### Run a one-off MariaDB query

```bash
docker exec -it mariadb mysql -u root -p"$MYSQL_ROOT_PASSWORD" wordpress
```

Or read the password from `.env` automatically:

```bash
source srcs/.env
docker exec -it mariadb mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"
```

---

## Repository structure

```
.
├── Makefile                        # Top-level build/run shortcuts
├── README.md                       # Project overview and design discussion
├── USER_DOC.md                     # End-user / admin documentation
├── DEV_DOC.md                      # This file
└── srcs/
    ├── docker-compose.yml          # Service definitions, network, volumes
    ├── .env                        # Local credentials — NOT committed
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   └── tools/
        │       └── init_db.sh      # DB + user creation entrypoint
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── www.conf        # PHP-FPM pool configuration
        │   └── tools/
        │       └── setup.sh        # WP-CLI bootstrap script
        └── nginx/
            ├── Dockerfile
            ├── conf/
            │   └── wordpress.conf.template  # Nginx vhost template
            └── tools/
                └── setup.sh        # TLS cert generation + Nginx start
```

---

## Where data is stored and how it persists

### Bind mounts

Both persistent volumes are configured as **bind mounts** that map host directories into the containers:

| Docker volume name | Host path               | Container path   | Content                          |
| ------------------ | ----------------------- | ---------------- | -------------------------------- |
| `srcs_db_data`     | `/home/edobele/data/db` | `/var/lib/mysql` | MariaDB data files               |
| `srcs_wp_data`     | `/home/edobele/data/wp` | `/var/www/html`  | WordPress core, plugins, uploads |

Because these are bind mounts, the data survives container restarts, `make down`, and image rebuilds. It is only deleted by `make fclean` (which runs `rm -rf` on both host directories) or by manually wiping them.

### Checking data on the host

```bash
ls /home/edobele/data/db    # MariaDB table files, ibdata1, ib_logfile*, etc.
ls /home/edobele/data/wp    # wp-config.php, wp-content/, wp-includes/, etc.
```

### Resetting to a clean state

```bash
make fclean
make up
```

This removes all data, rebuilds from scratch, and re-runs the MariaDB init script and the WordPress/WP-CLI bootstrap.

---

## Networking

All containers share a single user-defined bridge network named `inception`. Docker's embedded DNS resolver lets each container reference others by their service name:

- WordPress connects to MariaDB at `mariadb:3306`
- Nginx proxies PHP requests to `wordpress:9000`

Only Nginx publishes a port to the host (`443:443`). MariaDB and WordPress are not reachable directly from outside Docker.

```
Host (port 443)
      │
  [ nginx ]  ──FastCGI──▶  [ wordpress ]  ──TCP 3306──▶  [ mariadb ]
      │                          │                              │
 inception bridge network        │                              │
                           /var/www/html                /var/lib/mysql
                          (srcs_wp_data)               (srcs_db_data)
                          → /home/edobele/data/wp     → /home/edobele/data/db
```
