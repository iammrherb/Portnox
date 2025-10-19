#!/bin/bash

set -e

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

log_info "Starting comprehensive container image import..."
echo "This will download images for all supported vendors and platforms"
echo ""

declare -a NOKIA_IMAGES=(
    "ghcr.io/nokia/srlinux:latest"
    "ghcr.io/nokia/srlinux:23.10.1"
    "ghcr.io/nokia/srlinux:23.7.1"
    "ghcr.io/nokia/srlinux:22.11.2"
)

declare -a ARISTA_IMAGES=(
    "ceos:latest"
    "ceos:4.30.0F"
    "ceos:4.29.2F"
)

declare -a CISCO_IMAGES=(
    "vrnetlab/vr-xrv9k:latest"
    "vrnetlab/vr-xrv:latest"
    "vrnetlab/vr-csr:latest"
    "vrnetlab/vr-n9kv:latest"
    "vrnetlab/vr-nxos:latest"
)

declare -a JUNIPER_IMAGES=(
    "vrnetlab/vr-vmx:latest"
    "vrnetlab/vr-vqfx:latest"
    "vrnetlab/vr-vsrx:latest"
    "vrnetlab/vr-vjunosevolved:latest"
)

declare -a PALOALTO_IMAGES=(
    "vrnetlab/vr-pan:latest"
)

declare -a FORTINET_IMAGES=(
    "vrnetlab/vr-ftdv:latest"
    "vrnetlab/vr-fortios:latest"
)

declare -a ARUBA_IMAGES=(
    "vrnetlab/vr-aoscx:latest"
)

declare -a HP_IMAGES=(
    "vrnetlab/vr-hp-comware:latest"
)

declare -a DELL_IMAGES=(
    "vrnetlab/vr-dell-os10:latest"
)

declare -a EXTREME_IMAGES=(
    "vrnetlab/vr-exos:latest"
)

declare -a FRROUTING_IMAGES=(
    "frrouting/frr:latest"
    "frrouting/frr:v9.0.0"
    "frrouting/frr:v8.5.0"
)

declare -a PORTNOX_IMAGES=(
    "portnox/radius-server:latest"
    "portnox/tacacs-server:latest"
    "portnox/ztna-gateway:latest"
)

declare -a AUTH_IMAGES=(
    "freeradius/freeradius-server:latest"
    "freeradius/freeradius-server:3.2.3"
    "dchidell/docker-tacacs:latest"
)

declare -a IDP_IMAGES=(
    "osixia/openldap:latest"
    "osixia/openldap:1.5.0"
    "kristophjunge/test-saml-idp:latest"
    "quay.io/keycloak/keycloak:latest"
)

declare -a APP_IMAGES=(
    "nginx:alpine"
    "nginx:latest"
    "haproxy:alpine"
    "haproxy:latest"
    "postgres:15-alpine"
    "postgres:latest"
    "mysql:8.0"
    "redis:alpine"
    "redis:latest"
    "mongo:latest"
)

declare -a UTIL_IMAGES=(
    "ubuntu:22.04"
    "ubuntu:20.04"
    "alpine:latest"
    "alpine:3.18"
    "busybox:latest"
    "networkstatic/iperf3:latest"
    "nicolaka/netshoot:latest"
)

declare -a MONITOR_IMAGES=(
    "prom/prometheus:latest"
    "grafana/grafana:latest"
    "prom/node-exporter:latest"
    "prom/alertmanager:latest"
    "prom/blackbox-exporter:latest"
)

declare -a ENDPOINT_IMAGES=(
    "ubuntu:22.04"
    "alpine:latest"
    "nicolaka/netshoot:latest"
)

declare -a SRLABS_IMAGES=(
    "ghcr.io/srl-labs/clab-io-draw:latest"
    "ghcr.io/srl-labs/network-multitool:latest"
)

pull_images() {
    local category=$1
    shift
    local images=("$@")
    
    log_info "Pulling $category images..."
    
    local success=0
    local failed=0
    
    for image in "${images[@]}"; do
        log_info "Pulling $image..."
        if docker pull "$image" 2>/dev/null; then
            log_success "✓ $image"
            ((success++))
        else
            log_warning "✗ Failed to pull $image (may require manual import)"
            ((failed++))
        fi
    done
    
    log_info "$category: $success succeeded, $failed failed"
    echo ""
}

