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

log_info "Installing GUI and authentication tools..."
echo ""

log_info "Installing XFCE desktop environment..."
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xrdp \
    firefox \
    chromium-browser \
    dbus-x11 \
    x11-xserver-utils

log_info "Configuring XRDP..."
systemctl enable xrdp
systemctl start xrdp

ufw allow 3389/tcp 2>/dev/null || true

log_success "XFCE desktop and XRDP installed"

log_info "Installing Antimony GUI..."

if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
fi

cd /opt || exit 1
if [ ! -d "antimony" ]; then
    git clone https://github.com/srl-labs/containerlab-antimony.git antimony
fi

cd antimony || exit 1
npm install --production

cat > /etc/systemd/system/antimony.service <<'EOF'
[Unit]
Description=Antimony ContainerLab GUI
After=network.target docker.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/antimony
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=PORT=8080
Environment=CLAB_API=http://localhost:8443

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable antimony
systemctl start antimony

log_success "Antimony GUI installed and running on port 8080"

log_info "Installing EdgeShark..."

# Install dependencies
apt-get install -y \
    wireshark \
    tshark \
    tcpdump \
    python3-pip

pip3 install edgeshark

cat > /etc/systemd/system/edgeshark.service <<'EOF'
[Unit]
Description=EdgeShark Container Network Analysis
After=network.target docker.service

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/edgeshark serve --port 5001
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable edgeshark
systemctl start edgeshark

log_success "EdgeShark installed and running on port 5001"

log_info "Installing 802.1X client tools and network utilities..."

apt-get install -y \
    wpasupplicant \
    iproute2 \
    net-tools \
    bridge-utils \
    vlan \
    ebtables

log_success "802.1X client tools and network utilities installed"

log_info "Creating wpa_supplicant configuration templates..."

mkdir -p /data/configs/wpa_supplicant

cat > /data/configs/wpa_supplicant/eap-tls.conf <<'EOF'
network={
    ssid="Enterprise-Network"
    key_mgmt=WPA-EAP
    eap=TLS
    identity="user@example.com"
    ca_cert="/data/configs/ca/ca.crt"
    client_cert="/data/configs/ca/client.crt"
    private_key="/data/configs/ca/client.key"
    private_key_passwd="password"
}
EOF

cat > /data/configs/wpa_supplicant/eap-peap.conf <<'EOF'
network={
    ssid="Enterprise-Network"
    key_mgmt=WPA-EAP
    eap=PEAP
    identity="user@example.com"
    password="password"
    ca_cert="/data/configs/ca/ca.crt"
    phase2="auth=MSCHAPV2"
}
EOF

cat > /data/configs/wpa_supplicant/eap-ttls.conf <<'EOF'
network={
    ssid="Enterprise-Network"
    key_mgmt=WPA-EAP
    eap=TTLS
    identity="user@example.com"
    password="password"
    ca_cert="/data/configs/ca/ca.crt"
    phase2="auth=PAP"
}
EOF

cat > /data/configs/wpa_supplicant/wired-8021x.conf <<'EOF'
ap_scan=0
network={
    key_mgmt=IEEE8021X
    eap=PEAP
    identity="user@example.com"
    password="password"
    ca_cert="/data/configs/ca/ca.crt"
    phase2="auth=MSCHAPV2"
}
EOF

log_success "wpa_supplicant configuration templates created"

log_info "Creating 802.1X automation script..."

cat > /usr/local/bin/test-8021x <<'EOF'
#!/bin/bash


if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <interface> <config-file>"
    echo "Example: $0 eth1 /data/configs/wpa_supplicant/eap-peap.conf"
    exit 1
fi

INTERFACE=$1
CONFIG=$2

if [ ! -f "$CONFIG" ]; then
    echo "Error: Config file $CONFIG not found"
    exit 1
fi

echo "Starting 802.1X authentication on $INTERFACE..."
echo "Config: $CONFIG"

pkill -f "wpa_supplicant.*$INTERFACE" 2>/dev/null

wpa_supplicant -i "$INTERFACE" -c "$CONFIG" -D wired -dd

EOF

chmod +x /usr/local/bin/test-8021x

log_success "802.1X automation script created: /usr/local/bin/test-8021x"

