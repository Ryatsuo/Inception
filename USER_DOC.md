# User Documentation — Inception

## What does this stack provide?

The Inception stack runs three services that together deliver a self-hosted WordPress website: 

| Service       | What it does                                                                        | Reachable from outside? |
| ------------- | ----------------------------------------------------------------------------------- | ----------------------- |
| **Nginx**     | HTTPS reverse proxy. Terminates TLS on port 443 and forwards requests to WordPress. | Yes — port 443          |
| **WordPress** | PHP-FPM application server that powers the website.                                 | No — internal only      |
| **MariaDB**   | Relational database that stores all WordPress content.                              | No — internal only      |

All data persisted by the stack (database files and WordPress uploads/themes/plugins) is stored on the host machine under `/home/edobele/data/`.

---

## Starting the project

From the root of the repository:

```bash
make up
```

This builds the images (if not already built) and starts all three containers in the background.

To check that everything came up cleanly:

```bash
make status
```

You should see three containers with status `Up`.

---

## Stopping the project

```bash
make down
```

This stops and removes the containers and the internal Docker network. Your data under `/home/edobele/data/` is **not** deleted.

---

## Accessing the website

Open a browser and go to:

```
https://<SERVER_NAME>/
```

> The certificate is self-signed. Your browser will show a security warning. Click **Advanced → Accept the risk and continue** (Firefox) or **Proceed to … (unsafe)** (Chrome) to access the site.

### First visit

On the very first start, WordPress is configured automatically via WP-CLI. No manual installation wizard is shown. The site should be immediately accessible.

---

## Accessing the administration panel

Go to:

```
https://<SERVER_NAME>/wp-admin
```

Log in with the admin credentials defined in `srcs/.env`:

| Field    | Variable in `.env`  |
| -------- | ------------------- |
| Username | `WP_ADMIN_USER`     |
| Password | `WP_ADMIN_PASSWORD` |

From the admin panel you can manage posts, pages, plugins, themes, and user accounts.

---

## Locating and managing credentials

All credentials are stored in `srcs/.env`, which is **not committed to the repository**. To find it:

```bash
cat srcs/.env
```

The file contains:

- **MariaDB root password** — `MYSQL_ROOT_PASSWORD`
- **MariaDB application user/password** — `MYSQL_USER` / `MYSQL_PASSWORD`
- **WordPress admin account** — `WP_ADMIN_USER` / `WP_ADMIN_PASSWORD` / `WP_ADMIN_EMAIL`
- **WordPress editor account** — `WP_USER` / `WP_USER_PASSWORD` / `WP_USER_EMAIL`

> Never share this file or commit it to version control.

To change a credential after the stack has already been set up, update `srcs/.env` then run:

```bash
make fclean
make up
```

This wipes the existing data volumes and recreates everything from scratch with the new values.

---

## Checking that services are running correctly

### Quick status

```bash
make status
```

All three containers (`nginx`, `wordpress`, `mariadb`) should appear with status `Up`.

### Live logs

```bash
make logs
```

Press `Ctrl+C` to stop following.

### Logs for a single service

```bash
docker compose -f srcs/docker-compose.yml logs -f nginx
docker compose -f srcs/docker-compose.yml logs -f wordpress
docker compose -f srcs/docker-compose.yml logs -f mariadb
```

### Connectivity test (command line)

```bash
curl -kI https://localhost/
```

You should receive an HTTP response (e.g. `200 OK` or a redirect to `/wp-admin/install.php` on a fresh install).

### Common issues

| Symptom                                                   | Likely cause                           | Fix                                                                |
| --------------------------------------------------------- | -------------------------------------- | ------------------------------------------------------------------ |
| `wordpress` exits immediately                             | DB not ready yet                       | `make down && make up` — WP retries, but MariaDB may need a moment |
| Browser shows "Connection refused"                        | Nginx not started                      | `make status` then `make logs`                                     |
| WordPress says "Error establishing a database connection" | Wrong DB credentials or MariaDB not up | Check `srcs/.env`, then `make re`                                  |
| TLS certificate warning                                   | Expected — certificate is self-signed  | Accept the browser exception                                       |
