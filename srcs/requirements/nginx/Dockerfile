FROM debian:bookworm

RUN apt -y update && \
    apt install -y nginx openssl && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

COPY ./tools/script.sh /script.sh

RUN chmod +x /script.sh

CMD ["/script.sh"]