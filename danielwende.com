# HTTP → HTTPS redirection
server {
    listen 80;
    server_name danielwende.com www.danielwende.com;
    return 301 https://$host$request_uri;
}

# HTTPS (HTTP/2, hardened)
server {
    listen 443 ssl;
    http2 on;
    server_name danielwende.com www.danielwende.com *.danielwende.com;

    # TLS certs
    ssl_certificate     /etc/ssl/certs/danielwende.com.crt;
    ssl_certificate_key /etc/ssl/private/danielwende.com.key;

    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         'TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;
    ssl_session_timeout 1d;
    ssl_session_cache   shared:SSL:10m;
    ssl_session_tickets off;

    # Security headers
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy        "same-origin" always;
    add_header Permissions-Policy     "geolocation=(), microphone=()" always;
    add_header Content-Security-Policy "default-src 'self'; img-src 'self' data:; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; frame-ancestors $frame_ancestors; frame-src 'self' https://*.danielwende.com https://danielwnede-bank.netlify.app;" always;

    # Per-server rate limit (zone defined in nginx.conf)
    limit_req zone=req_limit_per_ip burst=20 nodelay;

    # Block common exploit probes quickly
    location ~* (env|htaccess|htpasswd)$                  { deny all; }
    location ~* (o|test|info|readme|license)\.php$        { deny all; }
    location ~* ^/(wp-admin|wp-content|wp-includes|vendor|cgi-bin|\.well-known/.*acme-challenge).* {
        return 444;
    }

    # Reverse proxy to backend
    location / {
        proxy_pass          http://backend;
        proxy_http_version  1.1;
        proxy_set_header    Host              $host;
        proxy_set_header    X-Real-IP         $remote_addr;
        proxy_set_header    X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto $scheme;        
        proxy_set_header    Upgrade           $http_upgrade;
        proxy_set_header    Connection        "upgrade";
    }

    # Custom error pages
    error_page 404 /404.html;
    location = /404.html { root /www/html; internal; }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html { root /www/html; internal; }
}