log_info "Creating Portnox Agent installation helper..."

cat > /usr/local/bin/install-portnox-agent <<'EOF'
#!/bin/bash


echo "Portnox Agent Headless Installation"
echo "===================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Error: Please run as root or with sudo"
    exit 1
fi

read -p "Enter Portnox Cloud URL (e.g., https://yourorg.portnox.cloud): " PORTNOX_URL
read -p "Enter Enrollment Token: " ENROLLMENT_TOKEN

if [ -z "$PORTNOX_URL" ] || [ -z "$ENROLLMENT_TOKEN" ]; then
    echo "Error: Both URL and token are required"
    exit 1
fi

echo "Downloading Portnox Agent..."
wget -O /tmp/portnox-agent.deb "${PORTNOX_URL}/downloads/agent/linux/portnox-agent-latest.deb"

echo "Installing Portnox Agent..."
dpkg -i /tmp/portnox-agent.deb || apt-get install -f -y

echo "Configuring Portnox Agent..."
cat > /etc/portnox/agent.conf <<AGENTCONF
{
    "cloud_url": "${PORTNOX_URL}",
    "enrollment_token": "${ENROLLMENT_TOKEN}",
    "auto_enroll": true
}
AGENTCONF

echo "Starting Portnox Agent..."
systemctl enable portnox-agent
systemctl start portnox-agent

echo ""
echo "Portnox Agent installed successfully!"
echo "Check status: systemctl status portnox-agent"

EOF

chmod +x /usr/local/bin/install-portnox-agent

log_success "Portnox Agent installation helper created: /usr/local/bin/install-portnox-agent"

cat > /usr/local/bin/test-radius <<'EOF'
#!/bin/bash


if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <radius-server>"
    echo "Example: $0 172.20.20.50"
    echo ""
    echo "This script tests network connectivity to a RADIUS server."
    echo "For full RADIUS authentication testing, use:"
    echo "  1. Portnox Cloud portal (recommended)"
    echo "  2. Deploy a test client container with wpa_supplicant"
    echo "  3. Use test-8021x script for 802.1X authentication"
    exit 1
fi

SERVER=$1

echo "Testing RADIUS server connectivity..."
echo "Server: $SERVER"
echo ""

if command -v nc &> /dev/null; then
    if timeout 5 nc -zvu "$SERVER" 1812 2>&1 | grep -q "succeeded\|open"; then
        echo "✓ RADIUS server is reachable on UDP port 1812"
    else
        echo "✗ Cannot reach RADIUS server on UDP port 1812"
        exit 1
    fi
    
    if timeout 5 nc -zvu "$SERVER" 1813 2>&1 | grep -q "succeeded\|open"; then
        echo "✓ RADIUS accounting server is reachable on UDP port 1813"
    else
        echo "⚠ Cannot reach RADIUS accounting server on UDP port 1813"
    fi
else
    echo "⚠ netcat (nc) not available, skipping connectivity test"
fi

echo ""
echo "Network connectivity test complete!"
echo "For full RADIUS authentication testing, use the Portnox Cloud portal."

EOF

chmod +x /usr/local/bin/test-radius

log_success "RADIUS test script created: /usr/local/bin/test-radius"

HOSTNAME=$(hostname -f)
IP=$(hostname -I | awk '{print $1}')

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║              GUI and Tools Installation Complete                 ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

log_success "Installation complete!"
echo ""
log_info "Access Information:"
echo "  Antimony GUI:    http://${HOSTNAME}:8080 or http://${IP}:8080"
echo "  EdgeShark:       http://${HOSTNAME}:5001 or http://${IP}:5001"
echo "  RDP Access:      ${HOSTNAME}:3389 or ${IP}:3389"
echo "    Username:      azureuser"
echo "    Password:      (your SSH key password or set with: sudo passwd azureuser)"
echo ""
log_info "Installed Tools:"
echo "  test-8021x       - Test 802.1X authentication"
echo "  test-radius      - Test RADIUS authentication"
echo "  install-portnox-agent - Install Portnox Agent (headless)"
echo ""
log_info "Configuration Files:"
echo "  /data/configs/wpa_supplicant/ - 802.1X configuration templates"
echo "  /data/configs/ca/             - CA certificates"
echo ""

exit 0
