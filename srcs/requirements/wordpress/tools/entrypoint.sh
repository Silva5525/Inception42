#!/bin/bash
set -e

# Load secrets
DB_PWD=$(cat /run/secrets/db_pw)
DB_ROOT_PWD=$(cat /run/secrets/db_root_pw)
WP_ADMIN_PWD=$(cat /run/secrets/wp_admin_pw)

# Load environment variables — fail if missing
: "${DOMAIN_NAME:?Missing DOMAIN_NAME}"
: "${WP_TITLE:?Missing WP_TITLE}"
: "${WP_ADMIN_USR:?Missing WP_ADMIN_USR}"
: "${WP_ADMIN_EMAIL:?Missing WP_ADMIN_EMAIL}"
: "${WP_USR:?Missing WP_USR}"
: "${DB_NAME:?Missing DB_NAME}"
: "${DB_USER:?Missing DB_USER}"

echo "Waiting for MariaDB to be ready..."
until mysqladmin ping -h mariadb -u"${DB_USER}" -p"${DB_PWD}" --silent; do
    echo "MariaDB not ready... retrying in 2s"
    sleep 2
done
echo "MariaDB is up!"

# Download WP-CLI if not installed
if ! command -v wp &> /dev/null; then
    curl -s -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
fi

# Prepare directories
mkdir -p /var/www/html /run/php
cd /var/www/html

# First-time install check
if [ ! -f wp-config.php ]; then
  echo "First-time setup: installing WordPress..."

    wp core download --allow-root

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
define('WP_ALLOW_REPAIR', true);
define('WP_DEBUG', true);
PHP

    wp config shuffle-salts --allow-root

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

    wp theme install astra --activate --allow-root
    wp plugin update --all --allow-root

    echo "WordPress installation complete."
else
    echo "WordPress already installed — skipping setup."
fi

# Fix permissions for NGINX to read files
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Configure PHP-FPM to listen on TCP port 9000
PHP_FPM_CONF="/etc/php/8.2/fpm/pool.d/www.conf"
sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 9000|' "$PHP_FPM_CONF"

echo "Starting PHP-FPM in foreground..."
exec php-fpm8.2 -F

