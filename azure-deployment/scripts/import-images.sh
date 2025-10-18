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

log_info "Starting container image import..."


declare -a NOS_IMAGES=(
    "ghcr.io/nokia/srlinux:latest"
    "ghcr.io/nokia/srlinux:23.10.1"
    "frrouting/frr:latest"
    "frrouting/frr:v8.5.0"
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
)

declare -a APP_IMAGES=(
    "nginx:alpine"
    "nginx:latest"
    "haproxy:alpine"
    "haproxy:latest"
    "postgres:15-alpine"
    "postgres:latest"
    "redis:alpine"
    "redis:latest"
)

declare -a UTIL_IMAGES=(
    "ubuntu:22.04"
    "ubuntu:20.04"
    "alpine:latest"
    "alpine:3.18"
    "busybox:latest"
    "networkstatic/iperf3:latest"
)

declare -a MONITOR_IMAGES=(
    "prom/prometheus:latest"
    "grafana/grafana:latest"
    "prom/node-exporter:latest"
    "prom/alertmanager:latest"
)


pull_images() {
    local category=$1
    shift
    local images=("$@")
    
    log_info "Pulling $category images..."
    
    for image in "${images[@]}"; do
        log_info "Pulling $image..."
        if docker pull "$image"; then
            log_success "✓ $image"
        else
            log_warning "✗ Failed to pull $image"
        fi
    done
    
    echo ""
}


pull_images "Network OS" "${NOS_IMAGES[@]}"
pull_images "Authentication" "${AUTH_IMAGES[@]}"
pull_images "Identity Provider" "${IDP_IMAGES[@]}"
pull_images "Application" "${APP_IMAGES[@]}"
pull_images "Utility" "${UTIL_IMAGES[@]}"
pull_images "Monitoring" "${MONITOR_IMAGES[@]}"


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
fi


log_info "Creating image tags..."

docker tag freeradius/freeradius-server:latest radius:latest || true
docker tag dchidell/docker-tacacs:latest tacacs:latest || true
docker tag nginx:alpine web:latest || true
docker tag ubuntu:22.04 linux:latest || true

log_success "Image tags created"

# Display summary

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║              Image Import Summary                                 ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

log_info "Listing all imported images:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -30

echo ""
log_info "Total images: $(docker images | wc -l)"
log_info "Total disk usage: $(docker system df | grep Images | awk '{print $3}')"
echo ""

log_success "Image import complete!"


log_info "Cleaning up temporary files..."
rm -rf /tmp/portnox-radius /tmp/portnox-tacacs

log_info "Pruning unused images..."
docker image prune -f

echo ""
log_success "All done!"

exit 0
