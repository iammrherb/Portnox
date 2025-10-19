#!/bin/bash


set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root or with sudo"
    exit 1
fi

log_info "Starting ContainerLab setup..."


log_info "Updating system packages..."
apt-get update -y
apt-get upgrade -y

log_info "Installing base packages..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    git \
    wget \
    jq \
    vim \
    nano \
    htop \
    net-tools \
    iputils-ping \
    traceroute \
    tcpdump \
    iperf3 \
    bridge-utils \
    vlan \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev \
    unzip \
    zip

log_success "Base packages installed"


log_info "Installing Docker..."

systemctl stop docker.socket 2>/dev/null || true
systemctl stop docker.service 2>/dev/null || true
systemctl disable docker.socket 2>/dev/null || true
systemctl disable docker.service 2>/dev/null || true

apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
apt-get autoremove -y 2>/dev/null || true

rm -rf /var/lib/docker
rm -rf /etc/docker
rm -f /etc/systemd/system/docker.service.d/*.conf
rm -f /etc/systemd/system/docker.socket.d/*.conf

apt-get update -y
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y

mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-address-pools": [
    {
      "base": "172.20.0.0/16",
      "size": 24
    }
  ],
  "ipv6": false,
  "experimental": false,
  "live-restore": true
}
EOF

DEBIAN_FRONTEND=noninteractive apt-get install -y -o Dpkg::Options::="--force-confnew" \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
    log_warning "Docker installation reported errors, but packages may be installed"
}

usermod -aG docker azureuser
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "azureuser" ]; then
    usermod -aG docker $SUDO_USER
    log_info "Added $SUDO_USER to docker group"
fi

log_info "Configuring Docker service..."
systemctl daemon-reload

systemctl unmask docker.service 2>/dev/null || true
systemctl unmask docker.socket 2>/dev/null || true

systemctl disable docker.socket 2>/dev/null || true

systemctl enable docker.service

log_info "Starting Docker service..."
if ! systemctl start docker.service; then
    log_warning "Initial Docker start failed, checking status..."
    systemctl status docker.service --no-pager || true
    journalctl -xeu docker.service --no-pager -n 50 || true
    
    log_info "Attempting to fix and restart Docker..."
    systemctl stop docker.service 2>/dev/null || true
    systemctl stop docker.socket 2>/dev/null || true
    
    pkill -9 dockerd 2>/dev/null || true
    pkill -9 containerd 2>/dev/null || true
    
    sleep 3
    
    systemctl daemon-reload
    systemctl reset-failed docker.service 2>/dev/null || true
    
    if ! systemctl start docker.service; then
        log_error "Docker service failed to start after troubleshooting"
        systemctl status docker.service --no-pager || true
        journalctl -xeu docker.service --no-pager -n 100 || true
        exit 1
    fi
fi

log_success "Docker service started"

log_info "Waiting for Docker to initialize..."
sleep 10

MAX_RETRIES=30
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if docker ps >/dev/null 2>&1; then
        log_success "Docker is running and responsive"
        docker --version
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        log_error "Docker failed to become responsive after $MAX_RETRIES attempts"
        systemctl status docker --no-pager || true
        journalctl -xeu docker.service --no-pager -n 100 || true
        exit 1
    fi
    
    log_info "Waiting for Docker to be ready... (attempt $RETRY_COUNT/$MAX_RETRIES)"
    sleep 2
done

log_success "Docker installed and configured"


log_info "Installing ContainerLab..."

bash -c "$(curl -sL https://get.containerlab.dev)"

# Verify installation
if command -v containerlab &> /dev/null; then
    CLAB_VERSION=$(containerlab version | grep version | awk '{print $2}')
    log_success "ContainerLab $CLAB_VERSION installed successfully"
else
    log_error "ContainerLab installation failed"
    exit 1
fi

log_success "ContainerLab installed"


log_info "Installing additional network tools..."

curl -s https://deb.frrouting.org/frr/keys.asc | apt-key add -
echo deb https://deb.frrouting.org/frr $(lsb_release -s -c) frr-stable | tee -a /etc/apt/sources.list.d/frr.list
apt-get update -y
apt-get install -y frr frr-pythontools

apt-get install -y \
    iproute2 \
    iptables \
    nftables \
    ethtool \
    socat \
    netcat \
    nmap

log_success "Network tools installed"


log_info "Installing Go..."

GO_VERSION="1.21.5"
wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
rm go${GO_VERSION}.linux-amd64.tar.gz

cat >> /etc/profile.d/go.sh <<EOF
export PATH=\$PATH:/usr/local/go/bin
export GOPATH=/root/go
export PATH=\$PATH:\$GOPATH/bin
EOF

source /etc/profile.d/go.sh

log_success "Go installed"


log_info "Installing Python packages..."

pip3 install --upgrade pip

pip3 install \
    ansible \
    netmiko \
    napalm \
    nornir \
    nornir-netmiko \
    nornir-napalm \
    paramiko \
    jinja2 \
    pyyaml \
    requests \
    pyrad \
    tacacs_plus \
    cryptography

log_success "Python packages installed"


log_info "Installing kubectl..."

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

log_info "Installing Helm..."

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

log_success "kubectl and Helm installed"


log_info "Setting up VRNetlab..."

mkdir -p /opt/vrnetlab
cd /opt/vrnetlab

git clone https://github.com/vrnetlab/vrnetlab.git . || log_warning "VRNetlab clone failed"

if [ -f requirements.txt ]; then
    pip3 install -r requirements.txt || log_warning "VRNetlab requirements installation failed (non-critical)"
else
    log_warning "VRNetlab requirements.txt not found (non-critical)"
fi

cd /root

log_success "VRNetlab setup complete"


log_info "Creating directory structure..."

mkdir -p /data/containerlab
mkdir -p /data/labs
mkdir -p /data/images
mkdir -p /data/configs
mkdir -p /data/vrnetlab
mkdir -p /data/antimony
mkdir -p /var/log/containerlab
mkdir -p /etc/containerlab

# Set proper permissions
if [ -n "$SUDO_USER" ]; then
    chown -R $SUDO_USER:$SUDO_USER /data
fi

log_success "Directory structure created"


log_info "Configuring system for ContainerLab..."

log_info "Loading kernel modules..."
modprobe bridge 2>/dev/null || log_warning "Bridge module already loaded or not available"
modprobe br_netfilter 2>/dev/null || log_warning "br_netfilter module already loaded or not available"
modprobe veth 2>/dev/null || true
modprobe vxlan 2>/dev/null || true

cat >> /etc/modules <<EOF
bridge
br_netfilter
veth
vxlan
EOF

log_info "Configuring sysctl settings..."
cat >> /etc/sysctl.conf <<EOF

net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.bridge.bridge-nf-call-iptables=0
net.bridge.bridge-nf-call-ip6tables=0
EOF

sysctl -p || log_warning "Some sysctl settings may not have applied (non-critical)"

log_success "System configured"


log_info "Installing FreeRADIUS..."

apt-get install -y freeradius freeradius-utils freeradius-common

systemctl stop freeradius
systemctl disable freeradius

log_success "FreeRADIUS installed"


log_info "Installing TACACS+ server..."

apt-get install -y tacacs+ || log_warning "TACACS+ package not available, will use containerized version"

log_success "TACACS+ setup complete"


log_info "Pulling common container images..."

docker pull ghcr.io/nokia/srlinux:latest || log_warning "Failed to pull SR Linux"
docker pull ceos:latest || log_warning "Failed to pull cEOS (requires manual import)"
docker pull vrnetlab/vr-xrv9k:latest || log_warning "Failed to pull XRv9k"
docker pull vrnetlab/vr-sros:latest || log_warning "Failed to pull SR OS"

docker pull alpine:latest
docker pull ubuntu:22.04
docker pull nginx:alpine
docker pull frrouting/frr:latest

docker pull freeradius/freeradius-server:latest || log_warning "Failed to pull FreeRADIUS"

log_success "Container images pulled"


log_info "Creating helper scripts..."

cat > /usr/local/bin/clab-manage <<'EOF'
#!/bin/bash

case "$1" in
    list)
        containerlab inspect --all
        ;;
    deploy)
        if [ -z "$2" ]; then
            echo "Usage: clab-manage deploy <lab-file>"
            exit 1
        fi
        containerlab deploy -t "$2"
        ;;
    destroy)
        if [ -z "$2" ]; then
            echo "Usage: clab-manage destroy <lab-file>"
            exit 1
        fi
        containerlab destroy -t "$2"
        ;;
    logs)
        if [ -z "$2" ]; then
            echo "Usage: clab-manage logs <container-name>"
            exit 1
        fi
        docker logs -f "$2"
        ;;
    exec)
        if [ -z "$2" ]; then
            echo "Usage: clab-manage exec <container-name> [command]"
            exit 1
        fi
        shift
        CONTAINER=$1
        shift
        docker exec -it "$CONTAINER" ${@:-bash}
        ;;
    status)
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    *)
        echo "Usage: clab-manage {list|deploy|destroy|logs|exec|status}"
        exit 1
        ;;
esac
EOF

chmod +x /usr/local/bin/clab-manage

log_success "Helper scripts created"


log_info "Setting up bash aliases..."

cat >> /etc/bash.bashrc <<'EOF'

alias clab='containerlab'
alias clab-list='containerlab inspect --all'
alias clab-ps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias clab-logs='docker logs -f'
alias clab-exec='docker exec -it'

alias cdlabs='cd /data/labs'
alias cdimages='cd /data/images'
alias cdconfigs='cd /data/configs'

clab-shell() {
    if [ -z "$1" ]; then
        echo "Usage: clab-shell <container-name>"
        return 1
    fi
    docker exec -it "$1" bash 2>/dev/null || docker exec -it "$1" sh
}

clab-ip() {
    if [ -z "$1" ]; then
        echo "Usage: clab-ip <container-name>"
        return 1
    fi
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$1"
}

EOF

log_success "Bash aliases configured"


log_info "Creating systemd service..."

cat > /etc/systemd/system/containerlab-autostart.service <<EOF
[Unit]
Description=ContainerLab Auto-start Service
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/containerlab-autostart.sh
ExecStop=/usr/local/bin/containerlab-autostop.sh

[Install]
WantedBy=multi-user.target
EOF

cat > /usr/local/bin/containerlab-autostart.sh <<'EOF'
#!/bin/bash

LABS_DIR="/data/labs"

if [ -d "$LABS_DIR" ]; then
    for lab in "$LABS_DIR"/*.clab.yml; do
        if [ -f "$lab" ]; then
            echo "Auto-starting lab: $lab"
            containerlab deploy -t "$lab" || echo "Failed to start $lab"
        fi
    done
fi
EOF

cat > /usr/local/bin/containerlab-autostop.sh <<'EOF'
#!/bin/bash

LABS_DIR="/data/labs"

if [ -d "$LABS_DIR" ]; then
    for lab in "$LABS_DIR"/*.clab.yml; do
        if [ -f "$lab" ]; then
            echo "Stopping lab: $lab"
            containerlab destroy -t "$lab" || echo "Failed to stop $lab"
        fi
    done
fi
EOF

chmod +x /usr/local/bin/containerlab-autostart.sh
chmod +x /usr/local/bin/containerlab-autostop.sh


log_success "Systemd service created"


log_info "Performing final configuration..."

cat > /etc/motd <<'EOF'

╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║   Portnox ContainerLab Environment                               ║
║   Azure Deployment                                                ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝

Quick Start Commands:
  clab-list              - List all deployed labs
  clab-manage deploy     - Deploy a lab
  clab-manage destroy    - Destroy a lab
  clab-ps                - Show running containers
  clab-shell <name>      - Open shell in container
  
Directories:
  /data/labs             - Lab topology files
  /data/images           - Container images
  /data/configs          - Configuration files
  /data/vrnetlab         - VRNetlab images

Documentation:
  https://containerlab.dev
  https://github.com/iammrherb/Portnox

EOF

log_success "Setup complete!"

# Display summary

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                    Installation Summary                          ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "✓ Docker $(docker --version | awk '{print $3}')"
echo "✓ ContainerLab $(containerlab version | grep version | awk '{print $2}')"
echo "✓ Go $(go version | awk '{print $3}')"
echo "✓ Python $(python3 --version | awk '{print $2}')"
echo "✓ kubectl $(kubectl version --client --short 2>/dev/null | awk '{print $3}')"
echo "✓ Helm $(helm version --short | awk '{print $1}')"
echo ""

log_info "Setting up Antimony GUI..."
if [ -f /tmp/setup-antimony.sh ]; then
    bash /tmp/setup-antimony.sh || log_warning "Antimony setup failed, but continuing..."
else
    log_warning "Antimony setup script not found at /tmp/setup-antimony.sh"
fi

log_info "Importing container images..."
if [ -f /tmp/import-images-comprehensive.sh ]; then
    bash /tmp/import-images-comprehensive.sh || log_warning "Image import failed, but continuing..."
elif [ -f /tmp/import-images.sh ]; then
    bash /tmp/import-images.sh || log_warning "Image import failed, but continuing..."
else
    log_warning "Image import script not found"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                    Deployment Complete!                          ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Access your lab environment:"
echo "  • Antimony GUI: http://$(hostname -I | awk '{print $1}'):8080"
echo "  • SSH: ssh azureuser@$(hostname -I | awk '{print $1}')"
echo "  • Labs directory: /data/labs"
echo ""
echo "Quick start commands:"
echo "  • List labs: sudo containerlab inspect --all"
echo "  • Deploy lab: sudo containerlab deploy -t /data/labs/<lab-file>"
echo "  • Destroy lab: sudo containerlab destroy -t /data/labs/<lab-file>"
echo "  • View images: docker images"
echo ""
echo "For detailed documentation, see: /data/COMPREHENSIVE_GUIDE.md"
echo ""

exit 0
