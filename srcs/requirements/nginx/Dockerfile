FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

# install nginx & remove the cache
RUN apt-get -y update && \
    apt-get install -y apt-utils nginx openssl curl netcat-openbsd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# copy the nginx configuration files
COPY ./tools/script.sh /script.sh

# run the script.sh to start the nginx service
RUN chmod +x /script.sh

CMD ["/script.sh"]
