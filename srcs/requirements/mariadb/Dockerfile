FROM debian:bookworm

# install mariadb & remove the cache
RUN apt-get update -y && \
    apt-get install -y mariadb-server && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# copy the mariadb configuration files
COPY ./tools/50-server.cnf /etc/mysql/mariadb.conf.d/
COPY ./tools/script.sh /

# run the script.sh to start the mariadb service
RUN chmod +x /script.sh

CMD ["/script.sh"]
