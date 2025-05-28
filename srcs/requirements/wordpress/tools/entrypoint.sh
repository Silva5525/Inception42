#!/bin/bash
set -e

# WordPress Initialization Script
# Sets up WordPress with MariaDB and PHP-FPM using Docker secrets.
# Intended for use in containerized environments with mounted secrets.

# Read sensitive credentials (database and WP admin passwords) from Docker's secrets mechanism
DB_PWD=$(cat /run/secrets/db_pw)
DB_ROOT_PWD=$(cat /run/secrets/db_root_pw)
WP_ADMIN_PWD=$(cat /run/secrets/wp_admin_pw)

# Abort script execution if any essential WordPress or database environment variable is missing
: "${DOMAIN_NAME:?Missing DOMAIN_NAME}"
: "${WP_TITLE:?Missing WP_TITLE}"
: "${WP_ADMIN_USR:?Missing WP_ADMIN_USR}"
: "${WP_ADMIN_EMAIL:?Missing WP_ADMIN_EMAIL}"
: "${WP_USR:?Missing WP_USR}"
: "${DB_NAME:?Missing DB_NAME}"
: "${DB_USER:?Missing DB_USER}"

# Wait for MariaDB to respond before proceeding with WordPress setup
echo "Waiting for MariaDB to be ready..."
until mysqladmin ping -h mariadb -u"${DB_USER}" -p"${DB_PWD}" --silent; do
    echo "MariaDB not ready... retrying in 2s"
    sleep 2
done
echo "MariaDB is up!"

# Check if WP-CLI is available; download and install it if missing
if ! command -v wp &> /dev/null; then
    echo "Downloading WP-CLI..."
    curl -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
fi

# Set up web root
mkdir -p /var/www/html /run/php
cd /var/www/html

# If wp-config.php does not exist, assume this is a fresh setup and install WordPress
if [ ! -f wp-config.php ]; then
    echo "First-time setup: installing WordPress..."

    # Download WordPress core files
    wp core download --allow-root

    # Create wp-config.php with database credentials and extra PHP definitions
    wp config create \
        --dbname="${DB_NAME}" \
        --dbuser="${DB_USER}" \
        --dbpass="${DB_PWD}" \
        --dbhost="mariadb" \
        --dbcharset="utf8" \
        --dbcollate="" \
        --allow-root \
        --extra-php <<PHP
define('WP_CACHE', true);
define('WP_ALLOW_REPAIR', false);
define('WP_DEBUG', false);
PHP

    # Generate and insert random salts for security
    wp config shuffle-salts --allow-root

    # Run the actual WordPress installation with admin credentials
    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USR}" \
        --admin_password="${WP_ADMIN_PWD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    wp user create "${WP_USR}" "${WP_ADMIN_EMAIL}" \
        --role=author \
        --user_pass="${DB_PWD}" \
        --allow-root

    # Install and activate a theme and key plugins
    wp theme install astra --activate --allow-root
    wp plugin install redis-cache --activate --allow-root
    
    # Update all available plugins to latest versions
    wp plugin update --all --allow-root
    
    # Enable Redis object caching
    wp redis enable --allow-root

    echo "WordPress setup complete."
else
    echo "WordPress already installed — skipping setup."
fi

# Set ownership and permissions for web server to function correctly
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Change PHP-FPM to use TCP (port 9000) instead of Unix socket for container compatibility
PHP_FPM_CONF="/etc/php/8.2/fpm/pool.d/www.conf"
sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 9000|' "$PHP_FPM_CONF"

# Start PHP-FPM in the foreground to keep container running
echo "Starting PHP-FPM..."
exec php-fpm8.2 -F
