#!/bin/bash
set -euo pipefail

# Validate required environment variables
for var in MYSQL_DATABASE MYSQL_USER MYSQL_PASSWORD MYSQL_ROOT_PASSWORD; do
	if [ -z "${!var:-}" ]; then
		echo "[mariadb] Error: $var is not set" >&2
		exit 1
	fi
done

# Prepare runtime and data directories
mkdir -p /run/mysqld /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Initialize system tables on first run
if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo "[mariadb] Initializing system tables..."
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null 2>&1
fi

# Check if setup has already been done (root password was set)
if [ ! -f "/var/lib/mysql/.setup_done" ]; then
	echo "[mariadb] Starting setup server..."
	
	# Start temp server with no grants
	mysqld --skip-networking --skip-grant-tables --socket=/run/mysqld/mysqld.sock --user=mysql &
	temp_pid=$!
	
	# Wait for startup
	for i in {1..30}; do
		if mysqladmin --protocol=socket ping --silent 2>/dev/null; then
			break
		fi
		sleep 1
	done
	
	# Apply setup SQL
	echo "[mariadb] Configuring database..."
	mysql --protocol=socket -u root <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
	
	# Mark setup as done
	touch /var/lib/mysql/.setup_done
	
	# Kill temp server
	kill $temp_pid || true
	sleep 2
fi

# Run main MariaDB in foreground
echo "[mariadb] Starting MariaDB..."
exec mysqld --user=mysql --bind-address=0.0.0.0