pull_images "Nokia SR Linux" "${NOKIA_IMAGES[@]}"
pull_images "Arista cEOS" "${ARISTA_IMAGES[@]}"
pull_images "Cisco (VRNetlab)" "${CISCO_IMAGES[@]}"
pull_images "Juniper (VRNetlab)" "${JUNIPER_IMAGES[@]}"
pull_images "Palo Alto (VRNetlab)" "${PALOALTO_IMAGES[@]}"
pull_images "Fortinet (VRNetlab)" "${FORTINET_IMAGES[@]}"
pull_images "Aruba (VRNetlab)" "${ARUBA_IMAGES[@]}"
pull_images "HP (VRNetlab)" "${HP_IMAGES[@]}"
pull_images "Dell (VRNetlab)" "${DELL_IMAGES[@]}"
pull_images "Extreme (VRNetlab)" "${EXTREME_IMAGES[@]}"
pull_images "FRRouting" "${FRROUTING_IMAGES[@]}"
pull_images "Portnox" "${PORTNOX_IMAGES[@]}"
pull_images "Authentication" "${AUTH_IMAGES[@]}"
pull_images "Identity Provider" "${IDP_IMAGES[@]}"
pull_images "Application" "${APP_IMAGES[@]}"
pull_images "Utility" "${UTIL_IMAGES[@]}"
pull_images "Monitoring" "${MONITOR_IMAGES[@]}"
pull_images "Endpoints" "${ENDPOINT_IMAGES[@]}"
pull_images "SR Labs Tools" "${SRLABS_IMAGES[@]}"

log_info "Building custom Portnox images..."

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
docker build -t portnox/radius:latest . || log_warning "Failed to build portnox/radius"
cd -

mkdir -p /tmp/portnox-tacacs
cat > /tmp/portnox-tacacs/Dockerfile <<'EOF'
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    tacacs+ \
    libpam-ldap \
    libpam-krb5 \
    && rm -rf /var/lib/apt/lists/*

COPY tac_plus.conf /etc/tacacs+/tac_plus.conf

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
docker build -t portnox/tacacs:latest . || log_warning "Failed to build portnox/tacacs"
cd -

mkdir -p /tmp/portnox-ztna
cat > /tmp/portnox-ztna/Dockerfile <<'EOF'
FROM nginx:alpine

RUN apk add --no-cache \
    openssl \
    curl \
    jq

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
docker build -t portnox/ztna-gateway:latest . || log_warning "Failed to build portnox/ztna-gateway"
cd -

log_success "Custom images built"

log_info "Checking for VRNetlab images..."

VRNETLAB_DIR="/data/vrnetlab"
if [ -d "$VRNETLAB_DIR" ]; then
    log_info "VRNetlab directory found, importing images..."
    
    for vendor_dir in "$VRNETLAB_DIR"/*; do
        if [ -d "$vendor_dir" ]; then
            vendor=$(basename "$vendor_dir")
            log_info "Processing $vendor images..."
            
            for image_tar in "$vendor_dir"/*.tar; do
                if [ -f "$image_tar" ]; then
                    log_info "Loading $(basename $image_tar)..."
                    docker load -i "$image_tar" || log_warning "Failed to load $image_tar"
                fi
            done
        fi
    done
else
    log_warning "VRNetlab directory not found at $VRNETLAB_DIR"
    log_info "Place vendor images in $VRNETLAB_DIR/<vendor>/ for automatic import"
fi

log_info "Creating image tags..."

docker tag freeradius/freeradius-server:latest radius:latest 2>/dev/null || true
docker tag dchidell/docker-tacacs:latest tacacs:latest 2>/dev/null || true
docker tag nginx:alpine web:latest 2>/dev/null || true
docker tag ubuntu:22.04 linux:latest 2>/dev/null || true
docker tag ghcr.io/nokia/srlinux:latest srlinux:latest 2>/dev/null || true
docker tag frrouting/frr:latest frr:latest 2>/dev/null || true

log_success "Image tags created"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║              Comprehensive Image Import Summary                  ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

log_info "Listing all imported images:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -50

echo ""
log_info "Total images: $(docker images | wc -l)"
log_info "Total disk usage: $(docker system df | grep Images | awk '{print $3}')"
echo ""

log_info "Images by vendor:"
echo "  Nokia SR Linux: $(docker images | grep -c srlinux || echo 0)"
echo "  Arista cEOS: $(docker images | grep -c ceos || echo 0)"
echo "  Cisco: $(docker images | grep -c 'vr-xrv\|vr-csr\|vr-n9kv' || echo 0)"
echo "  Juniper: $(docker images | grep -c 'vr-vmx\|vr-vqfx\|vr-vsrx' || echo 0)"
echo "  Palo Alto: $(docker images | grep -c vr-pan || echo 0)"
echo "  Fortinet: $(docker images | grep -c 'vr-ftdv\|vr-fortios' || echo 0)"
echo "  FRRouting: $(docker images | grep -c frrouting || echo 0)"
echo "  Portnox: $(docker images | grep -c portnox || echo 0)"
echo ""

log_success "Image import complete!"

log_info "Cleaning up temporary files..."
rm -rf /tmp/portnox-radius /tmp/portnox-tacacs /tmp/portnox-ztna

log_info "Pruning unused images..."
docker image prune -f

echo ""
log_success "All done! $(docker images | wc -l) images ready for use"

exit 0
