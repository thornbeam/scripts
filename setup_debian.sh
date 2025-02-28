#!/bin/bash

# Check if it's run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Log stdout and stderr
exec > >(tee setup_debian.log) 2>&1

# Set a timeout so the script won't hang up
timeout=10

# Update and upgrade system
apt -y update && apt -y full-upgrade

# Install packages
echo "Installing sudo ..."
apt install -y sudo

echo "Installing neovim ..."
apt install -y neovim

echo "Installing tmux ..."
apt install -y tmux

echo "Installing neofetch ..."
apt install -y neofetch

echo "Installing git ..."
apt install -y git

echo "Installing ufw ..."
apt install -y ufw

echo "Configuring ufw ..."
ufw default deny incoming \
&& ufw default allow outgoing \
&& ufw allow ssh \
&& ufw allow http \
&& ufw allow https \
&& systemctl enable ufw \
&& systemctl start ufw \
&& ufw enable

echo "Installing openssh-server ..."
apt install -y openssh-server

echo "Registering SSH key before deactivating SSH Password Authentication ..."
echo "Please enter your public key for SSH Public Key Authentication:"
read user_input

dir_path="/root/.ssh"
file_path="$dir_path/authorized_keys"

# Add public key to authorized_keys in root
mkdir -p $dir_path
cat > $file_path << EOF
$user_input
EOF

echo "Configuring sshd ..."
file_path="/etc/ssh/sshd_config.d/deactivate_pa.conf"
cat > $file_path << EOF
PasswordAuthentication no
EOF

systemctl restart sshd.service

echo "Installing nginx ..."
apt install -y nginx

# Implementing SSL Perfect Forward Secrecy
dir_path="/etc/nginx"
cd $dir_path
openssl dhparam -out dh4096.pem 4096
file_path="$dir_path/perfect-forward-secrecy.conf"
cat > $file_path << EOF
ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA RC4 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS !MEDIUM";
ssl_dhparam dh4096.pem;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
# This will prevent certain click-jacking attacks, but will prevent
# other sites from framing your site, so delete or modify as necessary!
add_header X-Frame-Options SAMEORIGIN;
EOF

file_path="$dir_path/nginx.conf"
cat > $file_path << EOF
user www-data;
worker_processes auto;
pid /run/nginx.pid;
error_log /var/log/nginx/error.log;
include /etc/nginx/modules-enabled/*.conf;

events {
	worker_connections 768;
	# multi_accept on;
}

http {

	##
	# Basic Settings
	##

	sendfile on;
	tcp_nopush on;
	types_hash_max_size 2048;
	# server_tokens off;

	# server_names_hash_bucket_size 64;
	# server_name_in_redirect off;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	##
	# Logging Settings
	##

	access_log /var/log/nginx/access.log;

	##
	# Gzip Settings
	##

	gzip on;

	# gzip_vary on;
	# gzip_proxied any;
	# gzip_comp_level 6;
	# gzip_buffers 16 8k;
	# gzip_http_version 1.1;
	# gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

	##
	# Virtual Host Configs
	##

	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;

  # See: https://community.qualys.com/blogs/securitylabs/2013/08/05/configuring-apache-nginx-and-openssl-for-forward-secrecy
  # This MUST come AFTER the lines that includes .../sites-enabled/*, otherwise SSLv3 support may be re-enabled accidentally.
  include perfect-forward-secrecy.conf;
  # See: http://forum.nginx.org/read.php?2,152294,152401#msg-152401
  ssl_session_cache shared:SSL:10m;
}


#mail {
#	# See sample authentication script at:
#	# http://wiki.nginx.org/ImapAuthenticateWithApachePhpScript
#
#	# auth_http localhost/auth.php;
#	# pop3_capabilities "TOP" "USER";
#	# imap_capabilities "IMAP4rev1" "UIDPLUS";
#
#	server {
#		listen     localhost:110;
#		protocol   pop3;
#		proxy      on;
#	}
#
#	server {
#		listen     localhost:143;
#		protocol   imap;
#		proxy      on;
#	}
#}
EOF

file_path="$dir_path/conf.d/root.conf"
cat > $file_path << EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 default_server ssl;
    listen [::]:443 default_server ssl;
    ssl_reject_handshake on;

    server_name _;

    return 444;
}
EOF

file_path="$dir_path/sites-enabled/*"
rm -f $file_path

systemctl restart nginx
