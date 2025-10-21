# Portnox ContainerLab Templates Guide

This guide provides comprehensive lab templates for testing Portnox solutions in various scenarios.

## 📋 Table of Contents

1. [802.1X RADIUS Labs](#8021x-radius-labs)
2. [ZTNA Gateway Labs](#ztna-gateway-labs)
3. [TACACS+ Labs](#tacacs-labs)
4. [SIEM Integration Labs](#siem-integration-labs)
5. [Security Monitoring Labs](#security-monitoring-labs)
6. [Configuration Requirements](#configuration-requirements)
7. [Deployment Instructions](#deployment-instructions)

---

## 802.1X RADIUS Labs

### Basic Local RADIUS Lab
**File**: `portnox-radius-basic-local.clab.yml`

**Purpose**: Test 802.1X authentication using a local Portnox RADIUS container.

**Components**:
- Portnox RADIUS container (local)
- Cisco switch (authenticator)
- Linux clients (supplicants)

**Use Cases**:
- Testing EAP-TLS, EAP-PEAP, EAP-TTLS
- Wired 802.1X authentication
- Basic RADIUS functionality

**Deploy**:
```bash
sudo containerlab deploy -t /data/labs/portnox-radius-basic-local.clab.yml
```

---

### Basic Cloud RADIUS Lab
**File**: `portnox-radius-basic-cloud.clab.yml`

**Purpose**: Test 802.1X authentication using Portnox Cloud RADIUS.

**Components**:
- Cisco and Arista switches (authenticators)
- Linux clients with different EAP methods
- **No local RADIUS container** - switches point directly to Portnox Cloud

**Configuration Required**:
1. Get your Portnox Cloud RADIUS IP and ports from: **Portnox Cloud Portal > Settings > RADIUS Gateways**
2. Update the lab file with:
   - `YOUR_PORTNOX_CLOUD_IP` - Your Portnox Cloud RADIUS IP
   - `YOUR_AUTH_PORT` - Authentication port (usually 1812)
   - `YOUR_ACCT_PORT` - Accounting port (usually 1813)
   - `YOUR_RADIUS_SECRET` - Your RADIUS shared secret

**Deploy**:
```bash
# Edit the file first to add your Portnox Cloud details
sudo containerlab deploy -t /data/labs/portnox-radius-basic-cloud.clab.yml
```

---

### Multi-Vendor RADIUS Lab
**File**: `portnox-radius-multivendor.clab.yml`

**Purpose**: Test 802.1X across multiple vendor switches and firewalls.

**Components**:
- Portnox RADIUS container
- Cisco Catalyst switch
- Arista EOS switch
- Juniper EX switch
- HPE Aruba CX switch
- Palo Alto firewall
- Fortinet FortiGate
- Multiple Linux clients with different EAP methods

**Use Cases**:
- Multi-vendor 802.1X testing
- Comparing authentication behavior across vendors
- Testing EAP method compatibility

**Deploy**:
```bash
sudo containerlab deploy -t /data/labs/portnox-radius-multivendor.clab.yml
```

---

## ZTNA Gateway Labs

### Basic ZTNA Lab
**File**: `portnox-ztna-basic.clab.yml`

**Purpose**: Test Portnox ZTNA Gateway with multiple protected applications.

**Components**:
- Portnox ZTNA Gateway container
- Portnox Auto-Update container
- Protected applications:
  - Web application (Nginx)
  - API application (Node.js)
  - Database (PostgreSQL)
  - File server (Samba)
  - SSH server
  - RDP server
- Client endpoint

**Use Cases**:
- Testing ZTNA access to different application types
- Zero Trust network access
- Application-level security

**Configuration Required**:
Set environment variables:
```bash
export PORTNOX_CLOUD_URL="https://yourorg.portnox.cloud"
export PORTNOX_GATEWAY_TOKEN="your-ztna-gateway-token"
export PORTNOX_ORG_ID="your-org-id"
```

**Deploy**:
```bash
sudo containerlab deploy -t /data/labs/portnox-ztna-basic.clab.yml
```

---

### Multi-IDP ZTNA Lab
**File**: `portnox-ztna-multi-idp.clab.yml`

**Purpose**: Test ZTNA with multiple identity providers.

**Components**:
- Portnox ZTNA Gateway
- Identity Providers (Keycloak simulators for):
  - Azure AD / Entra ID
  - Okta
  - Google Workspace
  - OneLogin
- Protected applications (CRM, ERP, HR, Finance)

**Use Cases**:
- Testing different IDP integrations
- SAML/OIDC authentication flows
- Multi-tenant ZTNA scenarios

**Deploy**:
```bash
sudo containerlab deploy -t /data/labs/portnox-ztna-multi-idp.clab.yml
```

**Access IDPs**:
- Azure AD: http://localhost:8080 (admin/admin)
- Okta: http://localhost:8081 (admin/admin)
- Google: http://localhost:8082 (admin/admin)
- OneLogin: http://localhost:8083 (admin/admin)

---

## TACACS+ Labs

### Basic TACACS+ Lab
**File**: `portnox-tacacs-basic.clab.yml`

**Purpose**: Test device administration with Portnox TACACS+.

**Components**:
- Portnox TACACS+ container
- Cisco router
- Arista switch
- Juniper router
- Palo Alto firewall
- Fortinet FortiGate
- Admin workstation

**Use Cases**:
- Device administration authentication
- Command authorization
- Accounting and audit logging
- Multi-vendor TACACS+ testing

**Configuration Required**:
```bash
export PORTNOX_CLOUD_URL="https://yourorg.portnox.cloud"
export PORTNOX_GATEWAY_TOKEN="your-tacacs-gateway-token"
export TACACS_SECRET="tacacskey123"
```

**Deploy**:
```bash
sudo containerlab deploy -t /data/labs/portnox-tacacs-basic.clab.yml
```

---

## SIEM Integration Labs

### ELK Stack Integration
**File**: `portnox-siem-elk.clab.yml`

**Purpose**: Forward Portnox logs to Elasticsearch/Logstash/Kibana.

**Components**:
- Portnox RADIUS container
- Portnox SIEM Forwarder (Elasticsearch mode)
- Elasticsearch
- Logstash
- Kibana
- Test switch and client

**Use Cases**:
- Centralized log management
- Security analytics
- Compliance reporting
- Real-time monitoring

**Deploy**:
```bash
sudo containerlab deploy -t /data/labs/portnox-siem-elk.clab.yml
```

**Access**:
- Kibana: http://localhost:5601
- Elasticsearch: http://localhost:9200

---

### Splunk Integration
**File**: `portnox-siem-splunk.clab.yml`

**Purpose**: Forward Portnox logs to Splunk.

**Components**:
- Portnox RADIUS container
- Portnox TACACS+ container
- Portnox SIEM Forwarder (Splunk mode)
- Splunk Enterprise
- Test devices

**Configuration Required**:
1. Get Splunk HEC token after deployment
2. Update `SPLUNK_HEC_TOKEN` environment variable

**Deploy**:
```bash
export SPLUNK_PASSWORD="Password123!"
sudo containerlab deploy -t /data/labs/portnox-siem-splunk.clab.yml
```

**Access**:
- Splunk Web: http://localhost:8000 (admin/Password123!)

---

## Security Monitoring Labs

### Comprehensive Security Monitoring Lab
**File**: `portnox-security-monitoring.clab.yml`

**Purpose**: Complete security monitoring and testing environment.

**Components**:
- **Portnox**:
  - RADIUS container
  - SIEM Forwarder
- **Penetration Testing**:
  - Kali Linux
  - Parrot Security OS
- **Network Security Monitoring**:
  - Security Onion
  - Snort IDS
  - Suricata IDS
- **SIEM/XDR**:
  - Wazuh Manager
  - Wazuh Indexer (OpenSearch)
  - Wazuh Dashboard
  - AlienVault OSSIM
- **Test Infrastructure**:
  - Network switch with SPAN port
  - Monitored client

**Use Cases**:
- Security testing and validation
- Threat detection
- Incident response
- Compliance monitoring
- Penetration testing
- Network traffic analysis

**Deploy**:
```bash
export WAZUH_PASSWORD="SecretPassword"
sudo containerlab deploy -t /data/labs/portnox-security-monitoring.clab.yml
```

**Access**:
- Kali Linux VNC: vnc://localhost:5900
- Parrot Security VNC: vnc://localhost:5901
- Security Onion: https://localhost:443
- Wazuh Dashboard: http://localhost:5601 (admin/SecretPassword)
- AlienVault OSSIM: https://localhost:8080

---

## Configuration Requirements

### Portnox Cloud Credentials

All labs require Portnox Cloud credentials. Get these from your Portnox Cloud portal:

1. **PORTNOX_CLOUD_URL**: Your organization's Portnox Cloud URL
   - Example: `https://yourorg.portnox.cloud`

2. **PORTNOX_GATEWAY_TOKEN**: Gateway registration token
   - Get from: **Portnox Cloud > Settings > Gateways > Add Gateway**

3. **PORTNOX_ORG_ID**: Your organization ID
   - Get from: **Portnox Cloud > Settings > Organization**

4. **RADIUS_SECRET**: Shared secret for RADIUS (if using local RADIUS)
   - Default: `testing123` (change for production)

5. **TACACS_SECRET**: Shared secret for TACACS+ (if using TACACS+)
   - Default: `tacacskey123` (change for production)

### Setting Environment Variables

**Option 1: Export in shell**
```bash
export PORTNOX_CLOUD_URL="https://yourorg.portnox.cloud"
export PORTNOX_GATEWAY_TOKEN="your-gateway-token"
export PORTNOX_ORG_ID="your-org-id"
export RADIUS_SECRET="testing123"
export TACACS_SECRET="tacacskey123"
```

**Option 2: Create .env file**
```bash
cat > /data/configs/.env <<EOF
PORTNOX_CLOUD_URL=https://yourorg.portnox.cloud
PORTNOX_GATEWAY_TOKEN=your-gateway-token
PORTNOX_ORG_ID=your-org-id
RADIUS_SECRET=testing123
TACACS_SECRET=tacacskey123
EOF

# Load environment variables
source /data/configs/.env
```

---

## Deployment Instructions

### Deploy a Lab

```bash
# Deploy a specific lab
sudo containerlab deploy -t /data/labs/<lab-name>.clab.yml

# Deploy with custom name
sudo containerlab deploy -t /data/labs/<lab-name>.clab.yml --name my-lab

# Deploy with reconfiguration
sudo containerlab deploy -t /data/labs/<lab-name>.clab.yml --reconfigure
```

### Inspect Running Labs

```bash
# List all running labs
sudo containerlab inspect --all

# Inspect specific lab
sudo containerlab inspect --name <lab-name>

# Get container details
docker ps
docker logs <container-name>
```

### Access Lab Components

```bash
# SSH into a container
docker exec -it <container-name> bash

# View container logs
docker logs -f <container-name>

# Access container shell
sudo containerlab exec --name <lab-name> --node <node-name> bash
```

### Destroy a Lab

```bash
# Destroy specific lab
sudo containerlab destroy -t /data/labs/<lab-name>.clab.yml

# Destroy all labs
sudo containerlab destroy --all

# Cleanup (remove all containers and networks)
sudo containerlab destroy --all --cleanup
```

---

## Troubleshooting

### Common Issues

**1. Container fails to start**
```bash
# Check container logs
docker logs <container-name>

# Check if image exists
docker images | grep <image-name>

# Pull image manually
docker pull <image-name>
```

**2. Network connectivity issues**
```bash
# Check container networks
docker network ls
docker network inspect <network-name>

# Test connectivity
docker exec <container-name> ping <target-ip>
```

**3. Portnox containers not connecting to cloud**
```bash
# Verify environment variables
docker exec <container-name> env | grep PORTNOX

# Check logs for connection errors
docker logs <container-name> | grep -i error

# Verify cloud URL is accessible
docker exec <container-name> curl -v https://yourorg.portnox.cloud
```

**4. VRNetlab images not available**
```bash
# VRNetlab images require manual import
# See: https://containerlab.dev/manual/vrnetlab/

# Build VRNetlab images
cd /data/vrnetlab
git clone https://github.com/vrnetlab/vrnetlab.git
cd vrnetlab/<vendor>
# Follow vendor-specific build instructions
```

---

## Best Practices

1. **Always use environment variables** for sensitive data (tokens, secrets)
2. **Test in isolated environments** before production
3. **Monitor resource usage** - some labs are resource-intensive
4. **Clean up after testing** - destroy labs when done
5. **Keep images updated** - pull latest Portnox container images regularly
6. **Document custom configurations** - save any modifications to lab files
7. **Use version control** - track changes to lab configurations

---

## Additional Resources

- **Portnox Documentation**: https://docs.portnox.com
- **ContainerLab Documentation**: https://containerlab.dev
- **Portnox Cloud Portal**: https://yourorg.portnox.cloud
- **Support**: support@portnox.com

---

## Lab Summary

| Lab Name | Purpose | Portnox Containers | Key Features |
|----------|---------|-------------------|--------------|
| portnox-radius-basic-local | Basic 802.1X testing | RADIUS | Local RADIUS, single switch |
| portnox-radius-basic-cloud | Cloud RADIUS testing | None (uses cloud) | Portnox Cloud RADIUS |
| portnox-radius-multivendor | Multi-vendor 802.1X | RADIUS | 6 vendors, 3 EAP methods |
| portnox-ztna-basic | ZTNA testing | ZTNA Gateway, Auto-Update | 6 app types |
| portnox-ztna-multi-idp | Multi-IDP ZTNA | ZTNA Gateway | 4 IDPs, 4 apps |
| portnox-tacacs-basic | TACACS+ testing | TACACS+ | 5 vendors, command auth |
| portnox-siem-elk | ELK integration | RADIUS, SIEM Forwarder | Elasticsearch, Kibana |
| portnox-siem-splunk | Splunk integration | RADIUS, TACACS+, SIEM Forwarder | Splunk Enterprise |
| portnox-security-monitoring | Security monitoring | RADIUS, SIEM Forwarder | Kali, Wazuh, Security Onion |

---

**Last Updated**: 2025-10-20
**Version**: 2.0.0
