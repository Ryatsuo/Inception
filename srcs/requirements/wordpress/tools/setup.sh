#!/bin/bash
set -euo pipefail

# Required environment variables
required_vars=(
  WORDPRESS_DB_NAME
  WORDPRESS_DB_USER
  WORDPRESS_DB_PASSWORD
  WORDPRESS_DB_HOST
  WP_TITLE
  WP_ADMIN_USER
  WP_ADMIN_PASSWORD
  WP_ADMIN_EMAIL
)
for var in "${required_vars[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "[wordpress] Error: $var is not set" >&2
    exit 1
  fi
done

WP_PATH=/var/www/html
DB_HOST=${WORDPRESS_DB_HOST:-mariadb}

mkdir -p "$WP_PATH"
chown -R www-data:www-data "$WP_PATH"

# Wait for MariaDB to be ready
echo "[wordpress] Waiting for MariaDB at $DB_HOST:3306..."
for i in {1..60}; do
  if nc -z "$DB_HOST" 3306 2>/dev/null; then
    echo "[wordpress] MariaDB is ready!"
    break
  fi
  echo "  Waiting... ($i/60)"
  sleep 1
done

# If WordPress is not configured yet, download and install
if [ ! -f "$WP_PATH/wp-config.php" ]; then
  echo "[wordpress] Downloading WordPress core..."
  wp core download --path="$WP_PATH" --allow-root --force

  echo "[wordpress] Creating wp-config.php..."
  wp config create \
    --path="$WP_PATH" \
    --allow-root \
    --dbname="$WORDPRESS_DB_NAME" \
    --dbuser="$WORDPRESS_DB_USER" \
    --dbpass="$WORDPRESS_DB_PASSWORD" \
    --dbhost="${DB_HOST}:3306" \
    --skip-check

  echo "[wordpress] Installing WordPress..."
  wp core install \
    --path="$WP_PATH" \
    --allow-root \
    --url="${WP_URL:-https://localhost}" \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --skip-email

  # Optional: create a regular user if provided
  if [ -n "${WP_USER:-}" ] && [ -n "${WP_USER_PASSWORD:-}" ] && [ -n "${WP_USER_EMAIL:-}" ]; then
    echo "[wordpress] Creating additional user $WP_USER..."
    wp user create "$WP_USER" "$WP_USER_EMAIL" --role=author --user_pass="$WP_USER_PASSWORD" --path="$WP_PATH" --allow-root || true
  fi
fi

chown -R www-data:www-data "$WP_PATH"

echo "[wordpress] Starting php-fpm..."
exec /usr/sbin/php-fpm8.2 -F