# Deployment Fixes Summary

## Overview

This document summarizes all the fixes applied to address the deployment errors you reported. The changes transform the deployment from a "deploy all labs simultaneously" approach to a comprehensive, resource-efficient solution with GUI access and authentication testing tools.

## Problems Identified

### 1. Resource Exhaustion
**Problem**: Deploying all labs simultaneously caused memory and CPU exhaustion on the VM.

**Solution**: Created `deploy-labs-sequential.sh` script that:
- Deploys labs one at a time
- Verifies each lab works
- Destroys the lab before moving to the next
- Provides detailed success/failure reporting
- Skips labs requiring vendor images (VRNetlab/cEOS)

### 2. Missing Configuration Files
**Problem**: Multiple labs failed with "failed to verify bind path" errors:
- `/data/configs/ca` - CA certificates
- `/data/configs/apps/webapp` - Web application configs
- `/data/labs/prometheus.yml` - Prometheus configuration
- `/data/labs/frr-router-1-config` - FRR router configs

**Solution**: Created `create-lab-configs.sh` script that generates:
- **CA Certificates**: Self-signed CA, server cert, client cert for RADIUS/TLS
- **FRR Router Configs**: Pre-configured daemons and frr.conf files
- **Prometheus Config**: Monitoring configuration
- **Application Configs**: Web app, API, database, file server configs
- **SR Linux Startup Configs**: Pre-configured switch configs with BGP

### 3. apt-get Syntax Errors
**Problem**: Commands like `apt-get update && apt-get install -y wpasupplicant` failed with "E: The update command takes no arguments"

**Solution**: Split commands into separate exec lines:
```yaml
exec:
  - apt-get update
  - apt-get install -y wpasupplicant iproute2
```

Fixed in files:
- `nokia-srlinux-lab.clab.yml` (3 client nodes)
- `portnox-tacacs-plus.clab.yml` (2 nodes)

### 4. BGP Configuration Errors
**Problem**: SR Linux BGP configurations failed with:
- "One of the address families must be enabled"
- "Mandatory field 'peer-group' is not present"

**Solution**: Added proper BGP configuration with peer-groups and address families:
```yaml
set / network-instance default protocols bgp group ebgp peer-as 65000
set / network-instance default protocols bgp group ebgp ipv4-unicast admin-state enable
set / network-instance default protocols bgp neighbor 10.5.1.1 peer-group ebgp
```

Fixed in files:
- `nokia-srlinux-lab.clab.yml` (4 SR Linux nodes)
- `quickstart-lab.clab.yml` (3 SR Linux nodes)

### 5. Unsupported SR Linux Features
**Problem**: SR Linux doesn't support `dot1x` or `tacacs` configuration commands, causing parsing errors.

**Solution**: Removed unsupported configuration lines:
- Removed `set / system dot1x` commands
- Removed `set / system aaa authentication tacacs` commands
- Removed `set / system aaa authentication radius` commands

These features don't exist in SR Linux - authentication must be configured differently.

### 6. Wrong Node Kind
**Problem**: `portnox-tacacs-plus.clab.yml` used `kind: vr-ftdv` which doesn't exist.

**Solution**: Changed to `kind: cisco_ftdv` (the correct ContainerLab kind for Cisco FTD)

### 7. VRNetlab Images Not Available
**Problem**: Many labs tried to pull VRNetlab images that don't exist in Docker Hub:
- `vrnetlab/vr-xrv9k`
- `vrnetlab/vr-fortios`
- `vrnetlab/vr-pan`
- `vrnetlab/vr-vmx`
- `ceos:latest`

**Solution**: Sequential deployment script automatically skips labs requiring vendor images and provides clear messaging about which labs need manual image import.

## New Features Added

### 1. GUI Environment (XFCE + XRDP)
**What**: Full desktop environment accessible via RDP

**Access**: 
```bash
# RDP to: <vm-ip>:3389
# Username: azureuser
# Password: Set with: sudo passwd azureuser
```

**Includes**:
- XFCE desktop environment
- Firefox and Chromium browsers
- Remote Desktop Protocol (XRDP) server

### 2. Antimony GUI (ContainerLab Web UI)
**What**: Web-based GUI for managing ContainerLab topologies

**Access**: `http://<vm-ip>:8080`

**Features**:
- Visual topology management
- Container control (start/stop/restart)
- Log viewing
- Topology editor

### 3. EdgeShark (Network Analysis)
**What**: Wireshark-like tool for analyzing container network traffic

**Access**: `http://<vm-ip>:5001`

**Features**:
- Packet capture from containers
- Real-time traffic analysis
- Protocol dissection

### 4. 802.1X/RADIUS Automation Tools

#### wpa_supplicant Configuration Templates
Location: `/data/configs/wpa_supplicant/`

**EAP-TLS** (`eap-tls.conf`):
```bash
network={
    ssid="Enterprise-Network"
    key_mgmt=WPA-EAP
    eap=TLS
    identity="user@example.com"
    ca_cert="/data/configs/ca/ca.crt"
    client_cert="/data/configs/ca/client.crt"
    private_key="/data/configs/ca/client.key"
}
```

**EAP-PEAP** (`eap-peap.conf`):
```bash
network={
    ssid="Enterprise-Network"
    key_mgmt=WPA-EAP
    eap=PEAP
    identity="user@example.com"
    password="password"
    ca_cert="/data/configs/ca/ca.crt"
    phase2="auth=MSCHAPV2"
}
```

**EAP-TTLS** (`eap-ttls.conf`):
```bash
network={
    ssid="Enterprise-Network"
    key_mgmt=WPA-EAP
    eap=TTLS
    identity="user@example.com"
    password="password"
    ca_cert="/data/configs/ca/ca.crt"
    phase2="auth=PAP"
}
```

