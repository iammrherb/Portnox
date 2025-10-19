# Comprehensive ContainerLab Deployment Guide

## Table of Contents
1. [Overview](#overview)
2. [Default Credentials](#default-credentials)
3. [Supported Vendors](#supported-vendors)
4. [Lab Topologies](#lab-topologies)
5. [VRNetlab Setup](#vrnetlab-setup)
6. [Antimony GUI](#antimony-gui)
7. [ZTNA Gateway](#ztna-gateway)
8. [Troubleshooting](#troubleshooting)

## Overview

This deployment provides a comprehensive network lab environment with support for multiple vendors, authentication systems, and network topologies. All components are containerized and managed through ContainerLab.

### Key Features
- **Multi-vendor support**: Cisco, Arista, Juniper, Palo Alto, Fortinet, Nokia, Aruba, HP, Dell, Extreme
- **Authentication**: RADIUS, TACACS+, LDAP, SAML
- **ZTNA**: Zero Trust Network Access gateway
- **Monitoring**: Prometheus, Grafana
- **Web GUI**: Antimony for topology management

## Default Credentials

### RADIUS Server
- **Service**: FreeRADIUS
- **Port**: 1812/UDP (auth), 1813/UDP (acct)
- **Shared Secret**: `testing123`
- **Admin User**: N/A (configured via raddb)
- **Test Users**:
  - Username: `testuser` / Password: `testpass`
  - Username: `admin` / Password: `admin123`

### TACACS+ Server
- **Service**: TACACS+
- **Port**: 49/TCP
- **Shared Key**: `tacacskey123`
- **Users**:
  - Username: `admin` / Password: `admin` (privilege 15)
  - Username: `operator` / Password: `operator` (privilege 1)

### LDAP Server
- **Service**: OpenLDAP
- **Port**: 389/TCP (LDAP), 636/TCP (LDAPS)
- **Admin DN**: `cn=admin,dc=example,dc=com`
- **Admin Password**: `admin`
- **Base DN**: `dc=example,dc=com`

### Antimony GUI
- **URL**: `http://<vm-hostname>:8080`
- **Authentication**: None (open access)
- **Features**: Lab deployment, container management, topology visualization

### ZTNA Gateway
- **URL**: `https://<vm-hostname>:443`
- **Admin Port**: 8443/TCP
- **Default**: No authentication (demo mode)

### Network Devices

#### Nokia SR Linux
- **Username**: `admin`
- **Password**: `NokiaSrl1!`
- **SSH Port**: Varies by container
- **Management**: gNMI, JSON-RPC

#### Arista cEOS
- **Username**: `admin`
- **Password**: `admin`
- **Enable Password**: None required
- **SSH Port**: Varies by container

#### Cisco IOS-XR (VRNetlab)
- **Username**: `admin`
- **Password**: `admin`
- **Enable Password**: `admin`
- **SSH Port**: Varies by container

#### Juniper vMX/vQFX (VRNetlab)
- **Username**: `root`
- **Password**: `Juniper`
- **SSH Port**: Varies by container

#### Palo Alto (VRNetlab)
- **Username**: `admin`
- **Password**: `admin`
- **Web UI**: HTTPS on container port

#### Fortinet FortiGate (VRNetlab)
- **Username**: `admin`
- **Password**: `admin`
- **Web UI**: HTTPS on container port

#### FRRouting
- **Username**: `admin`
- **Password**: `admin`
- **VTY Password**: `admin`

## Supported Vendors

### Network Operating Systems

#### Nokia SR Linux
- **Kind**: `nokia_srlinux` or `srl`
- **Images**: 
  - `ghcr.io/nokia/srlinux:latest`
  - `ghcr.io/nokia/srlinux:23.10.1`
- **Documentation**: https://learn.srlinux.dev/
- **Use Cases**: Data center switching, routing, automation

#### Arista cEOS
- **Kind**: `arista_ceos` or `ceos`
- **Images**: 
  - `ceos:latest`
  - `ceos:4.30.0F`
- **Note**: Requires manual image import from Arista
- **Documentation**: https://www.arista.com/en/support/software-download
- **Use Cases**: Data center, campus, cloud networking

#### Cisco (VRNetlab)
- **Kinds**: 
  - `cisco_xrv9k` - IOS-XR virtual router
  - `cisco_xrv` - IOS-XRv
  - `cisco_csr1000v` - CSR 1000v
  - `cisco_n9kv` - Nexus 9000v
- **Images**: `vrnetlab/vr-*`
- **Documentation**: https://containerlab.dev/manual/vrnetlab/
- **Use Cases**: Enterprise routing, data center, service provider

#### Juniper (VRNetlab)
- **Kinds**:
  - `juniper_vmx` - vMX virtual router
  - `juniper_vqfx` - vQFX virtual switch
  - `juniper_vsrx` - vSRX virtual firewall
- **Images**: `vrnetlab/vr-vmx`, `vrnetlab/vr-vqfx`, `vrnetlab/vr-vsrx`
- **Documentation**: https://containerlab.dev/manual/kinds/vr-juniper/
- **Use Cases**: Enterprise, service provider, security

#### Palo Alto Networks (VRNetlab)
- **Kind**: `paloalto_panos`
- **Images**: `vrnetlab/vr-pan`
- **Documentation**: https://containerlab.dev/manual/kinds/vr-paloalto/
- **Use Cases**: Next-gen firewall, security

#### Fortinet (VRNetlab)
- **Kinds**:
  - `fortinet_fortigate` - FortiGate firewall
  - `fortinet_ftdv` - Firepower Threat Defense
- **Images**: `vrnetlab/vr-fortios`, `vrnetlab/vr-ftdv`
- **Use Cases**: Firewall, SD-WAN, security

#### Aruba (VRNetlab)
- **Kind**: `aruba_aoscx`
- **Images**: `vrnetlab/vr-aoscx`
- **Use Cases**: Campus switching, data center

#### HP/HPE (VRNetlab)
- **Kind**: `hp_comware`
- **Images**: `vrnetlab/vr-hp-comware`
- **Use Cases**: Campus, data center

#### Dell (VRNetlab)
- **Kind**: `dell_os10`
- **Images**: `vrnetlab/vr-dell-os10`
- **Use Cases**: Data center switching

#### Extreme Networks (VRNetlab)
- **Kind**: `extreme_exos`
- **Images**: `vrnetlab/vr-exos`
- **Use Cases**: Campus, data center

#### FRRouting
- **Kind**: `linux`
- **Images**: `frrouting/frr:latest`
- **Documentation**: https://frrouting.org/
- **Use Cases**: Open-source routing, BGP, OSPF, ISIS

### Authentication & Identity

#### Portnox RADIUS
- **Image**: `portnox/radius:latest`
- **Ports**: 1812/UDP, 1813/UDP
- **Features**: 802.1X, MAC auth, LDAP/AD integration

#### Portnox TACACS+
- **Image**: `portnox/tacacs:latest`
- **Port**: 49/TCP
- **Features**: Device administration, command authorization

#### FreeRADIUS
- **Image**: `freeradius/freeradius-server:latest`
- **Modules**: LDAP, Kerberos, PostgreSQL, MySQL, REST

#### OpenLDAP
- **Image**: `osixia/openldap:latest`
- **Use**: User directory, authentication backend

#### Keycloak
- **Image**: `quay.io/keycloak/keycloak:latest`
- **Use**: SSO, SAML, OpenID Connect

### ZTNA & Security

#### Portnox ZTNA Gateway
- **Image**: `portnox/ztna-gateway:latest`
- **Ports**: 443/TCP, 8443/TCP
- **Features**: Zero Trust access, identity-based policies

### Monitoring & Observability

#### Prometheus
- **Image**: `prom/prometheus:latest`
- **Port**: 9090/TCP
- **Use**: Metrics collection, alerting

#### Grafana
- **Image**: `grafana/grafana:latest`
- **Port**: 3000/TCP
- **Default Login**: admin/admin
- **Use**: Visualization, dashboards

## Lab Topologies

### Pre-configured Labs

#### 1. RADIUS 802.1X Lab
**File**: `portnox-radius-802.1x.clab.yml`

**Topology**:
- 1x RADIUS server (FreeRADIUS)
- 3x Network switches (Cisco, Arista, Juniper)
- 3x Test clients (EAP-TLS, PEAP, EAP-TTLS)
- 1x Active Directory server
- 1x LDAP server
- 1x Certificate Authority
- 1x Syslog server

**Use Cases**:
- 802.1X wired authentication
- 802.1X wireless authentication
- MAC authentication bypass
- Dynamic VLAN assignment
- CoA (Change of Authorization)

**Deploy**:
```bash
sudo containerlab deploy -t /data/labs/portnox-radius-802.1x.clab.yml
```

#### 2. TACACS+ Lab
**File**: `portnox-tacacs-plus.clab.yml`

**Topology**:
- 1x TACACS+ server
- 7x Network devices (Cisco, Arista, Juniper, Palo Alto, Fortinet, F5)
- 3x Identity providers (AD, LDAP, SAML)
- 1x Audit server
- 1x Jump host
- 1x Monitoring server

**Use Cases**:
- Device administration AAA
- Command authorization
- Privilege level management
- Audit logging
- Multi-vendor support

**Deploy**:
```bash
sudo containerlab deploy -t /data/labs/portnox-tacacs-plus.clab.yml
```

#### 3. ZTNA Deployment Lab
**File**: `portnox-ztna-deployment.clab.yml`

**Topology**:
- 1x ZTNA Gateway
- 1x ZTNA Controller
- 3x Identity providers (Azure AD, Okta, Google)
- 6x Protected applications
- 3x Security services (EDR, Posture, MFA)
- 3x User endpoints
- 1x Firewall
- 1x Load balancer
- Monitoring stack

**Use Cases**:
- Zero Trust access
- Identity-based policies
- Device posture checking
- MFA enforcement
- Application access control

**Deploy**:
```bash
sudo containerlab deploy -t /data/labs/portnox-ztna-deployment.clab.yml
```

### Creating Custom Labs

#### Basic Lab Structure
```yaml
name: my-lab
topology:
  nodes:
    router1:
      kind: nokia_srlinux
      image: ghcr.io/nokia/srlinux:latest
    
    router2:
      kind: arista_ceos
      image: ceos:latest
    
    radius:
      kind: linux
      image: portnox/radius:latest
      ports:
        - 1812:1812/udp
        - 1813:1813/udp
  
  links:
    - endpoints: ["router1:e1-1", "router2:eth1"]
```

#### Vendor-Specific Examples

**Cisco IOS-XR**:
```yaml
xr-router:
  kind: cisco_xrv9k
  image: vrnetlab/vr-xrv9k:latest
  mgmt-ipv4: 172.20.20.10
```

**Juniper vMX**:
```yaml
vmx-router:
  kind: juniper_vmx
  image: vrnetlab/vr-vmx:latest
  mgmt-ipv4: 172.20.20.11
```

**Palo Alto**:
```yaml
firewall:
  kind: paloalto_panos
  image: vrnetlab/vr-pan:latest
  mgmt-ipv4: 172.20.20.12
```

**Fortinet FortiGate**:
```yaml
fortigate:
  kind: fortinet_fortigate
  image: vrnetlab/vr-fortios:latest
  mgmt-ipv4: 172.20.20.13
```

## VRNetlab Setup

VRNetlab allows running vendor images as containers. Most commercial network OS images require manual import.

### Supported Vendors via VRNetlab
- Cisco: IOS-XR, IOS-XRv, CSR1000v, Nexus 9000v
- Juniper: vMX, vQFX, vSRX, vJunos Evolved
- Palo Alto: PAN-OS
- Fortinet: FortiOS, FortiGate
- Aruba: AOS-CX
- HP/HPE: Comware
- Dell: OS10
- Extreme: EXOS

### Building VRNetlab Images

1. **Download vendor image** (requires account with vendor)
2. **Place in VRNetlab directory**:
```bash
mkdir -p /data/vrnetlab/cisco-xrv9k
cp iosxrv-k9-demo.qcow2 /data/vrnetlab/cisco-xrv9k/
```

3. **Build container image**:
```bash
cd /opt/vrnetlab/xrv9k
make docker-image
```

4. **Verify image**:
```bash
docker images | grep vrnetlab
```

### VRNetlab Directory Structure
```
/data/vrnetlab/
├── cisco-xrv9k/
│   └── iosxrv-k9-demo.qcow2
├── juniper-vmx/
│   └── vmx-bundle.tgz
├── paloalto/
│   └── PA-VM-KVM.qcow2
└── fortinet/
    └── fortios.qcow2
```

## Antimony GUI

Antimony provides a web-based interface for managing ContainerLab topologies.

### Access
- **URL**: `http://<vm-hostname>:8080`
- **No authentication required** (demo mode)

### Features
- **Lab Management**: Deploy, destroy, inspect labs
- **Container Control**: Start, stop, restart containers
- **Log Viewing**: Real-time container logs
- **Topology Editor**: Visual topology creation
- **File Management**: Upload/download lab files

### API Endpoints
- `GET /api/labs` - List all labs
- `POST /api/labs/deploy` - Deploy a lab
- `DELETE /api/labs/:name` - Destroy a lab
- `GET /api/containers` - List containers
- `GET /api/containers/:id/logs` - Get container logs
- `POST /api/containers/:id/exec` - Execute command in container

### Example API Usage
```bash
curl http://<vm-hostname>:8080/api/labs

curl -X POST http://<vm-hostname>:8080/api/labs/deploy \
  -H "Content-Type: application/json" \
  -d '{"file": "/data/labs/portnox-radius-802.1x.clab.yml"}'
```

## ZTNA Gateway

The ZTNA Gateway provides Zero Trust Network Access capabilities.

### Architecture
- **Gateway**: Entry point for user connections
- **Controller**: Policy enforcement and management
- **Identity Providers**: Azure AD, Okta, Google Workspace
- **Protected Apps**: Backend applications
- **Endpoints**: User devices with posture checking

### Configuration

#### Gateway Config
```yaml
ztna-gateway:
  kind: linux
  image: portnox/ztna-gateway:latest
  ports:
    - 443:443/tcp
    - 8443:8443/tcp
  env:
    GATEWAY_MODE: "production"
    IDP_URL: "https://idp.example.com"
    POLICY_SERVER: "http://controller:8080"
```

#### Protected Application
```yaml
protected-app:
  kind: linux
  image: nginx:alpine
  labels:
    ztna.protected: "true"
    ztna.policy: "require-mfa"
```

### Access Policies
- **Identity-based**: User/group membership
- **Device posture**: OS version, encryption, EDR
- **Context-aware**: Location, time, risk score
- **MFA enforcement**: Required for sensitive apps

## Troubleshooting

### Common Issues

#### 1. Container Won't Start
```bash
docker logs <container-name>
sudo containerlab inspect --all
```

#### 2. Network Connectivity Issues
```bash
docker network ls
docker network inspect <network-name>
ip link show
```

#### 3. RADIUS Not Authenticating
```bash
docker logs radius-server
radiusd -X  # Debug mode
```

#### 4. TACACS+ Connection Failed
```bash
docker logs tacacs-server
telnet <tacacs-server> 49
```

#### 5. VRNetlab Image Won't Build
```bash
cd /opt/vrnetlab/<vendor>
make clean
make docker-image
```

### Useful Commands

#### ContainerLab
```bash
sudo containerlab deploy -t <lab-file>
sudo containerlab destroy -t <lab-file>
sudo containerlab inspect --all
sudo containerlab graph -t <lab-file>
```

#### Docker
```bash
docker ps
docker logs -f <container>
docker exec -it <container> bash
docker stats
docker system df
```

#### Networking
```bash
ip addr show
ip route show
iptables -L -n -v
tcpdump -i any port 1812
```

### Log Locations
- **ContainerLab**: `/var/log/containerlab/`
- **Docker**: `docker logs <container>`
- **RADIUS**: `/var/log/radius/radius.log`
- **TACACS+**: `/var/log/tac_plus.acct`
- **System**: `/var/log/syslog`

### Performance Tuning

#### Increase Container Resources
```yaml
nodes:
  router1:
    kind: cisco_xrv9k
    image: vrnetlab/vr-xrv9k:latest
    cpu: 4
    memory: 8GB
```

#### Optimize Docker
```bash
docker system prune -a
docker volume prune
```

## Additional Resources

### Documentation
- ContainerLab: https://containerlab.dev/
- VRNetlab: https://github.com/vrnetlab/vrnetlab
- Portnox: https://docs.portnox.com/
- SR Linux: https://learn.srlinux.dev/
- FRRouting: https://frrouting.org/

### Community
- ContainerLab Slack: https://containerlab.dev/community/
- GitHub Discussions: https://github.com/srl-labs/containerlab/discussions
- SR Labs: https://github.com/srl-labs

### Lab Examples
- Official Examples: https://github.com/srl-labs/containerlab/tree/main/lab-examples
- Community Labs: https://github.com/topics/clab-topo

## Support

For issues or questions:
1. Check this guide
2. Review ContainerLab documentation
3. Check GitHub issues
4. Contact Portnox support

---

**Version**: 1.0
**Last Updated**: 2025-10-18
**Maintained by**: Portnox ContainerLab Team
