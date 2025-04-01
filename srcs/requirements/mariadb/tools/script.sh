#!/bin/bash
set -e

# Create the required runtime directory
mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld

mkdir -p /var/log/mysql
chown -R mysql:mysql /var/log/mysql


# Set the MySQL root password from the secret
DB_PASSWORD=$(cat /run/secrets/db_pw)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_pw)

# Start MySQL in the background (no networking) just to initialize
mysqld --skip-networking --socket=/var/run/mysqld/mysqld.sock &

# Wait for MySQL to be ready
until mysqladmin ping --socket=/var/run/mysqld/mysqld.sock --silent; do
    sleep 1
done

# Execute SQL commands
mysql -u root -S /var/run/mysqld/mysqld.sock <<-EOSQL
    CREATE DATABASE IF NOT EXISTS ${DB_NAME};
    CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
    FLUSH PRIVILEGES;
EOSQL

# Bring down MySQL
mysqladmin shutdown -u root -p"${DB_ROOT_PASSWORD}" -S /var/run/mysqld/mysqld.sock || true

# Now start MySQL as PID 1 (for the container)
exec mysqld
