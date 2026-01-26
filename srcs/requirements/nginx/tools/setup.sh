#!/bin/bash
set -euo pipefail

# Environment
SERVER_NAME=${SERVER_NAME:-localhost}
SSL_DIR=/etc/nginx/ssl
CONF_TEMPLATE=/etc/nginx/conf.d/wordpress.conf.template
CONF_TARGET=/etc/nginx/sites-available/wordpress.conf

mkdir -p "$SSL_DIR" /etc/nginx/sites-available /etc/nginx/sites-enabled

# Generate self-signed cert if missing
if [ ! -f "$SSL_DIR/server.crt" ] || [ ! -f "$SSL_DIR/server.key" ]; then
  echo "[nginx] Generating self-signed certificate for $SERVER_NAME..."
  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout "$SSL_DIR/server.key" \
    -out "$SSL_DIR/server.crt" \
    -days 365 \
    -subj "/CN=$SERVER_NAME"
fi

# Render config from template
sed "s|__SERVER_NAME__|$SERVER_NAME|g" "$CONF_TEMPLATE" > "$CONF_TARGET"

# Enable site and disable default
rm -f /etc/nginx/sites-enabled/default || true
ln -sf "$CONF_TARGET" /etc/nginx/sites-enabled/wordpress.conf

# Test configuration
nginx -t

echo "[nginx] Starting nginx..."
exec nginx -g 'daemon off;'