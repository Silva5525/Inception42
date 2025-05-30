#!/bin/bash

# Entrypoint script for MariaDB container.
# Handles directory setup, secrets loading, and one-time DB initialization.

set -e

# Ensure MySQL runtime and log directories exist and are owned by the mysql user.
mkdir -p /var/run/mysqld /var/log/mysql
chown -R mysql:mysql /var/run/mysqld /var/log/mysql

echo "Listing /var/lib/mysql:"
ls -la /var/lib/mysql

# Uncomment for debugging purposes
# echo "Current user: $(id)"

# Ensure /var/lib/mysql is writable, or the database won't initialize properly.
if [ ! -w /var/lib/mysql ]; then
  echo "Cannot write to /var/lib/mysql — check volume permissions!"
  ls -la /var/lib/mysql
  exit 2
fi

# Read database passwords from Docker secrets (fallback to empty string if missing)
DB_PASSWORD=$(cat /run/secrets/db_pw || echo "")
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_pw || echo "")

# # Sanity check
# echo "[DEBUG] DB_USER=$DB_USER"
# echo "[DEBUG] DB_NAME=$DB_NAME"
# echo "[DEBUG] DB_PASSWORD=$DB_PASSWORD"
# echo "[DEBUG] DB_ROOT_PASSWORD=$DB_ROOT_PASSWORD"

if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ]; then
  echo "Required environment variables DB_NAME or DB_USER are missing!"
  exit 1
fi

INIT_MARKER="/var/lib/mysql/.mariadb_initialized"

if [ ! -f "$INIT_MARKER" ]; then
  echo "Database not initialized. Proceeding with setup..."

  chown -R mysql:mysql /var/lib/mysql

  # Initialize the MySQL data directory (only done on first run)
  mysql_install_db --user=mysql --datadir=/var/lib/mysql

  if [ $? -ne 0 ]; then
      echo "mysql_install_db initialization failed"
      exit 1
  fi

  # Compose SQL statements to create DB, user, and set root password
  echo "Starting temporary mysqld instance for initialization..."
  mysqld --skip-networking --socket=/var/run/mysqld/mysqld.sock &

  until mysqladmin ping --socket=/var/run/mysqld/mysqld.sock --silent; do
    echo "Waiting for MySQL to be ready..."
    sleep 1
  done

  echo "Running SQL initialization..."

SQL=$(cat <<EOSQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOSQL
)

  # Thif flags only for debugging!
  # echo "Executing SQL:"
  # echo "$SQL"

  mysql -u root -S /var/run/mysqld/mysqld.sock -e "$SQL"

  mysqladmin shutdown -u root -p"${DB_ROOT_PASSWORD}" -S /var/run/mysqld/mysqld.sock || \
    echo "Could not shutdown temporary mysqld"

  touch "$INIT_MARKER"
else
  echo "MariaDB already initialized. Skipping setup."
fi

# Launch MariaDB in foreground to keep the container running
echo "Starting MariaDB in foreground..."
exec mysqld
