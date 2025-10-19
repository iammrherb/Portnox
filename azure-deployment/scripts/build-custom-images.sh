#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root or with sudo"
    exit 1
fi

log_info "Building custom Portnox images..."
echo ""

log_info "Building portnox/radius:latest..."
mkdir -p /tmp/portnox-radius
cat > /tmp/portnox-radius/Dockerfile <<'EOF'
FROM freeradius/freeradius-server:latest

RUN apt-get update && apt-get install -y \
    freeradius-ldap \
    freeradius-krb5 \
    freeradius-postgresql \
    freeradius-mysql \
    freeradius-rest \
    openssl \
    && rm -rf /var/lib/apt/lists/*

COPY raddb/ /etc/raddb/

EXPOSE 1812/udp 1813/udp 18120/tcp

CMD ["radiusd", "-f", "-X"]
EOF

mkdir -p /tmp/portnox-radius/raddb
cat > /tmp/portnox-radius/raddb/clients.conf <<'EOF'
client localhost {
    ipaddr = 127.0.0.1
    secret = testing123
    require_message_authenticator = no
}

client any {
    ipaddr = 0.0.0.0/0
    secret = testing123
    require_message_authenticator = no
}
EOF

cd /tmp/portnox-radius
if docker build -t portnox/radius:latest .; then
    log_success "✓ portnox/radius:latest built successfully"
else
    log_error "✗ Failed to build portnox/radius:latest"
fi
cd - > /dev/null

echo ""
log_info "Building portnox/tacacs:latest..."
mkdir -p /tmp/portnox-tacacs
cat > /tmp/portnox-tacacs/Dockerfile <<'EOF'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    tacacs+ \
    && rm -rf /var/lib/apt/lists/*

COPY tac_plus.conf /etc/tacacs+/tac_plus.conf

RUN mkdir -p /var/log && touch /var/log/tac_plus.acct

EXPOSE 49/tcp

CMD ["/usr/sbin/tac_plus", "-C", "/etc/tacacs+/tac_plus.conf", "-G", "-d", "16"]
EOF

cat > /tmp/portnox-tacacs/tac_plus.conf <<'EOF'
key = tacacskey123

accounting file = /var/log/tac_plus.acct

user = admin {
    login = cleartext "admin"
    service = exec {
        priv-lvl = 15
    }
}

user = operator {
    login = cleartext "operator"
    service = exec {
        priv-lvl = 1
    }
}

group = admins {
    default service = permit
    service = exec {
        priv-lvl = 15
    }
}

group = operators {
    default service = permit
    service = exec {
        priv-lvl = 1
    }
}
EOF

cd /tmp/portnox-tacacs
if docker build -t portnox/tacacs:latest .; then
    log_success "✓ portnox/tacacs:latest built successfully"
else
    log_error "✗ Failed to build portnox/tacacs:latest"
fi
cd - > /dev/null

echo ""
log_info "Building portnox/ztna-gateway:latest..."
mkdir -p /tmp/portnox-ztna
cat > /tmp/portnox-ztna/Dockerfile <<'EOF'
FROM nginx:alpine

RUN apk add --no-cache \
    openssl \
    curl \
    jq

RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/key.pem \
    -out /etc/nginx/ssl/cert.pem \
    -subj "/C=US/ST=State/L=City/O=Portnox/CN=ztna-gateway"

COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

EXPOSE 443 8443

CMD ["nginx", "-g", "daemon off;"]
EOF

cat > /tmp/portnox-ztna/nginx.conf <<'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    keepalive_timeout 65;
    
    include /etc/nginx/conf.d/*.conf;
}
EOF

cat > /tmp/portnox-ztna/default.conf <<'EOF'
server {
    listen 443 ssl;
    server_name ztna-gateway;
    
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    location / {
        return 200 "ZTNA Gateway Active\n";
        add_header Content-Type text/plain;
    }
    
    location /health {
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
}
EOF

cd /tmp/portnox-ztna
if docker build -t portnox/ztna-gateway:latest .; then
    log_success "✓ portnox/ztna-gateway:latest built successfully"
else
    log_error "✗ Failed to build portnox/ztna-gateway:latest"
fi
cd - > /dev/null

echo ""
log_info "Cleaning up temporary files..."
rm -rf /tmp/portnox-radius /tmp/portnox-tacacs /tmp/portnox-ztna

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║              Custom Image Build Summary                          ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

log_info "Verifying built images:"
docker images | grep portnox

echo ""
if docker images | grep -q "portnox/radius"; then
    log_success "✓ portnox/radius:latest is available"
else
    log_warning "✗ portnox/radius:latest not found"
fi

if docker images | grep -q "portnox/tacacs"; then
    log_success "✓ portnox/tacacs:latest is available"
else
    log_warning "✗ portnox/tacacs:latest not found"
fi

if docker images | grep -q "portnox/ztna-gateway"; then
    log_success "✓ portnox/ztna-gateway:latest is available"
else
    log_warning "✗ portnox/ztna-gateway:latest not found"
fi

echo ""
log_success "Custom image build complete!"
echo ""
echo "You can now deploy labs that use these images:"
echo "  • sudo containerlab deploy -t /data/labs/portnox-radius-802.1x.clab.yml"
echo "  • sudo containerlab deploy -t /data/labs/portnox-tacacs-plus.clab.yml"
echo "  • sudo containerlab deploy -t /data/labs/portnox-ztna-deployment.clab.yml"
echo ""

exit 0
