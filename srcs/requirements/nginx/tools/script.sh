#!/bin/bash
# This script configures and launches an NGINX server with 
#   a self-signed SSL certificate.
# If no certificate exists, it generates one using OpenSSL
# It also creates a basic NGINX TLS config for serving PHP files via FastCGI.

# Ensure directories exist, then generate a new self-signed certificate if missing
mkdir -p $(dirname "$SSL_CERT_PATH") $(dirname "$SSL_KEY_PATH")

if [ ! -f "$SSL_CERT_PATH" ] || [ ! -f "$SSL_KEY_PATH" ]; then
  openssl req -x509 -nodes -days 365 \
      -newkey rsa:2048 \
      -keyout "$SSL_KEY_PATH" \
      -out "$SSL_CERT_PATH" \
      -subj "/C=MO/L=KH/O=1337/OU=student/CN=${DOMAIN_NAME}"
fi

# Replace NGINX default site configuration to:
# - Enable HTTPS with the generated self-signed certificate
# - Serve content from /var/www/html
# - Forward PHP requests to a FastCGI backend at 'wordpress:9000'
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

# Validate certs
if [ ! -s "$SSL_CERT_PATH" ] || [ ! -s "$SSL_KEY_PATH" ]; then
  echo "SSL cert/key generation failed. Exiting."
  exit 1
fi

# Validate NGINX config
nginx -t
if [ $? -ne 0 ]; then
  echo "NGINX config invalid. Exiting."
  exit 1
fi

# Start NGINX in the foreground to keep the container/process alive
exec nginx -g "daemon off;"
