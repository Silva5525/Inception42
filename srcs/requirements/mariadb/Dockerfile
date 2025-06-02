FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive

# Install MariaDB and netcat (for health checks, etc.), then clean up
RUN apt-get -y update && \
    apt-get install -y mariadb-server netcat-openbsd && \
    groupmod -g 3000 mysql && \
    usermod -u 3000 -g 3000 mysql && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# copy the custom MariaDB config& entrypoint script
COPY ./tools/50-server.cnf /etc/mysql/mariadb.conf.d/
COPY ./tools/script.sh /
RUN chmod +x /script.sh

# Use the entrypoint script to control container behavior
ENTRYPOINT ["/script.sh"]