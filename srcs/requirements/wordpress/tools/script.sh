#!/bin/bash

DB_PASSWORD=$(cat /run/secrets/db_pw)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_pw)
DB_PWD=$(cat /run/secrets/db_pw)
db_pwD=$(cat /run/secrets/db_pw)
WP_ADMIN_PWD=$(cat /run/secrets/wp_admin_pw)

set -e

# Download WP-CLI if not present
if ! command -v wp &> /dev/null; then
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
fi

# Ensure target dir exists
mkdir -p /var/www/html
cd /var/www/html

# Clean and download WordPress
rm -rf ./*
wp core download --allow-root

# Place pre-copied config
cp -f /var/www/html/wp-config.php .

# Replace DB credentials
sed -i "s/db1/${DB_NAME}/" wp-config.php
sed -i "s/user/${DB_USER}/" wp-config.php
sed -i "s/pwd/${DB_PWD}/" wp-config.php

# Replace salts
sed -i "/### SALT_PLACEHOLDER ###/r /dev/stdin" wp-config.php <<< "$SALTS"
sed -i "/### SALT_PLACEHOLDER ###/d" wp-config.php

# WordPress install
wp core install \
  --url="${DOMAIN_NAME}" \
  --title="${WP_TITLE}" \
  --admin_user="${WP_ADMIN_USR}" \
  --admin_password="${WP_ADMIN_PWD}" \
  --admin_email="${WP_ADMIN_EMAIL}" \
  --skip-email \
  --allow-root

# Create extra user
wp user create "${WP_USR}" "${WP_ADMIN_EMAIL}" \
  --role=author \
  --user_pass="${db_pwD}" \
  --allow-root

# Theme & plugins
wp theme install astra --activate --allow-root
wp plugin install redis-cache --activate --allow-root
wp plugin update --all --allow-root
wp redis enable --allow-root

# Fix PHP-FPM socket to use TCP
PHP_FPM_CONF="/etc/php/8.2/fpm/pool.d/www.conf"
sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 9000|' $PHP_FPM_CONF

# Ensure PHP runtime dir exists
mkdir -p /run/php

# Start PHP-FPM in foreground
php-fpm8.2 -F