**Wired 802.1X** (`wired-8021x.conf`):
```bash
ap_scan=0
network={
    key_mgmt=IEEE8021X
    eap=PEAP
    identity="user@example.com"
    password="password"
    ca_cert="/data/configs/ca/ca.crt"
    phase2="auth=MSCHAPV2"
}
```

#### Test Scripts

**test-8021x** - Test 802.1X authentication:
```bash
test-8021x eth1 /data/configs/wpa_supplicant/eap-peap.conf
```

**test-radius** - Test RADIUS authentication:
```bash
test-radius user@example.com password 172.20.20.50 testing123
```

**install-portnox-agent** - Install Portnox Agent (headless):
```bash
sudo install-portnox-agent
# Follow prompts for Portnox Cloud URL and enrollment token
```

## Deployment Workflow Changes

### Before
```yaml
- Deploy all labs simultaneously
- Labs stay running (resource exhaustion)
- No GUI access
- No authentication testing tools
```

### After
```yaml
- Create all configuration files first
- Install GUI and tools
- Deploy labs sequentially (one at a time)
- Verify each lab works
- Destroy lab before next one
- Provide comprehensive access information
```

## Updated Deployment Summary

After deployment completes, you'll receive:

### Access Information
- **SSH**: `ssh -i azure_key azureuser@<vm-hostname>`
- **Antimony GUI**: `http://<vm-ip>:8080`
- **EdgeShark**: `http://<vm-ip>:5001`
- **RDP**: `<vm-ip>:3389` (username: azureuser)

### Installed Tools
- `test-8021x` - Test 802.1X authentication
- `test-radius` - Test RADIUS authentication
- `install-portnox-agent` - Install Portnox Agent

### Configuration Files
- `/data/configs/wpa_supplicant/` - 802.1X templates
- `/data/configs/ca/` - CA certificates
- `/data/configs/apps/` - Application configs
- `/data/labs/` - Lab topology files

## How to Use After Deployment

### 1. Access the VM
```bash
# SSH access
ssh -i azure_key azureuser@<vm-hostname>

# Or use RDP client to connect to <vm-ip>:3389
```

### 2. Deploy a Lab
```bash
# Deploy quickstart lab (no vendor images required)
sudo containerlab deploy -t /data/labs/quickstart-lab.clab.yml

# Check status
sudo containerlab inspect -t /data/labs/quickstart-lab.clab.yml
```

### 3. Access Antimony GUI
Open browser to `http://<vm-ip>:8080` to manage labs visually.

### 4. Test 802.1X Authentication
```bash
# From a client container
sudo containerlab exec -t /data/labs/nokia-srlinux-lab.clab.yml client-1 bash

# Inside container
test-8021x eth1 /data/configs/wpa_supplicant/eap-peap.conf
```

### 5. Test RADIUS Authentication
```bash
test-radius testuser password 172.20.20.101 testing123
```

### 6. Destroy a Lab
```bash
sudo containerlab destroy -t /data/labs/quickstart-lab.clab.yml --cleanup
```

## Files Modified

### Lab Topology Files
- `nokia-srlinux-lab.clab.yml` - Fixed BGP configs, removed unsupported features, fixed apt-get
- `quickstart-lab.clab.yml` - Fixed BGP configs
- `portnox-tacacs-plus.clab.yml` - Fixed node kind, fixed apt-get

### Workflow
- `.github/workflows/deploy-azure-containerlab.yml` - Added config creation, GUI setup, sequential deployment

### New Scripts
- `azure-deployment/scripts/deploy-labs-sequential.sh` - Sequential deployment
- `azure-deployment/scripts/create-lab-configs.sh` - Create all config files
- `azure-deployment/scripts/setup-gui-and-tools.sh` - Install GUI and tools

## Testing Recommendations

1. **Trigger deployment workflow** with default settings
2. **Wait for completion** and check for errors
3. **SSH to VM** and verify directory structure
4. **Deploy quickstart lab** manually to test
5. **Access GUIs** (Antimony, EdgeShark, RDP)
6. **Test authentication tools**
7. **Clean up** when done

## Known Limitations

1. **VRNetlab images**: Labs requiring vendor images (Cisco, Arista, Juniper, etc.) are skipped during sequential deployment. You must manually import these images if needed.

2. **Placeholder values**: Configuration files contain example values (passwords, domains) that should be updated for production use.

3. **Resource constraints**: D4s_v3 VM (4 vCPUs, 16GB RAM) can only run 1-2 complex labs simultaneously. Use sequential deployment or upgrade VM size.

4. **External dependencies**: Antimony and EdgeShark are cloned from external GitHub repos - deployment may fail if repos are unavailable.

## Troubleshooting

### Lab deployment fails
```bash
# Check logs
sudo containerlab deploy -t /data/labs/<lab>.clab.yml --debug

# Check Docker status
sudo systemctl status docker

# Check available resources
free -h
df -h
```

### GUI not accessible
```bash
# Check Antimony service
sudo systemctl status antimony

# Check EdgeShark service
sudo systemctl status edgeshark

# Check XRDP service
sudo systemctl status xrdp

# Check firewall
sudo ufw status
```

### Authentication tests fail
```bash
# Verify config files exist
ls -la /data/configs/ca/
ls -la /data/configs/wpa_supplicant/

# Check RADIUS server is running
sudo containerlab inspect --all | grep radius

# Test network connectivity
ping 172.20.20.101
```

## Next Steps

1. **Merge PR #15** to apply all fixes
2. **Trigger deployment workflow** to test end-to-end
3. **Verify all features work** as documented
4. **Report any issues** for further fixes

## Questions?

If you encounter any issues or have questions about these fixes, please comment on PR #15 or reach out via the Devin session.
