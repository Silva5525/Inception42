#!/bin/bash

# Set default values if not provided
SSL_CERT_PATH=${SSL_CERT_PATH:-/etc/ssl/certs/nginx-selfsigned.crt}
SSL_KEY_PATH=${SSL_KEY_PATH:-/etc/ssl/private/nginx-selfsigned.key}
DOMAIN_NAME=${DOMAIN_NAME:-localhost}

# Generate self-signed certificate if not exists
mkdir -p $(dirname "$SSL_CERT_PATH") $(dirname "$SSL_KEY_PATH")

if [ ! -f "$SSL_CERT_PATH" ] || [ ! -f "$SSL_KEY_PATH" ]; then
  openssl req -x509 -nodes -days 365 \
      -newkey rsa:2048 \
      -keyout "$SSL_KEY_PATH" \
      -out "$SSL_CERT_PATH" \
      -subj "/C=MO/L=KH/O=1337/OU=student/CN=${DOMAIN_NAME}"
fi

# Create NGINX TLS config
cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name ${DOMAIN_NAME};

    ssl_certificate $SSL_CERT_PATH;
    ssl_certificate_key $SSL_KEY_PATH;
    ssl_protocols TLSv1.2 TLSv1.3;

    root /var/www/html;
    index index.php index.html;

    location ~ [^/]\.php(/|$) {
        try_files \$uri =404;
        fastcgi_pass wordpress:9000;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF

# Start NGINX in foreground
exec nginx -g "daemon off;"
