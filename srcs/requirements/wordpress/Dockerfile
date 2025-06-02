FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages: PHP, PHP-FPM, PHP-MySQL, curl, MariaDB client, etc.
RUN apt-get -y update && \
    apt-get install -y php php-fpm php-mysql curl unzip less mariadb-client netcat-openbsd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create necessary directories for PHP and WordPress
RUN mkdir -p /var/www/html /run/php

# Copy the custom entrypoint script into the container
COPY ./tools/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

# Set the working directory where WordPress files will live
WORKDIR /var/www/html

# Use custom entrypoint to handle WordPress installation and setup
ENTRYPOINT ["/entrypoint.sh"]
