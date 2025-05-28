FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

# install mariadb & remove the cache
RUN apt-get -y update && \
    apt-get install -y mariadb-server netcat-openbsd && \
    groupmod -g 3000 mysql && \
    usermod -u 3000 -g 3000 mysql && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# copy the mariadb configuration files
COPY ./tools/50-server.cnf /etc/mysql/mariadb.conf.d/
COPY ./tools/script.sh /

# run the script.sh to start the mariadb service
RUN chmod +x /script.sh

CMD ["/script.sh"]
