#!/bin/bash
set -euo pipefail

# Vérifie que toutes les variables d'environnement nécessaires sont définies
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

# Crée le dossier WordPress et affecte les droits à l'utilisateur www-data
mkdir -p "$WP_PATH"
chown -R www-data:www-data "$WP_PATH"

# Attend que MariaDB soit prête avant de continuer (sinon l'installation échouerait)
echo "[wordpress] Waiting for MariaDB at $DB_HOST:3306..."
for i in {1..60}; do
  if nc -z "$DB_HOST" 3306 2>/dev/null; then
    echo "[wordpress] MariaDB is ready!"
    break
  fi
  echo "  Waiting... ($i/60)"
  sleep 1
done

# Télécharge et installe WordPress uniquement au premier démarrage (si wp-config.php n'existe pas encore)
if [ ! -f "$WP_PATH/wp-config.php" ]; then
  echo "[wordpress] Downloading WordPress core..."
  wp core download --path="$WP_PATH" --allow-root --force

  # Génère le fichier wp-config.php avec les paramètres de connexion à la BDD
  echo "[wordpress] Creating wp-config.php..."
  wp config create \
    --path="$WP_PATH" \
    --allow-root \
    --dbname="$WORDPRESS_DB_NAME" \
    --dbuser="$WORDPRESS_DB_USER" \
    --dbpass="$WORDPRESS_DB_PASSWORD" \
    --dbhost="${DB_HOST}:3306" \
    --skip-check

  # Installe WordPress avec le titre, l'admin et l'URL définis dans le .env
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

  # Crée un second utilisateur (auteur) si les variables WP_USER sont définies dans le .env
  if [ -n "${WP_USER:-}" ] && [ -n "${WP_USER_PASSWORD:-}" ] && [ -n "${WP_USER_EMAIL:-}" ]; then
    echo "[wordpress] Creating additional user $WP_USER..."
    wp user create "$WP_USER" "$WP_USER_EMAIL" --role=author --user_pass="$WP_USER_PASSWORD" --path="$WP_PATH" --allow-root || true
  fi
fi

# Remet les droits sur les fichiers WordPress (au cas où ils auraient changé)
chown -R www-data:www-data "$WP_PATH"

# Lance PHP-FPM en premier plan pour servir WordPress à Nginx (obligatoire pour que le container reste actif)
echo "[wordpress] Starting php-fpm..."
exec /usr/sbin/php-fpm8.2 -F