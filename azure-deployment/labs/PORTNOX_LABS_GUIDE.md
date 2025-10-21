# Portnox ContainerLab Deployment Guide

This guide provides comprehensive instructions for deploying and configuring all Portnox lab topologies in ContainerLab.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Lab Templates](#lab-templates)
4. [Deployment Instructions](#deployment-instructions)
5. [Configuration Requirements](#configuration-requirements)
6. [Troubleshooting](#troubleshooting)
7. [Best Practices](#best-practices)

---

## Overview

This repository includes 10 comprehensive lab templates demonstrating Portnox integration with various network security scenarios:

| Lab Template | Description | Use Case |
|--------------|-------------|----------|
| `portnox-radius-basic-local.clab.yml` | Basic 802.1X with local RADIUS container | Testing RADIUS authentication locally |
| `portnox-radius-basic-cloud.clab.yml` | Basic 802.1X with Portnox Cloud RADIUS | Production RADIUS with cloud backend |
| `portnox-radius-multivendor.clab.yml` | Multi-vendor 802.1X deployment | Testing across Cisco, Arista, Juniper, HPE, PA, Fortinet |
| `portnox-ztna-basic.clab.yml` | ZTNA Gateway with 6 protected apps | Zero Trust Network Access deployment |
| `portnox-ztna-multi-idp.clab.yml` | ZTNA with multiple IDPs | Azure AD, Okta, Google, OneLogin integration |
| `portnox-tacacs-basic.clab.yml` | TACACS+ device administration | Network device authentication & authorization |
| `portnox-siem-elk.clab.yml` | SIEM integration with ELK Stack | Log forwarding to Elasticsearch/Kibana |
| `portnox-siem-splunk.clab.yml` | SIEM integration with Splunk | Log forwarding to Splunk Enterprise |
| `portnox-security-monitoring.clab.yml` | Comprehensive security monitoring | Kali, Parrot, Security Onion, Wazuh, AlienVault |
| `portnox-radius-802.1x.clab.yml` | Advanced 802.1X with AD/LDAP | Production-ready RADIUS deployment |

---

## Prerequisites

### System Requirements

- **VM Size**: Minimum Standard_D4s_v3 (4 vCPUs, 16GB RAM)
  - Recommended: Standard_D8s_v3 (8 vCPUs, 32GB RAM) for multiple labs
  - For security monitoring lab: Standard_D16s_v3 (16 vCPUs, 64GB RAM)
- **Storage**: 512GB data disk (minimum)
- **OS**: Ubuntu 22.04 LTS
- **Docker**: Latest version
- **ContainerLab**: Latest version (installed automatically)

### Portnox Cloud Requirements

All labs require a Portnox Cloud account and the following credentials:

1. **Portnox Cloud URL**: Your organization's Portnox Cloud URL
   - Format: `https://yourorg.portnox.cloud`
   - Get from: Portnox Cloud Console > Settings > Organization

2. **Gateway Tokens**: Different tokens for different services
   - **RADIUS Gateway Token**: For RADIUS labs
   - **TACACS+ Gateway Token**: For TACACS+ labs
   - **ZTNA Gateway Token**: For ZTNA labs
   - **SIEM Gateway Token**: For SIEM integration labs
   - Get from: Portnox Cloud Console > Settings > Gateways > Create Gateway

3. **Organization ID**: Your Portnox organization ID
   - Get from: Portnox Cloud Console > Settings > Organization

4. **Shared Secrets**:
   - **RADIUS Secret**: For RADIUS authentication (default: `testing123`)
   - **TACACS+ Secret**: For TACACS+ authentication (default: `testing123`)

### Network Device Images

Some labs require VRNetlab images for vendor network devices:

- **Cisco**: `ceos:latest` (Arista cEOS as Cisco substitute)
- **Arista**: `ceos:latest`
- **Juniper**: `vrnetlab/vr-vmx:latest`
- **Palo Alto**: `vrnetlab/vr-panos:latest`
- **Fortinet**: `vrnetlab/vr-fortios:latest`
- **HPE Aruba**: `arubanetworks/aoscx:latest`

See [VENDOR_IMAGE_REGISTRY.md](../VENDOR_IMAGE_REGISTRY.md) for image building instructions.

---

## Lab Templates

### 1. Basic RADIUS Lab (Local Container)

**File**: `portnox-radius-basic-local.clab.yml`

**Description**: Demonstrates basic 802.1X authentication using a local Portnox RADIUS container running in ContainerLab.

**Components**:
- 1x Portnox RADIUS container
- 1x Cisco switch with 802.1X
- 2x Linux clients (EAP-PEAP, EAP-TLS)

**Deployment**:
```bash
# Set environment variables
export PORTNOX_CLOUD_URL="https://yourorg.portnox.cloud"
export PORTNOX_GATEWAY_TOKEN="your-radius-gateway-token"
export PORTNOX_ORG_ID="your-org-id"
export RADIUS_SECRET="testing123"

# Deploy lab
sudo containerlab deploy -t /data/labs/portnox-radius-basic-local.clab.yml

# Verify deployment
sudo containerlab inspect -t /data/labs/portnox-radius-basic-local.clab.yml
```

**Access**:
- RADIUS Server: `172.20.20.10:1812` (UDP)
- Cisco Switch: `172.20.20.20` (SSH)
- Clients: `172.20.20.30`, `172.20.20.31`

**Testing**:
```bash
# SSH into client
docker exec -it clab-portnox-radius-basic-local-client-peap bash

# Test 802.1X authentication
wpa_supplicant -i eth1 -c /configs/eap-peap.conf -D wired -dd
```

---

### 2. Basic RADIUS Lab (Portnox Cloud)

**File**: `portnox-radius-basic-cloud.clab.yml`

**Description**: Demonstrates 802.1X authentication pointing to Portnox Cloud RADIUS servers.

**Components**:
- 2x Network switches (Cisco, Arista) configured for Portnox Cloud RADIUS
- 2x Linux clients (EAP-PEAP, EAP-TLS)

**Configuration Required**:

Before deploying, you MUST update the switch configurations with your Portnox Cloud RADIUS IP and ports:

1. Get your Portnox Cloud RADIUS IP:
   - Login to Portnox Cloud Console
   - Go to: Settings > RADIUS Gateways
   - Note the IP address, auth port, and accounting port

2. Edit the lab file:
```bash
nano /data/labs/portnox-radius-basic-cloud.clab.yml
```

3. Replace placeholders in switch configs:
```
# BEFORE:
radius server PORTNOX-CLOUD
 address ipv4 YOUR_PORTNOX_CLOUD_IP auth-port YOUR_AUTH_PORT acct-port YOUR_ACCT_PORT
 key YOUR_RADIUS_SECRET

# AFTER (example):
radius server PORTNOX-CLOUD
 address ipv4 203.0.113.50 auth-port 1812 acct-port 1813
 key MySecretKey123
```

**Deployment**:
```bash
# Deploy lab
sudo containerlab deploy -t /data/labs/portnox-radius-basic-cloud.clab.yml

# Verify deployment
sudo containerlab inspect -t /data/labs/portnox-radius-basic-cloud.clab.yml
```

---

### 3. Multi-Vendor RADIUS Lab

**File**: `portnox-radius-multivendor.clab.yml`

**Description**: Comprehensive 802.1X lab with 6 vendor platforms and 3 EAP methods.

**Components**:
- 1x Portnox RADIUS container
- 6x Network devices (Cisco, Arista, Juniper, HPE Aruba, Palo Alto, Fortinet)
- 3x Linux clients (EAP-TLS, EAP-PEAP, EAP-TTLS)

**Deployment**:
```bash
# Set environment variables
export PORTNOX_CLOUD_URL="https://yourorg.portnox.cloud"
export PORTNOX_GATEWAY_TOKEN="your-radius-gateway-token"
export PORTNOX_ORG_ID="your-org-id"
export RADIUS_SECRET="testing123"

# Deploy lab
sudo containerlab deploy -t /data/labs/portnox-radius-multivendor.clab.yml
```

**Testing Different EAP Methods**:

```bash
# Test EAP-TLS (certificate-based)
docker exec -it clab-portnox-radius-multivendor-client-eap-tls bash
wpa_supplicant -i eth1 -c /configs/eap-tls.conf -D wired -dd

# Test EAP-PEAP (username/password with TLS tunnel)
docker exec -it clab-portnox-radius-multivendor-client-eap-peap bash
wpa_supplicant -i eth1 -c /configs/eap-peap.conf -D wired -dd

# Test EAP-TTLS (username/password with TLS tunnel, PAP inner auth)
docker exec -it clab-portnox-radius-multivendor-client-eap-ttls bash
wpa_supplicant -i eth1 -c /configs/eap-ttls.conf -D wired -dd
```

---

### 4. Basic ZTNA Lab

**File**: `portnox-ztna-basic.clab.yml`

**Description**: Zero Trust Network Access deployment with 6 protected application types.

**Components**:
- 1x Portnox ZTNA Gateway
- 1x Portnox Auto-Update container
- 6x Protected applications (Web, API, Database, File Server, SSH, RDP)
- 1x Test client

**Deployment**:
```bash
# Set environment variables
export PORTNOX_CLOUD_URL="https://yourorg.portnox.cloud"
export PORTNOX_GATEWAY_TOKEN="your-ztna-gateway-token"
export PORTNOX_ORG_ID="your-org-id"

# Deploy lab
sudo containerlab deploy -t /data/labs/portnox-ztna-basic.clab.yml
```

**Access**:
- ZTNA Gateway: `https://172.20.20.10:443`
- Management API: `https://172.20.20.10:8443`
- Web App: `http://172.20.20.20:8080`
- API Server: `http://172.20.20.21:3000`
- Database: `172.20.20.22:5432`
- SSH Server: `172.20.20.24:2222`
- RDP Server: `172.20.20.25:3389`

**Testing ZTNA Access**:
```bash
# Test from client
docker exec -it clab-portnox-ztna-basic-test-client bash

# Test web app access through ZTNA gateway
curl -k https://172.20.20.10/app-web

# Test API access through ZTNA gateway
curl -k https://172.20.20.10/app-api
```

---

### 5. ZTNA Multi-IDP Lab

**File**: `portnox-ztna-multi-idp.clab.yml`

**Description**: ZTNA deployment with multiple Identity Providers (Azure AD, Okta, Google, OneLogin).

**Components**:
- 1x Portnox ZTNA Gateway
- 4x IDP simulators (Keycloak configured as Azure AD, Okta, Google, OneLogin)
- 4x Protected applications (one per IDP)
- 4x Test clients (one per IDP)

**Deployment**:
```bash
# Set environment variables
export PORTNOX_CLOUD_URL="https://yourorg.portnox.cloud"
export PORTNOX_GATEWAY_TOKEN="your-ztna-gateway-token"
export PORTNOX_ORG_ID="your-org-id"
export KEYCLOAK_PASSWORD="admin123"
export ENABLE_AZURE_AD="true"
export ENABLE_OKTA="true"
export ENABLE_GOOGLE="true"
export ENABLE_ONELOGIN="true"

# Deploy lab
sudo containerlab deploy -t /data/labs/portnox-ztna-multi-idp.clab.yml
```

**Access IDP Consoles**:
- Azure AD Simulator: `http://172.20.20.20:8081`
- Okta Simulator: `http://172.20.20.21:8082`
- Google Simulator: `http://172.20.20.22:8083`
- OneLogin Simulator: `http://172.20.20.23:8084`

**IDP Configuration**:

Each Keycloak instance needs to be configured:

1. Access Keycloak admin console (e.g., `http://172.20.20.20:8081`)
2. Login with: `admin` / `admin123`
3. Create realm for the IDP
4. Configure SAML/OIDC client for Portnox ZTNA Gateway
5. Create test users

---

### 6. TACACS+ Lab

**File**: `portnox-tacacs-basic.clab.yml`

**Description**: Device administration authentication and command authorization with TACACS+.

**Components**:
- 1x Portnox TACACS+ container
- 5x Network devices (Cisco, Arista, Juniper, Palo Alto, Fortinet)
- 1x Admin workstation

**Deployment**:
```bash
# Set environment variables
export PORTNOX_CLOUD_URL="https://yourorg.portnox.cloud"
export PORTNOX_GATEWAY_TOKEN="your-tacacs-gateway-token"
export PORTNOX_ORG_ID="your-org-id"
export TACACS_SECRET="testing123"

# Deploy lab
sudo containerlab deploy -t /data/labs/portnox-tacacs-basic.clab.yml
```

**Testing TACACS+ Authentication**:
```bash
# SSH into admin workstation
docker exec -it clab-portnox-tacacs-basic-admin-workstation bash

# SSH to Cisco router (will use TACACS+ auth)
ssh admin@172.20.20.20

# Try privileged commands (will use TACACS+ authorization)
enable
configure terminal
show running-config
```

**Command Authorization Levels**:
- Level 1: Basic show commands
- Level 15: Full configuration access

---

### 7. SIEM Integration Lab (ELK Stack)

**File**: `portnox-siem-elk.clab.yml`

**Description**: Log forwarding from Portnox to Elasticsearch, Logstash, and Kibana.

**Components**:
- 1x Portnox SIEM Forwarder
- 1x Elasticsearch
- 1x Logstash
- 1x Kibana
- 1x Portnox RADIUS server (generating logs)
- 1x Test switch
- 1x Test client

**Deployment**:
```bash
# Set environment variables
export PORTNOX_CLOUD_URL="https://yourorg.portnox.cloud"
export PORTNOX_GATEWAY_TOKEN="your-siem-gateway-token"
export PORTNOX_ORG_ID="your-org-id"
export ES_USERNAME="elastic"
export ES_PASSWORD="changeme"

# Deploy lab
sudo containerlab deploy -t /data/labs/portnox-siem-elk.clab.yml
```

**Access**:
- Kibana Dashboard: `http://172.20.20.22:5601`
- Elasticsearch: `http://172.20.20.20:9200`
- Logstash API: `http://172.20.20.21:9600`

**Viewing Logs in Kibana**:

1. Open Kibana: `http://172.20.20.22:5601`
2. Go to: Management > Stack Management > Index Patterns
3. Create index pattern: `portnox-logs-*`
4. Go to: Analytics > Discover
5. Select `portnox-logs-*` index pattern
6. View Portnox authentication logs

---

### 8. SIEM Integration Lab (Splunk)

**File**: `portnox-siem-splunk.clab.yml`

**Description**: Log forwarding from Portnox to Splunk Enterprise using HEC (HTTP Event Collector).

**Components**:
- 1x Portnox SIEM Forwarder
- 1x Splunk Enterprise
- 3x Portnox containers (RADIUS, TACACS+, ZTNA) generating logs
- 1x Test device
- 1x Test client

**Deployment**:
```bash
# Set environment variables
export PORTNOX_CLOUD_URL="https://yourorg.portnox.cloud"
export PORTNOX_GATEWAY_TOKEN="your-siem-gateway-token"
export PORTNOX_ORG_ID="your-org-id"
export SPLUNK_PASSWORD="changeme123"
export SPLUNK_HEC_TOKEN="your-hec-token"

# Deploy lab
sudo containerlab deploy -t /data/labs/portnox-siem-splunk.clab.yml
```

**Access**:
- Splunk Web: `http://172.20.20.20:8000`
- Login: `admin` / `changeme123`

**Configuring Splunk HEC**:

1. Login to Splunk Web
2. Go to: Settings > Data Inputs > HTTP Event Collector
3. Click "New Token"
4. Name: `Portnox`
5. Source type: `portnox:json`
6. Index: `portnox`
7. Copy the token and update `SPLUNK_HEC_TOKEN` environment variable

**Viewing Logs in Splunk**:

1. Go to: Search & Reporting
2. Search query: `index=portnox`
3. View Portnox authentication, authorization, and access logs

---

### 9. Security Monitoring Lab

**File**: `portnox-security-monitoring.clab.yml`

**Description**: Comprehensive security monitoring with Kali Linux, Parrot Security, Security Onion, Wazuh, AlienVault OSSIM, Snort, and Suricata.

**Components**:
- 1x Portnox RADIUS server
- 1x Portnox SIEM Forwarder
- 1x Kali Linux
- 1x Parrot Security OS
- 1x Security Onion
- 3x Wazuh (Manager, Indexer, Dashboard)
- 1x AlienVault OSSIM
- 1x Snort IDS
- 1x Suricata IDS/IPS
- 1x Test switch
- 1x Test client

**System Requirements**:
- **Minimum**: Standard_D16s_v3 (16 vCPUs, 64GB RAM)
- **Recommended**: Standard_D32s_v3 (32 vCPUs, 128GB RAM)
- **Storage**: 1TB data disk

**Deployment**:
```bash
# Set environment variables
export PORTNOX_CLOUD_URL="https://yourorg.portnox.cloud"
export PORTNOX_GATEWAY_TOKEN="your-gateway-token"
export PORTNOX_ORG_ID="your-org-id"
export WAZUH_PASSWORD="SecretPassword"
export OSSIM_PASSWORD="admin"

# Deploy lab (this will take 15-20 minutes)
sudo containerlab deploy -t /data/labs/portnox-security-monitoring.clab.yml
```

**Access**:
- Kali Linux VNC: `vnc://172.20.20.20:5900`
- Parrot Security VNC: `vnc://172.20.20.21:5900`
- Security Onion: `https://172.20.20.22`
- Wazuh Dashboard: `http://172.20.20.32:5601`
- AlienVault OSSIM: `https://172.20.20.40`

**Testing Security Monitoring**:

```bash
# Generate authentication events
docker exec -it clab-portnox-security-monitoring-test-client bash
wpa_supplicant -i eth1 -c /configs/eap-peap.conf -D wired -dd

# View in Wazuh Dashboard
# 1. Open http://172.20.20.32:5601
# 2. Login with: wazuh-wui / SecretPassword
# 3. Go to: Security Events
# 4. Filter: agent.name:portnox-radius

# View in Security Onion
# 1. Open https://172.20.20.22
# 2. Login with credentials from setup
# 3. Go to: Alerts
# 4. Filter for 802.1X authentication events
```

---

## Configuration Requirements

### Environment Variables

All labs require the following environment variables to be set before deployment:

```bash
# Portnox Cloud Configuration
export PORTNOX_CLOUD_URL="https://yourorg.portnox.cloud"
export PORTNOX_ORG_ID="your-org-id"

# Gateway Tokens (get from Portnox Cloud Console)
export PORTNOX_GATEWAY_TOKEN="your-radius-gateway-token"        # For RADIUS labs
export PORTNOX_TACACS_GATEWAY_TOKEN="your-tacacs-gateway-token" # For TACACS+ labs
export PORTNOX_ZTNA_GATEWAY_TOKEN="your-ztna-gateway-token"     # For ZTNA labs
export PORTNOX_SIEM_GATEWAY_TOKEN="your-siem-gateway-token"     # For SIEM labs

# Shared Secrets
export RADIUS_SECRET="testing123"
export TACACS_SECRET="testing123"

# Optional: SIEM Configuration
export ES_USERNAME="elastic"
export ES_PASSWORD="changeme"
export SPLUNK_PASSWORD="changeme123"
export SPLUNK_HEC_TOKEN="your-hec-token"
export WAZUH_PASSWORD="SecretPassword"
export OSSIM_PASSWORD="admin"
```

### Persistent Configuration

To make environment variables persistent across sessions:

```bash
# Add to ~/.bashrc
cat >> ~/.bashrc <<'EOF'
# Portnox ContainerLab Configuration
export PORTNOX_CLOUD_URL="https://yourorg.portnox.cloud"
export PORTNOX_ORG_ID="your-org-id"
export PORTNOX_GATEWAY_TOKEN="your-radius-gateway-token"
export RADIUS_SECRET="testing123"
export TACACS_SECRET="testing123"
EOF

# Reload
source ~/.bashrc
```

---

## Troubleshooting

### Common Issues

#### 1. Container Fails to Start

**Symptom**: Container exits immediately after deployment

**Solution**:
```bash
# Check container logs
docker logs clab-<lab-name>-<container-name>

# Check if image exists
docker images | grep portnox

# Pull image manually
docker pull portnox/portnox-radius:latest
```

#### 2. RADIUS Authentication Fails

**Symptom**: Client cannot authenticate via 802.1X

**Troubleshooting Steps**:

```bash
# 1. Verify RADIUS server is running
docker exec -it clab-<lab-name>-portnox-radius bash
netstat -ulnp | grep 1812

# 2. Check RADIUS logs
docker logs clab-<lab-name>-portnox-radius

# 3. Test RADIUS connectivity from switch
docker exec -it clab-<lab-name>-cisco-switch bash
ping 172.20.20.10

# 4. Verify shared secret matches
# Check switch config and RADIUS_SECRET environment variable

# 5. Test with radtest (if available)
radtest testuser testpass 172.20.20.10 1812 testing123
```

#### 3. TACACS+ Authorization Fails

**Symptom**: User can login but cannot execute commands

**Solution**:
```bash
# Check TACACS+ logs
docker logs clab-<lab-name>-portnox-tacacs

# Verify command authorization is configured on device
docker exec -it clab-<lab-name>-cisco-router bash
show running-config | include authorization

# Check Portnox Cloud policy
# Login to Portnox Cloud > Policies > TACACS+ > Command Authorization
```

#### 4. ZTNA Gateway Cannot Connect to Cloud

**Symptom**: ZTNA Gateway shows "disconnected" status

**Solution**:
```bash
# Check gateway logs
docker logs clab-<lab-name>-ztna-gateway

# Verify environment variables
docker exec -it clab-<lab-name>-ztna-gateway env | grep PORTNOX

# Test connectivity to Portnox Cloud
docker exec -it clab-<lab-name>-ztna-gateway bash
curl -k https://yourorg.portnox.cloud/health

# Verify gateway token is valid
# Login to Portnox Cloud > Settings > Gateways > Check token status
```

#### 5. SIEM Logs Not Appearing

**Symptom**: No logs in Kibana/Splunk

**Solution**:
```bash
# Check SIEM Forwarder logs
docker logs clab-<lab-name>-portnox-siem-forwarder

# Verify Elasticsearch is running
curl http://172.20.20.20:9200/_cluster/health

# Check if index exists
curl http://172.20.20.20:9200/_cat/indices | grep portnox

# Verify Splunk HEC is enabled
curl -k https://172.20.20.20:8088/services/collector/health
```

#### 6. VRNetlab Images Not Found

**Symptom**: Lab fails to deploy with "image not found" error

**Solution**:
```bash
# Check available images
docker images | grep vrnetlab

# Build VRNetlab images (see VENDOR_IMAGE_REGISTRY.md)
cd /data/vrnetlab
git clone https://github.com/vrnetlab/vrnetlab.git
cd vrnetlab/<vendor>
make

# Import image to ContainerLab
docker tag vrnetlab/vr-<vendor>:latest <vendor>:latest
```

---

## Best Practices

### 1. Resource Management

- **Start Small**: Deploy one lab at a time to understand resource requirements
- **Monitor Resources**: Use `htop` or `docker stats` to monitor CPU/memory usage
- **Clean Up**: Destroy labs when not in use to free resources

```bash
# Destroy a lab
sudo containerlab destroy -t /data/labs/<lab-file>.clab.yml

# Clean up unused Docker resources
docker system prune -a
```

### 2. Network Isolation

- Each lab uses its own management network (`172.20.20.0/24`)
- Labs are isolated from each other by default
- Use Docker networks for inter-lab communication if needed

### 3. Security

- **Change Default Passwords**: Update all default passwords in production
- **Use Strong Secrets**: Replace `testing123` with strong shared secrets
- **Limit Access**: Configure NSG rules to restrict access to lab VMs
- **Rotate Tokens**: Regularly rotate Portnox Gateway tokens

### 4. Backup and Recovery

```bash
# Backup lab configurations
tar -czf /data/backups/labs-$(date +%Y%m%d).tar.gz /data/labs/

# Backup container volumes
docker run --rm -v clab-data:/data -v /data/backups:/backup ubuntu tar czf /backup/clab-data-$(date +%Y%m%d).tar.gz /data

# Restore from backup
tar -xzf /data/backups/labs-20241018.tar.gz -C /data/
```

### 5. Performance Optimization

- **Use SSD Storage**: Ensure data disk is Premium SSD
- **Enable Accelerated Networking**: Already enabled in ARM template
- **Limit Concurrent Labs**: Run max 2-3 labs simultaneously on D8s_v3
- **Increase VM Size**: For security monitoring lab, use D16s_v3 or larger

### 6. Logging and Monitoring

```bash
# View all container logs
docker logs -f clab-<lab-name>-<container-name>

# Monitor lab status
sudo containerlab inspect -a

# Check Docker resource usage
docker stats

# View system resources
htop
```

---

## Lab Summary

| Lab | Containers | Min RAM | Min vCPUs | Deployment Time |
|-----|-----------|---------|-----------|-----------------|
| RADIUS Basic Local | 4 | 4GB | 2 | 2-3 min |
| RADIUS Basic Cloud | 4 | 4GB | 2 | 2-3 min |
| RADIUS Multi-Vendor | 10 | 8GB | 4 | 5-7 min |
| ZTNA Basic | 8 | 6GB | 4 | 3-5 min |
| ZTNA Multi-IDP | 13 | 12GB | 8 | 7-10 min |
| TACACS+ Basic | 7 | 6GB | 4 | 4-6 min |
| SIEM ELK | 6 | 8GB | 4 | 5-7 min |
| SIEM Splunk | 6 | 8GB | 4 | 5-7 min |
| Security Monitoring | 15 | 32GB | 16 | 15-20 min |

---

## Additional Resources

- **Portnox Documentation**: https://docs.portnox.com
- **ContainerLab Documentation**: https://containerlab.dev
- **VRNetlab Documentation**: https://github.com/vrnetlab/vrnetlab
- **Docker Documentation**: https://docs.docker.com

---

## Support

For issues or questions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review container logs: `docker logs <container-name>`
3. Check Portnox Cloud Console for gateway status
4. Contact Portnox Support: support@portnox.com

---

**Last Updated**: October 2024
**Version**: 1.0
