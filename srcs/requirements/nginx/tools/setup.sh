#!/bin/bash
set -euo pipefail

# Récupère le nom de domaine depuis la variable d'environnement (localhost par défaut)
SERVER_NAME=${SERVER_NAME:-localhost}
SSL_DIR=/etc/nginx/ssl
CONF_TEMPLATE=/etc/nginx/conf.d/wordpress.conf.template
CONF_TARGET=/etc/nginx/sites-available/wordpress.conf

# Crée les dossiers nécessaires s'ils n'existent pas
mkdir -p "$SSL_DIR" /etc/nginx/sites-available /etc/nginx/sites-enabled

# Génère un certificat SSL auto-signé pour HTTPS uniquement s'il n'existe pas déjà
if [ ! -f "$SSL_DIR/server.crt" ] || [ ! -f "$SSL_DIR/server.key" ]; then
  echo "[nginx] Generating self-signed certificate for $SERVER_NAME..."
  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout "$SSL_DIR/server.key" \
    -out "$SSL_DIR/server.crt" \
    -days 365 \
    -subj "/CN=$SERVER_NAME"
fi

# Génère la config Nginx depuis le template en remplaçant __SERVER_NAME__ par le vrai nom de domaine
sed "s|__SERVER_NAME__|$SERVER_NAME|g" "$CONF_TEMPLATE" > "$CONF_TARGET"

# Active le site WordPress et désactive le site par défaut de Nginx
rm -f /etc/nginx/sites-enabled/default || true
ln -sf "$CONF_TARGET" /etc/nginx/sites-enabled/wordpress.conf

# Vérifie que la configuration Nginx est valide avant de démarrer
nginx -t

# Lance Nginx en premier plan (daemon off obligatoire pour que le container reste actif)
echo "[nginx] Starting nginx..."
exec nginx -g 'daemon off;'

# req -x509 : génère un certificat auto-signé
# -nodes : ne pas chiffrer la clé privée
# -newkey rsa:2048 : génère une nouvelle clé RSA de 2048 bits
# -keyout : chemin de la clé privée
# -out : chemin du certificat
# -days 365 : validité du certificat en jours
# -subj : On donne le nom de domaine pour éviter de devoir répondre aux questions interactives d'openssl (CN=Common Name)