# Comprehensive Vendor Image Registry

This document provides a complete reference for all network vendor container images, Docker registries, and image sources for ContainerLab deployments.

## Table of Contents

1. [Public Container Registries](#public-container-registries)
2. [Vendor-Specific Images](#vendor-specific-images)
3. [VRNetlab Images](#vrnetlab-images)
4. [EVE-NG Image Conversion](#eve-ng-image-conversion)
5. [Custom Portnox Images](#custom-portnox-images)
6. [Authentication & Identity](#authentication--identity)
7. [Monitoring & Observability](#monitoring--observability)
8. [Supporting Services](#supporting-services)

---

## Public Container Registries

### GitHub Container Registry (ghcr.io)
Primary registry for open-source network images.

```bash
# Nokia SR Linux
ghcr.io/nokia/srlinux:latest
ghcr.io/nokia/srlinux:23.10.1
ghcr.io/nokia/srlinux:23.7.1
ghcr.io/nokia/srlinux:22.11.2

# Antimony (ContainerLab GUI)
ghcr.io/antimony-team/antimony-backend:latest
ghcr.io/antimony-team/antimony-interface:latest

# Keycloak (Identity Provider)
ghcr.io/keycloak/keycloak:latest
```

### Docker Hub (docker.io)
Most common public registry.

```bash
# FRRouting
frrouting/frr:latest
frrouting/frr:9.0.1
frrouting/frr:8.5.2

# Utility Images
nicolaka/netshoot:latest
alpine:latest
ubuntu:22.04
ubuntu:20.04
debian:bullseye

# Web Servers
nginx:latest
nginx:alpine
httpd:latest

# Databases
postgres:15
postgres:14
mysql:8.0
redis:latest
redis:7-alpine

# Monitoring
prom/prometheus:latest
grafana/grafana:latest
prom/node-exporter:latest
prom/blackbox-exporter:latest
```

### Quay.io
Red Hat and community images.

```bash
# CoreDNS
quay.io/coreos/coredns:latest

# Etcd
quay.io/coreos/etcd:latest

# Calico
quay.io/calico/node:latest
quay.io/calico/cni:latest
```

---

## Vendor-Specific Images

### Nokia

**SR Linux** (Open Source, No License Required)
```bash
# Container Registry
ghcr.io/nokia/srlinux:latest
ghcr.io/nokia/srlinux:23.10.1
ghcr.io/nokia/srlinux:23.7.1
ghcr.io/nokia/srlinux:22.11.2

# Default Credentials
Username: admin
Password: NokiaSrl1!

# Documentation
https://learn.srlinux.dev/
https://github.com/nokia/srlinux-container-image
```

### Arista

**cEOS (Container EOS)** (Requires Account)
```bash
# Download Location
https://www.arista.com/en/support/software-download
Account Required: Yes (Arista Support Portal)

# Import Process
docker import cEOS64-lab-4.30.0F.tar.xz ceos:4.30.0F
docker tag ceos:4.30.0F ceos:latest

# Available Versions
ceos:4.30.0F
ceos:4.29.2F
ceos:4.28.3M

# Default Credentials
Username: admin
Password: admin

# Documentation
https://www.arista.com/en/support/software-download/eos-container
```

### Cisco

**IOS-XR, IOS-XE, NX-OS** (Requires VRNetlab + Vendor Images)
```bash
# Download Location
https://software.cisco.com/
Account Required: Yes (CCO Account)

# Supported Platforms via VRNetlab
- IOS-XRv 9000 (xrv9k)
- IOS-XRv (xrv)
- CSR 1000v (csr)
- Nexus 9000v (n9kv)
- Catalyst 8000v (cat8000v)

# Image Names After Build
vrnetlab/vr-xrv9k:latest
vrnetlab/vr-xrv:latest
vrnetlab/vr-csr:latest
vrnetlab/vr-n9kv:latest
vrnetlab/vr-cat8000v:latest

# Default Credentials (varies by platform)
Username: admin / cisco
Password: admin / cisco

# Documentation
https://www.cisco.com/c/en/us/support/index.html
```

### Juniper

**vMX, vQFX, vSRX** (Requires VRNetlab + Vendor Images)
```bash
# Download Location
https://support.juniper.net/support/downloads/
Account Required: Yes (JTAC Account)

# Supported Platforms via VRNetlab
- vMX (Virtual MX Router)
- vQFX (Virtual QFX Switch)
- vSRX (Virtual SRX Firewall)
- vJunos Evolved

# Image Names After Build
vrnetlab/vr-vmx:latest
vrnetlab/vr-vqfx:latest
vrnetlab/vr-vsrx:latest
vrnetlab/vr-vjunosevolved:latest

# Default Credentials
Username: root / admin
Password: Juniper / admin

# Documentation
https://www.juniper.net/documentation/
```

### Palo Alto Networks

**PAN-OS** (Requires VRNetlab + Vendor Images)
```bash
# Download Location
https://support.paloaltonetworks.com/
Account Required: Yes (Support Portal)

# Supported Platforms via VRNetlab
- PA-VM (Virtual Firewall)

# Image Names After Build
vrnetlab/vr-pan:latest

# Default Credentials
Username: admin
Password: admin

# License Required
Yes - Evaluation or full license

# Documentation
https://docs.paloaltonetworks.com/
```

### Fortinet

**FortiGate** (Requires VRNetlab + Vendor Images)
```bash
# Download Location
https://support.fortinet.com/
Account Required: Yes (Support Portal)

# Supported Platforms via VRNetlab
- FortiGate VM
- FortiOS

# Image Names After Build
vrnetlab/vr-fortios:latest
vrnetlab/vr-ftdv:latest

# Default Credentials
Username: admin
Password: (blank)

# License Required
Yes - Evaluation or full license

# Documentation
https://docs.fortinet.com/
```

### Aruba (HPE)

**ArubaOS-CX** (Requires VRNetlab + Vendor Images)
```bash
# Download Location
https://asp.arubanetworks.com/
Account Required: Yes (Aruba Support Portal)

# Supported Platforms via VRNetlab
- ArubaOS-CX Virtual Switch

# Image Names After Build
vrnetlab/vr-aoscx:latest

# Default Credentials
Username: admin
Password: admin

# Documentation
https://www.arubanetworks.com/techdocs/
```

### Dell

**Dell OS10** (Requires VRNetlab + Vendor Images)
```bash
# Download Location
https://www.dell.com/support/
Account Required: Yes (Dell Support)

# Supported Platforms via VRNetlab
- OS10 Virtual Switch

# Image Names After Build
vrnetlab/vr-dellos10:latest

# Default Credentials
Username: admin
Password: admin

# Documentation
https://www.dell.com/support/kbdoc/
```

### HP (Hewlett Packard Enterprise)

**Comware** (Requires VRNetlab + Vendor Images)
```bash
# Download Location
https://support.hpe.com/
Account Required: Yes (HPE Support)

# Supported Platforms via VRNetlab
- Comware Virtual Switch

# Image Names After Build
vrnetlab/vr-comware:latest

# Default Credentials
Username: admin
Password: admin

# Documentation
https://support.hpe.com/hpesc/public/home
```

### Extreme Networks

**EXOS** (Requires VRNetlab + Vendor Images)
```bash
# Download Location
https://extremeportal.force.com/
Account Required: Yes (Extreme Portal)

# Supported Platforms via VRNetlab
- EXOS Virtual Switch

# Image Names After Build
vrnetlab/vr-exos:latest

# Default Credentials
Username: admin
Password: (blank)

# Documentation
https://documentation.extremenetworks.com/
```

### Mikrotik

**RouterOS** (Requires VRNetlab + Vendor Images)
```bash
# Download Location
https://mikrotik.com/download
Account Required: No (Public Download)

# Supported Platforms via VRNetlab
- RouterOS CHR (Cloud Hosted Router)

# Image Names After Build
vrnetlab/vr-routeros:latest

# Default Credentials
Username: admin
Password: (blank)

# License Required
Yes - Free tier available

# Documentation
https://wiki.mikrotik.com/
```

### VyOS

**VyOS** (Open Source Router)
```bash
# Download Location
https://vyos.io/
Account Required: No (Rolling releases free)

# Supported Platforms via VRNetlab
- VyOS Router

# Image Names After Build
vrnetlab/vr-vyos:latest

# Default Credentials
Username: vyos
Password: vyos

# Documentation
https://docs.vyos.io/
```

---

## VRNetlab Images

VRNetlab converts vendor VM images (QCOW2, VMDK, OVA) into Docker containers.

### VRNetlab Repository
```bash
# Clone VRNetlab
git clone https://github.com/vrnetlab/vrnetlab.git
cd vrnetlab
```

### Supported Vendors

| Vendor | Platform | Image Format | Build Directory |
|--------|----------|--------------|-----------------|
| Cisco | IOS-XRv 9000 | QCOW2 | `xrv9k/` |
| Cisco | IOS-XRv | QCOW2 | `xrv/` |
| Cisco | CSR 1000v | QCOW2/OVA | `csr/` |
| Cisco | Nexus 9000v | QCOW2 | `n9kv/` |
| Cisco | Catalyst 8000v | QCOW2 | `cat8000v/` |
| Juniper | vMX | QCOW2 | `vmx/` |
| Juniper | vQFX | QCOW2 | `vqfx/` |
| Juniper | vSRX | QCOW2 | `vsrx/` |
| Juniper | vJunos Evolved | QCOW2 | `vjunosevolved/` |
| Arista | vEOS | VMDK | `veos/` |
| Palo Alto | PA-VM | QCOW2 | `pan/` |
| Fortinet | FortiGate | QCOW2 | `fortios/` |
| Fortinet | FortiGate (FTD) | QCOW2 | `ftdv/` |
| Aruba | AOS-CX | QCOW2 | `aoscx/` |
| Dell | OS10 | QCOW2 | `dellos10/` |
| HP | Comware | QCOW2 | `comware/` |
| Extreme | EXOS | QCOW2 | `exos/` |
| Mikrotik | RouterOS | QCOW2 | `routeros/` |
| VyOS | VyOS | QCOW2 | `vyos/` |

### Building VRNetlab Images

```bash
# Example: Build Cisco IOS-XRv 9000
cd vrnetlab/xrv9k
cp /path/to/iosxrv-k9-demo-7.3.2.qcow2 .
make docker-image

# Verify image was created
docker images | grep vrnetlab

# Tag for ContainerLab
docker tag vrnetlab/vr-xrv9k:7.3.2 vrnetlab/vr-xrv9k:latest
```

### VRNetlab Environment Variables

All VRNetlab containers support these environment variables:

```bash
# Connection Settings
CONNECTION_MODE=tc          # Traffic control mode (tc, macvtap, bridge)
VCPU=2                      # Number of vCPUs
RAM=4096                    # RAM in MB
DISK_SIZE=10G               # Disk size

# Boot Settings
BOOT_DELAY=0                # Delay before boot (seconds)
BOOT_TIMEOUT=600            # Boot timeout (seconds)

# Management
MGMT_INTERFACE=eth0         # Management interface name
MGMT_IP=                    # Static management IP (optional)

# Credentials (vendor-specific)
USERNAME=admin              # Default username
PASSWORD=admin              # Default password
```

---

## EVE-NG Image Conversion

EVE-NG uses QCOW2 images which can be converted to ContainerLab via VRNetlab.

### EVE-NG Image Locations

```bash
# On EVE-NG Server
/opt/unetlab/addons/qemu/

# Common EVE-NG Images
/opt/unetlab/addons/qemu/iosxrv9k-*
/opt/unetlab/addons/qemu/vios-*
/opt/unetlab/addons/qemu/vmx-*
/opt/unetlab/addons/qemu/vqfx-*
/opt/unetlab/addons/qemu/paloalto-*
/opt/unetlab/addons/qemu/fortinet-*
```

### Conversion Process

**Step 1: Export from EVE-NG**
```bash
# SSH to EVE-NG server
ssh root@eve-ng-server

# Copy image to local machine
scp /opt/unetlab/addons/qemu/iosxrv9k-7.3.2/virtioa.qcow2 user@local:/tmp/
```

**Step 2: Convert to VRNetlab**
```bash
# On local machine with VRNetlab
cd vrnetlab/xrv9k
cp /tmp/virtioa.qcow2 ./iosxrv-k9-demo-7.3.2.qcow2
make docker-image
```

**Step 3: Import to ContainerLab**
```bash
# Image is now available as
docker images | grep vrnetlab/vr-xrv9k
```

### Automated EVE-NG Conversion Script

```bash
#!/bin/bash
# convert-eve-ng-image.sh

EVE_SERVER="$1"
EVE_IMAGE_PATH="$2"
VENDOR="$3"
VERSION="$4"

if [ -z "$EVE_SERVER" ] || [ -z "$EVE_IMAGE_PATH" ] || [ -z "$VENDOR" ] || [ -z "$VERSION" ]; then
    echo "Usage: $0 <eve-server> <image-path> <vendor> <version>"
    echo "Example: $0 192.168.1.100 /opt/unetlab/addons/qemu/iosxrv9k-7.3.2/virtioa.qcow2 xrv9k 7.3.2"
    exit 1
fi

# Download from EVE-NG
echo "Downloading image from EVE-NG..."
scp root@$EVE_SERVER:$EVE_IMAGE_PATH /tmp/eve-image.qcow2

# Build with VRNetlab
echo "Building VRNetlab image..."
cd vrnetlab/$VENDOR
cp /tmp/eve-image.qcow2 .
make docker-image

# Cleanup
rm /tmp/eve-image.qcow2

echo "Image built successfully: vrnetlab/vr-$VENDOR:$VERSION"
```

---

## Official Portnox Containers

**IMPORTANT**: Use official Portnox containers from Docker Hub. Do NOT build custom containers.

### RADIUS Gateway

**Docker Hub**: https://hub.docker.com/r/portnox/portnox-radius  
**Documentation**: https://docs.portnox.com/topics/radius_local_docker

```bash
docker pull portnox/portnox-radius:latest
```

**Required Environment Variables:**
```bash
PORTNOX_ORG_ID=your-org-id                 # From Portnox Cloud
PORTNOX_PROFILE=your-profile-name          # Profile name in Portnox Cloud
PORTNOX_TOKEN=your-gateway-token           # Authentication token from Portnox Cloud
```

**Optional Environment Variables:**
```bash
PORTNOX_NAME=my-radius-gateway             # Custom gateway name
PORTNOX_LOG_LEVEL=info                     # Log level (debug, info, warn, error)
RADIUS_PORT=1812                           # RADIUS authentication port
RADIUS_ACCT_PORT=1813                      # RADIUS accounting port
```

**Deployment Example:**
```bash
docker run -d \
  --name portnox-radius \
  -p 1812:1812/udp \
  -p 1813:1813/udp \
  -e PORTNOX_ORG_ID=your-org-id \
  -e PORTNOX_PROFILE=your-profile \
  -e PORTNOX_TOKEN=your-token \
  portnox/portnox-radius:latest
```

### TACACS+ Gateway

**Docker Hub**: https://hub.docker.com/r/portnox/portnox-tacacs  
**Documentation**: https://docs.portnox.com/topics/tacacs_local_docker

```bash
docker pull portnox/portnox-tacacs:latest
```

**Required Environment Variables:**
```bash
PORTNOX_ORG_ID=your-org-id                 # From Portnox Cloud
PORTNOX_PROFILE=your-profile-name          # Profile name in Portnox Cloud
PORTNOX_TOKEN=your-gateway-token           # Authentication token from Portnox Cloud
```

**Optional Environment Variables:**
```bash
PORTNOX_NAME=my-tacacs-gateway             # Custom gateway name
PORTNOX_LOG_LEVEL=info                     # Log level (debug, info, warn, error)
TACACS_PORT=49                             # TACACS+ port
```

**Deployment Example:**
```bash
docker run -d \
  --name portnox-tacacs \
  -p 49:49/tcp \
  -e PORTNOX_ORG_ID=your-org-id \
  -e PORTNOX_PROFILE=your-profile \
  -e PORTNOX_TOKEN=your-token \
  portnox/portnox-tacacs:latest
```

### ZTNA Gateway

**Docker Hub**: https://hub.docker.com/r/portnox/ztna-gateway  
**Documentation**: https://docs.portnox.com/topics/ztna_hosted_linux

```bash
docker pull portnox/ztna-gateway:latest
```

**Required Environment Variables:**
```bash
ZTNA_GATEWAY_ORG_ID=your-org-id            # From Portnox Cloud
ZTNA_GATEWAY_TOKEN=your-gateway-token      # Authentication token from Portnox Cloud
```

**Optional Environment Variables:**
```bash
ZTNA_GATEWAY_NAME=my-ztna-gateway          # Custom gateway name
ZTNA_GATEWAY_LOG_LEVEL=info                # Log level (debug, info, warn, error)
ZTNA_GATEWAY_PORT=443                      # HTTPS port
ZTNA_GATEWAY_ADMIN_PORT=8443               # Admin port
```

**Deployment Example:**
```bash
docker run -d \
  --name portnox-ztna \
  -p 443:443/tcp \
  -p 8443:8443/tcp \
  -e ZTNA_GATEWAY_ORG_ID=your-org-id \
  -e ZTNA_GATEWAY_TOKEN=your-token \
  portnox/ztna-gateway:latest
```

### AutoUpdate

**Docker Hub**: https://hub.docker.com/r/portnox/portnox-autoupdate  
**Documentation**: https://docs.portnox.com/topics/docker_autoupdate

```bash
docker pull portnox/portnox-autoupdate:latest
```

**Required Environment Variables:**
```bash
PORTNOX_ORG_ID=your-org-id                 # From Portnox Cloud
PORTNOX_TOKEN=your-autoupdate-token        # Authentication token from Portnox Cloud
```

**Optional Environment Variables:**
```bash
UPDATE_CHECK_INTERVAL=3600                 # Check interval in seconds (default: 1 hour)
PORTNOX_LOG_LEVEL=info                     # Log level (debug, info, warn, error)
```

**Deployment Example:**
```bash
docker run -d \
  --name portnox-autoupdate \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e PORTNOX_ORG_ID=your-org-id \
  -e PORTNOX_TOKEN=your-token \
  portnox/portnox-autoupdate:latest
```

### DHCP Proxy

**Docker Hub**: https://hub.docker.com/r/portnox/portnox-dhcp  
**Documentation**: https://docs.portnox.com/topics/dhcp_proxy

```bash
docker pull portnox/portnox-dhcp:latest
```

**Required Environment Variables:**
```bash
PORTNOX_ORG_ID=your-org-id                 # From Portnox Cloud
PORTNOX_TOKEN=your-dhcp-token              # Authentication token from Portnox Cloud
DHCP_INTERFACE=eth0                        # Network interface to monitor
```

**Optional Environment Variables:**
```bash
PORTNOX_NAME=my-dhcp-proxy                 # Custom proxy name
PORTNOX_LOG_LEVEL=info                     # Log level (debug, info, warn, error)
DHCP_SERVER=172.16.0.1                     # DHCP server IP (optional)
DHCP_RELAY_MODE=false                      # Enable relay mode
```

**Deployment Example:**
```bash
docker run -d \
  --name portnox-dhcp \
  --network host \
  -e PORTNOX_ORG_ID=your-org-id \
  -e PORTNOX_TOKEN=your-token \
  -e DHCP_INTERFACE=eth0 \
  portnox/portnox-dhcp:latest
```

### SIEM Forwarder

**Docker Hub**: https://hub.docker.com/r/portnox/portnox-siem  
**Documentation**: https://docs.portnox.com/topics/siem_integration

```bash
docker pull portnox/portnox-siem:latest
```

**Required Environment Variables:**
```bash
PORTNOX_ORG_ID=your-org-id                 # From Portnox Cloud
PORTNOX_TOKEN=your-siem-token              # Authentication token from Portnox Cloud
SIEM_SERVER=siem.example.com               # SIEM server hostname/IP
SIEM_PORT=514                              # SIEM server port
```

**Optional Environment Variables:**
```bash
PORTNOX_NAME=my-siem-forwarder             # Custom forwarder name
PORTNOX_LOG_LEVEL=info                     # Log level (debug, info, warn, error)
SIEM_PROTOCOL=tcp                          # Protocol (tcp, udp, tls)
SIEM_FORMAT=cef                            # Log format (cef, json, syslog)
TLS_VERIFY=true                            # Verify TLS certificates
```

**Deployment Example:**
```bash
docker run -d \
  --name portnox-siem \
  -e PORTNOX_ORG_ID=your-org-id \
  -e PORTNOX_TOKEN=your-token \
  -e SIEM_SERVER=siem.example.com \
  -e SIEM_PORT=514 \
  -e SIEM_PROTOCOL=tcp \
  portnox/portnox-siem:latest
```

### Unifi Agent

**Docker Hub**: https://hub.docker.com/r/portnox/portnox-unifi-agent  
**Documentation**: https://docs.portnox.com/topics/unifi_integration

```bash
docker pull portnox/portnox-unifi-agent:latest
```

**Required Environment Variables:**
```bash
PORTNOX_ORG_ID=your-org-id                 # From Portnox Cloud
PORTNOX_TOKEN=your-unifi-token             # Authentication token from Portnox Cloud
UNIFI_CONTROLLER=unifi.example.com         # Unifi Controller hostname/IP
UNIFI_USERNAME=admin                       # Unifi admin username
UNIFI_PASSWORD=password                    # Unifi admin password
```

**Optional Environment Variables:**
```bash
PORTNOX_NAME=my-unifi-agent                # Custom agent name
PORTNOX_LOG_LEVEL=info                     # Log level (debug, info, warn, error)
UNIFI_PORT=8443                            # Unifi Controller port
UNIFI_SITE=default                         # Unifi site name
SYNC_INTERVAL=300                          # Sync interval in seconds
```

**Deployment Example:**
```bash
docker run -d \
  --name portnox-unifi \
  -e PORTNOX_ORG_ID=your-org-id \
  -e PORTNOX_TOKEN=your-token \
  -e UNIFI_CONTROLLER=unifi.example.com \
  -e UNIFI_USERNAME=admin \
  -e UNIFI_PASSWORD=password \
  portnox/portnox-unifi-agent:latest
```

### NXLog Forwarder

**Documentation**: https://docs.portnox.com/topics/integrate_nxlog#docker

For log forwarding to Portnox Cloud, configure NXLog with Docker integration.

**Environment Variables:**
```bash
NXLOG_SERVER=logs.portnox.com              # Portnox log server
NXLOG_PORT=6514                            # Syslog TLS port
NXLOG_ORG_ID=your-org-id                   # From Portnox Cloud
NXLOG_TOKEN=your-nxlog-token               # Authentication token
```

---

## Authentication & Identity

### FreeIPA (LDAP + Kerberos)

```bash
docker.io/freeipa/freeipa-server:latest
```

**Environment Variables:**
```bash
IPA_SERVER_HOSTNAME=ipa.example.com
IPA_SERVER_IP=192.168.1.100
DS_PASSWORD=directory-manager-password
ADMIN_PASSWORD=admin-password
IPA_REALM=EXAMPLE.COM
IPA_DOMAIN=example.com
```

### OpenLDAP

```bash
docker.io/osixia/openldap:latest
```

**Environment Variables:**
```bash
LDAP_ORGANISATION=Example Inc
LDAP_DOMAIN=example.com
LDAP_ADMIN_PASSWORD=admin
LDAP_CONFIG_PASSWORD=config
LDAP_READONLY_USER=true
LDAP_READONLY_USER_USERNAME=readonly
LDAP_READONLY_USER_PASSWORD=readonly
```

### Active Directory (Samba)

```bash
docker.io/nowsci/samba-domain:latest
```

**Environment Variables:**
```bash
DOMAIN=EXAMPLE
DOMAINPASS=YourPassword123!
DNSFORWARDER=8.8.8.8
HOSTIP=192.168.1.100
```

### Keycloak (OIDC/SAML)

```bash
ghcr.io/keycloak/keycloak:latest
```

**Environment Variables:**
```bash
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=admin
KC_DB=postgres
KC_DB_URL=jdbc:postgresql://postgres:5432/keycloak
KC_DB_USERNAME=keycloak
KC_DB_PASSWORD=password
KC_HOSTNAME=keycloak.example.com
KC_PROXY=edge
```

### Okta (External SaaS)

```bash
# No container - External service
# Integration via OIDC/SAML
```

**Configuration:**
```bash
OKTA_DOMAIN=example.okta.com
OKTA_CLIENT_ID=your-client-id
OKTA_CLIENT_SECRET=your-client-secret
OKTA_ISSUER=https://example.okta.com/oauth2/default
```

### Azure AD (External SaaS)

```bash
# No container - External service
# Integration via OIDC/SAML
```

**Configuration:**
```bash
AZURE_TENANT_ID=your-tenant-id
AZURE_CLIENT_ID=your-client-id
AZURE_CLIENT_SECRET=your-client-secret
AZURE_AUTHORITY=https://login.microsoftonline.com/your-tenant-id
```

---

## Monitoring & Observability

### Prometheus

```bash
docker.io/prom/prometheus:latest
```

**Environment Variables:**
```bash
PROMETHEUS_RETENTION_TIME=15d
PROMETHEUS_STORAGE_PATH=/prometheus
PROMETHEUS_CONFIG=/etc/prometheus/prometheus.yml
```

### Grafana

```bash
docker.io/grafana/grafana:latest
```

**Environment Variables:**
```bash
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=admin
GF_SERVER_ROOT_URL=https://grafana.example.com
GF_DATABASE_TYPE=postgres
GF_DATABASE_HOST=postgres:5432
GF_DATABASE_NAME=grafana
GF_DATABASE_USER=grafana
GF_DATABASE_PASSWORD=password
GF_AUTH_GENERIC_OAUTH_ENABLED=true
GF_AUTH_GENERIC_OAUTH_NAME=Keycloak
GF_AUTH_GENERIC_OAUTH_CLIENT_ID=grafana
GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET=secret
```

### Loki (Log Aggregation)

```bash
docker.io/grafana/loki:latest
```

**Environment Variables:**
```bash
LOKI_CONFIG=/etc/loki/local-config.yaml
LOKI_STORAGE_PATH=/loki
```

### Jaeger (Tracing)

```bash
docker.io/jaegertracing/all-in-one:latest
```

**Environment Variables:**
```bash
COLLECTOR_ZIPKIN_HOST_PORT=:9411
COLLECTOR_OTLP_ENABLED=true
```

---

## Supporting Services

### PostgreSQL

```bash
docker.io/postgres:15
```

**Environment Variables:**
```bash
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password
POSTGRES_DB=postgres
POSTGRES_INITDB_ARGS=--encoding=UTF8
PGDATA=/var/lib/postgresql/data
```

### MySQL

```bash
docker.io/mysql:8.0
```

**Environment Variables:**
```bash
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=mydb
MYSQL_USER=user
MYSQL_PASSWORD=password
```

### Redis

```bash
docker.io/redis:7-alpine
```

**Environment Variables:**
```bash
REDIS_PASSWORD=password
REDIS_MAXMEMORY=256mb
REDIS_MAXMEMORY_POLICY=allkeys-lru
```

### RabbitMQ

```bash
docker.io/rabbitmq:3-management
```

**Environment Variables:**
```bash
RABBITMQ_DEFAULT_USER=admin
RABBITMQ_DEFAULT_PASS=admin
RABBITMQ_DEFAULT_VHOST=/
```

### Elasticsearch

```bash
docker.io/elasticsearch:8.11.0
```

**Environment Variables:**
```bash
discovery.type=single-node
ELASTIC_PASSWORD=password
xpack.security.enabled=true
```

---

## Image Build & Import Scripts

### Build All Custom Images

```bash
sudo /data/scripts/build-custom-images.sh
```

### Import All Public Images

```bash
sudo /data/scripts/import-images-comprehensive.sh
```

### Import Specific Vendor

```bash
# Nokia SR Linux
docker pull ghcr.io/nokia/srlinux:latest

# FRRouting
docker pull frrouting/frr:latest

# Arista cEOS (after download)
docker import cEOS64-lab-4.30.0F.tar.xz ceos:4.30.0F
```

---

## Quick Reference

### Check Available Images

```bash
docker images
docker images | grep vrnetlab
docker images | grep portnox
docker images | grep nokia
```

### Pull Image from Registry

```bash
docker pull ghcr.io/nokia/srlinux:latest
docker pull frrouting/frr:latest
docker pull grafana/grafana:latest
```

### Build VRNetlab Image

```bash
cd vrnetlab/<vendor>
cp /path/to/vendor-image.qcow2 .
make docker-image
```

### Tag Image

```bash
docker tag ghcr.io/nokia/srlinux:latest srlinux:latest
docker tag vrnetlab/vr-xrv9k:7.3.2 vrnetlab/vr-xrv9k:latest
```

---

## Additional Resources

- **ContainerLab**: https://containerlab.dev/
- **VRNetlab**: https://github.com/vrnetlab/vrnetlab
- **Nokia SR Linux**: https://learn.srlinux.dev/
- **FRRouting**: https://frrouting.org/
- **Antimony GUI**: https://github.com/antimony-team/antimony
- **Docker Hub**: https://hub.docker.com/
- **GitHub Container Registry**: https://ghcr.io/

---

**Last Updated**: 2025-10-18
