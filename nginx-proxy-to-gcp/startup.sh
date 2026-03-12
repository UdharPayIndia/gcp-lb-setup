#!/bin/bash
set -e

echo "Starting Nginx Proxy initialization..."

# 1. Update package list and install Nginx
sudo apt-get update
sudo apt-get install -y nginx

# 2. Backup default config
if [ -f /etc/nginx/sites-available/default ]; then
    sudo mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
fi

# 3. Create the new Nginx configuration
# This configuration acts as a reverse proxy passing through ALL original request properties.
cat ~/nginx.conf > /etc/nginx/sites-available/default

# 4. Test the configuration and reload Nginx
nginx -t
systemctl restart nginx
systemctl enable nginx

echo "Nginx Proxy initialized successfully."
