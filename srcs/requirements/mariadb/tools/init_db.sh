#!/bin/bash
# -e exit si une commande échoue
# -u exit si une variable d'environnement utilisée n'est pas définie
# -o pipefail pour que les erreurs dans les pipelines soient prises en compte
set -euo pipefail

# Vérifie que toutes les variables d'environnement nécessaires sont définies
for var in MYSQL_DATABASE MYSQL_USER MYSQL_PASSWORD MYSQL_ROOT_PASSWORD; do
	if [ -z "${!var:-}" ]; then
		echo "[mariadb] Error: $var is not set" >&2
		exit 1
	fi
done

# Crée les dossiers nécessaires au fonctionnement de MariaDB et affecte les droits à l'utilisateur mysql
mkdir -p /run/mysqld /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Initialise les tables système de MariaDB uniquement au premier démarrage
if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo "[mariadb] Initializing system tables..."
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null 2>&1
fi

# Configure la base de données une seule fois (le fichier .setup_done sert de marqueur)
if [ ! -f "/var/lib/mysql/.setup_done" ]; then
	echo "[mariadb] Starting setup server..."
	
	# Démarre un serveur temporaire sans réseau et sans authentification pour pouvoir exécuter le SQL de setup
	mysqld --skip-networking --skip-grant-tables --socket=/run/mysqld/mysqld.sock --user=mysql &
	temp_pid=$!
	
	# Attend que le serveur temporaire soit prêt
	for i in {1..30}; do
		if mysqladmin --protocol=socket ping --silent 2>/dev/null; then
			break
		fi
		sleep 1
	done
	
	# Applique la configuration SQL : mot de passe root, création de la BDD et de l'utilisateur WordPress
	echo "[mariadb] Configuring database..."
	mysql --protocol=socket -u root <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
	
	# Marque le setup comme terminé pour ne pas le rejouer au prochain démarrage
	touch /var/lib/mysql/.setup_done
	
	# Arrête le serveur temporaire
	kill $temp_pid || true
	sleep 2
fi

# Lance le vrai serveur MariaDB en premier plan (obligatoire pour que le container reste actif)
echo "[mariadb] Starting MariaDB..."
exec mysqld --user=mysql --bind-address=0.0.0.0
