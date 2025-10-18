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

apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

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
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

usermod -aG docker azureuser
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "azureuser" ]; then
    usermod -aG docker $SUDO_USER
    log_info "Added $SUDO_USER to docker group"
fi

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

systemctl daemon-reload
systemctl enable docker

log_info "Starting Docker service..."
if systemctl start docker; then
    log_success "Docker service started successfully"
else
    log_error "Failed to start Docker service, checking status..."
    systemctl status docker --no-pager || true
    journalctl -xeu docker.service --no-pager -n 50 || true
    
    log_warning "Attempting to fix Docker service..."
    systemctl stop docker || true
    rm -rf /var/lib/docker/network/files/* || true
    systemctl daemon-reload
    systemctl start docker || {
        log_error "Docker service failed to start after troubleshooting"
        exit 1
    }
fi

sleep 5
if docker ps >/dev/null 2>&1; then
    log_success "Docker is running and responsive"
    docker --version
else
    log_error "Docker is not responding"
    systemctl status docker --no-pager
    exit 1
fi

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

git clone https://github.com/vrnetlab/vrnetlab.git .

pip3 install -r requirements.txt || true

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

cat >> /etc/sysctl.conf <<EOF

net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.bridge.bridge-nf-call-iptables=0
net.bridge.bridge-nf-call-ip6tables=0
EOF

sysctl -p

modprobe bridge
modprobe br_netfilter
modprobe veth
modprobe vxlan

cat >> /etc/modules <<EOF
bridge
br_netfilter
veth
vxlan
EOF

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
echo "Next steps:"
echo "  1. Log out and log back in for group changes to take effect"
echo "  2. Run setup-antimony.sh to install Antimony GUI"
echo "  3. Run import-images.sh to import container images"
echo "  4. Deploy labs from /data/labs directory"
echo ""
echo "For help, run: clab-manage"
echo ""

exit 0
