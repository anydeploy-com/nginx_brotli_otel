#!/usr/bin/env bash

if [ ! -e "/lib/systemd/system/nginx.service" ]; then
  # Control will enter here if the NGINX service doesn't exist.
  file="/lib/systemd/system/nginx.service"

  /bin/cat >$file <<'EOF'
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
fi