FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

# install nginx & remove the cache
RUN apt-get -y update && \
    apt-get install -y php php-fpm php-mysql curl unzip less mariadb-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create necessary dirs
RUN mkdir -p /var/www/html /run/php

# copy the configuration files
# COPY ./tools/script.sh /script.sh
# COPY ./tools/wp-config.php /var/www/html/wp-config.php
COPY ./tools/entrypoint.sh /entrypoint.sh

# run the script.sh to start the service
# RUN chmod +x /script.sh
RUN chmod +x /entrypoint.sh

# Set working directory
WORKDIR /var/www/html

# CMD ["/script.sh"]
ENTRYPOINT ["/entrypoint.sh"]
