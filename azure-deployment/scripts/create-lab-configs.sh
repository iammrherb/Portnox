#!/bin/bash


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}[ERROR]${NC} Please run as root or with sudo"
    exit 1
fi

log_info "Creating lab configuration files and directories..."

mkdir -p /data/configs/{ca,apps/{webapp,api,db,file,ssh,rdp},frr,prometheus,grafana}
mkdir -p /data/labs

log_info "Creating CA certificates..."
cd /data/configs/ca || exit 1

cat > openssl.cnf <<'EOF'
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no

[req_distinguished_name]
C = US
ST = State
L = City
O = Example Inc
CN = Example CA

[v3_ca]
basicConstraints = CA:TRUE
keyUsage = keyCertSign, cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
EOF

openssl genrsa -out ca.key 4096 2>/dev/null
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -config openssl.cnf 2>/dev/null

openssl genrsa -out server.key 2048 2>/dev/null
openssl req -new -key server.key -out server.csr -subj "/C=US/ST=State/L=City/O=Example Inc/CN=radius.example.com" 2>/dev/null
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 365 2>/dev/null

openssl genrsa -out client.key 2048 2>/dev/null
openssl req -new -key client.key -out client.csr -subj "/C=US/ST=State/L=City/O=Example Inc/CN=client.example.com" 2>/dev/null
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 365 2>/dev/null

log_success "CA certificates created"

log_info "Creating Prometheus configuration..."
cat > /data/configs/prometheus/prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'containerlab'
    static_configs:
      - targets: ['localhost:8080']
EOF

cp /data/configs/prometheus/prometheus.yml /data/labs/prometheus.yml

log_success "Prometheus configuration created"

log_info "Creating FRR router configurations..."

mkdir -p /data/labs/frr-router-1-config
cat > /data/labs/frr-router-1-config/daemons <<'EOF'
bgpd=yes
ospfd=yes
zebra=yes
vtysh_enable=yes
EOF

cat > /data/labs/frr-router-1-config/frr.conf <<'EOF'
hostname frr-router1
password admin
enable password admin

interface eth1
 ip address 10.0.10.2/24

router bgp 65001
 bgp router-id 10.0.10.2
 neighbor 10.0.10.1 remote-as 65001
 address-family ipv4 unicast
  network 10.0.10.0/24
  neighbor 10.0.10.1 activate
 exit-address-family

line vty
EOF

mkdir -p /data/labs/frr-router-2-config
cat > /data/labs/frr-router-2-config/daemons <<'EOF'
bgpd=yes
ospfd=yes
zebra=yes
vtysh_enable=yes
EOF

cat > /data/labs/frr-router-2-config/frr.conf <<'EOF'
hostname frr-router2
password admin
enable password admin

interface eth1
 ip address 10.0.20.2/24

router bgp 65002
 bgp router-id 10.0.20.2
 neighbor 10.0.20.1 remote-as 65002
 address-family ipv4 unicast
  network 10.0.20.0/24
  neighbor 10.0.20.1 activate
 exit-address-family

line vty
EOF

log_success "FRR configurations created"

log_info "Creating application configurations..."

mkdir -p /data/configs/apps/webapp
cat > /data/configs/apps/webapp/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Protected Web App</title>
</head>
<body>
    <h1>Protected Web Application</h1>
    <p>This is a sample protected web application for ZTNA testing.</p>
</body>
</html>
EOF

mkdir -p /data/configs/apps/api
cat > /data/configs/apps/api/app.py <<'EOF'
from flask import Flask, jsonify
app = Flask(__name__)

@app.route('/api/health')
def health():
    return jsonify({"status": "healthy"})

@app.route('/api/data')
def data():
    return jsonify({"message": "Protected API data"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

mkdir -p /data/configs/apps/db
cat > /data/configs/apps/db/init.sql <<'EOF'
CREATE DATABASE IF NOT EXISTS protected_db;
USE protected_db;
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL
);
INSERT INTO users (username, email) VALUES ('admin', 'admin@example.com');
EOF

mkdir -p /data/configs/apps/file
echo "Sample protected file" > /data/configs/apps/file/sample.txt

mkdir -p /data/configs/apps/ssh
cat > /data/configs/apps/ssh/sshd_config <<'EOF'
Port 22
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
EOF

mkdir -p /data/configs/apps/rdp
echo "RDP configuration placeholder" > /data/configs/apps/rdp/README.txt

log_success "Application configurations created"

log_info "Creating SR Linux startup configurations..."

cat > /data/labs/srl1.cfg <<'EOF'
set / system information location "Leaf Switch 1"
set / interface ethernet-1/1 admin-state enable
set / interface ethernet-1/2 admin-state enable
set / network-instance default type default
set / network-instance default interface ethernet-1/1.0
set / network-instance default interface ethernet-1/2.0
set / network-instance default protocols bgp admin-state enable
set / network-instance default protocols bgp router-id 10.0.1.1
set / network-instance default protocols bgp autonomous-system 65001
set / network-instance default protocols bgp group ebgp peer-as 65000
set / network-instance default protocols bgp group ebgp ipv4-unicast admin-state enable
set / network-instance default protocols bgp neighbor 10.0.1.2 peer-group ebgp
EOF

cat > /data/labs/srl2.cfg <<'EOF'
set / system information location "Leaf Switch 2"
set / interface ethernet-1/1 admin-state enable
set / interface ethernet-1/2 admin-state enable
set / network-instance default type default
set / network-instance default interface ethernet-1/1.0
set / network-instance default interface ethernet-1/2.0
set / network-instance default protocols bgp admin-state enable
set / network-instance default protocols bgp router-id 10.0.2.1
set / network-instance default protocols bgp autonomous-system 65002
set / network-instance default protocols bgp group ebgp peer-as 65000
set / network-instance default protocols bgp group ebgp ipv4-unicast admin-state enable
set / network-instance default protocols bgp neighbor 10.0.2.2 peer-group ebgp
EOF

cat > /data/labs/srl-spine.cfg <<'EOF'
set / system information location "Spine Switch"
set / interface ethernet-1/1 admin-state enable
set / interface ethernet-1/2 admin-state enable
set / interface ethernet-1/3 admin-state enable
set / network-instance default type default
set / network-instance default interface ethernet-1/1.0
set / network-instance default interface ethernet-1/2.0
set / network-instance default interface ethernet-1/3.0
set / network-instance default protocols bgp admin-state enable
set / network-instance default protocols bgp router-id 10.0.0.1
set / network-instance default protocols bgp autonomous-system 65000
set / network-instance default protocols bgp group ebgp ipv4-unicast admin-state enable
EOF

log_success "SR Linux startup configurations created"

# Set proper permissions
chown -R labnox:labnox /data/configs /data/labs
chmod -R 755 /data/configs /data/labs

echo ""
log_success "All lab configuration files created successfully!"
log_info "Configuration directories:"
echo "  /data/configs/ca - CA certificates"
echo "  /data/configs/apps - Application configs"
echo "  /data/configs/frr - FRR router configs"
echo "  /data/configs/prometheus - Prometheus config"
echo "  /data/labs - Lab topology files and configs"

exit 0
