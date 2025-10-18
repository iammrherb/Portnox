# Architecture Documentation

## Overview

This document describes the architecture of the Portnox ContainerLab Azure deployment solution.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitHub Actions                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │  Workflow    │→ │   Deploy     │→ │  Configure   │         │
│  │  Trigger     │  │Infrastructure│  │     VM       │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                        Azure Cloud                              │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    Resource Group                        │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐        │  │
│  │  │    VNet    │  │    NSG     │  │  Public IP │        │  │
│  │  └────────────┘  └────────────┘  └────────────┘        │  │
│  │                                                          │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │              Virtual Machine                     │  │  │
│  │  │  ┌────────────┐  ┌────────────┐                 │  │  │
│  │  │  │  OS Disk   │  │ Data Disk  │                 │  │  │
│  │  │  │  128 GB    │  │  512 GB    │                 │  │  │
│  │  │  └────────────┘  └────────────┘                 │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    VM Software Stack                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Ubuntu 22.04 LTS                                        │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐        │  │
│  │  │   Docker   │  │ContainerLab│  │  Antimony  │        │  │
│  │  └────────────┘  └────────────┘  └────────────┘        │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Lab Topologies                                          │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐        │  │
│  │  │   RADIUS   │  │  TACACS+   │  │    ZTNA    │        │  │
│  │  │   802.1X   │  │   Device   │  │   Zero     │        │  │
│  │  │    Auth    │  │   Admin    │  │   Trust    │        │  │
│  │  └────────────┘  └────────────┘  └────────────┘        │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. GitHub Actions Workflow

**File**: `.github/workflows/deploy-azure-containerlab.yml`

**Jobs**:
1. **deploy-infrastructure**: Creates Azure resources using ARM template
2. **configure-vm**: Installs and configures software on VM
3. **deploy-labs**: Deploys ContainerLab topologies
4. **import-images**: Imports container images
5. **setup-antimony**: Installs Antimony GUI
6. **deployment-summary**: Generates deployment report

**Triggers**:
- Manual workflow dispatch
- Configurable parameters (VM size, location, etc.)

### 2. Azure Infrastructure

#### Resource Group
- Contains all Azure resources
- Configurable name and location
- Supports multiple deployments

#### Virtual Network
- Address space: 10.0.0.0/16
- Subnet: 10.0.0.0/24
- Isolated management network

#### Network Security Group
**Inbound Rules**:
- SSH (22/tcp)
- HTTP (80/tcp)
- HTTPS (443/tcp)
- RADIUS (1812-1813/udp)
- TACACS+ (49/tcp)
- Antimony GUI (8080/tcp)
- ContainerLab API (8443/tcp)
- Lab Services (8000-9000/tcp)

#### Virtual Machine
**Specifications**:
- OS: Ubuntu 22.04 LTS
- Size: Configurable (default: Standard_D8s_v3)
- OS Disk: 128 GB Premium SSD
- Data Disk: 512 GB Premium SSD (configurable)
- Accelerated Networking: Enabled

**Authentication**:
- SSH key-based (recommended)
- Password-based (optional)

### 3. Software Stack

#### Docker Engine
- Version: Latest stable
- Configuration: Optimized for ContainerLab
- Custom network pools
- Log rotation enabled

#### ContainerLab
- Version: Latest
- Installation: Official installer script
- Integration: Systemd service for auto-start

#### Antimony GUI
- Port: 8080
- Technology: Node.js + Express
- Features:
  - Lab management
  - Topology visualization
  - Container control
  - Log viewing
  - File editor

#### Supporting Tools
- **Go**: Required for some ContainerLab features
- **Python 3**: Automation and scripting
- **Ansible**: Configuration management
- **kubectl/Helm**: Kubernetes integration
- **VRNetlab**: Virtual router support

### 4. Lab Topologies

#### RADIUS 802.1X Lab
**Components**:
- 1x RADIUS server (FreeRADIUS)
- 3x Network switches (Cisco, Arista, Juniper)
- 3x Test clients (various EAP methods)
- 2x Identity providers (AD, LDAP)
- 1x Certificate Authority
- 1x Syslog server
- 1x Traffic generator

**Network Topology**:
```
                    ┌──────────────┐
                    │   RADIUS     │
                    │   Server     │
                    └──────┬───────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   ┌────▼────┐       ┌────▼────┐       ┌────▼────┐
   │ Cisco   │       │ Arista  │       │Juniper  │
   │ Switch  │       │ Switch  │       │ Switch  │
   └────┬────┘       └────┬────┘       └────┬────┘
        │                 │                  │
   ┌────▼────┐       ┌────▼────┐       ┌────▼────┐
   │ Client  │       │ Client  │       │ Client  │
   │EAP-TLS  │       │  PEAP   │       │EAP-TTLS │
   └─────────┘       └─────────┘       └─────────┘
```

#### TACACS+ Lab
**Components**:
- 1x TACACS+ server
- 7x Network devices (routers, switches, firewalls)
- 3x Identity providers (AD, LDAP, SAML)
- 1x Audit server
- 1x Jump host
- 1x Monitoring server

**Authentication Flow**:
```
┌─────────┐      ┌──────────┐      ┌──────────┐
│ Network │─────▶│ TACACS+  │─────▶│   IDP    │
│ Device  │◀─────│  Server  │◀─────│  (AD)    │
└─────────┘      └──────────┘      └──────────┘
     │                 │
     │                 ▼
     │           ┌──────────┐
     └──────────▶│  Audit   │
                 │  Server  │
                 └──────────┘
```

#### ZTNA Lab
**Components**:
- 1x ZTNA Gateway
- 1x ZTNA Controller
- 3x Identity providers (Azure AD, Okta, Google)
- 6x Protected applications
- 3x Security services (EDR, Posture, MFA)
- 3x User endpoints
- 1x Firewall
- 1x Load balancer
- Monitoring infrastructure

**Zero Trust Architecture**:
```
┌─────────┐      ┌──────────┐      ┌──────────┐
│  User   │─────▶│   ZTNA   │─────▶│Protected │
│Endpoint │      │ Gateway  │      │   App    │
└─────────┘      └────┬─────┘      └──────────┘
                      │
                 ┌────▼─────┐
                 │   IDP    │
                 │ (SAML)   │
                 └────┬─────┘
                      │
                 ┌────▼─────┐
                 │ Posture  │
                 │  Check   │
                 └──────────┘
```

## Data Flow

### Deployment Flow

1. **User triggers workflow** → GitHub Actions
2. **GitHub Actions** → Azure ARM template deployment
3. **ARM template** → Creates Azure resources
4. **cloud-init** → Initial VM configuration
5. **Setup scripts** → Install software stack
6. **Import scripts** → Pull container images
7. **Deploy scripts** → Launch lab topologies
8. **Antimony setup** → Start web GUI

### Lab Operation Flow

1. **User accesses Antimony GUI** → Port 8080
2. **Antimony GUI** → ContainerLab API
3. **ContainerLab** → Docker Engine
4. **Docker** → Launches containers
5. **Containers** → Form network topology
6. **Monitoring** → Collects metrics and logs

## Security Architecture

### Network Security

**Layers**:
1. Azure NSG (perimeter)
2. VM firewall (host-based)
3. Docker networks (container isolation)
4. ContainerLab management network (control plane)

**Segmentation**:
- Management network: 172.20.X.0/24
- Lab networks: Isolated per topology
- External access: Controlled via NSG

### Authentication & Authorization

**VM Access**:
- SSH key-based authentication
- No password authentication (recommended)
- Sudo access for admin user

**Container Access**:
- Docker socket access control
- ContainerLab RBAC (future)
- Antimony GUI authentication (future)

### Data Protection

**At Rest**:
- Azure Disk Encryption (optional)
- Premium SSD with encryption

**In Transit**:
- SSH for management
- HTTPS for web interfaces
- TLS for container communication

## Scalability

### Vertical Scaling
- Resize VM (stop, resize, start)
- Add more data disks
- Increase network bandwidth

### Horizontal Scaling
- Deploy multiple VMs
- Use Azure Load Balancer
- Implement Clabernetes for Kubernetes

### Resource Limits

| VM Size | Max Containers | Max Labs | Recommended Use |
|---------|---------------|----------|-----------------|
| D4s_v3  | 10-15 | 1-2 | Testing |
| D8s_v3  | 20-30 | 2-4 | Development |
| D16s_v3 | 40-60 | 4-8 | Production |
| D32s_v3 | 80-100 | 8-16 | Enterprise |

## Monitoring & Observability

### Metrics Collection
- **Azure Monitor**: VM metrics
- **Prometheus**: Container metrics
- **Grafana**: Visualization
- **Docker stats**: Resource usage

### Logging
- **Azure Log Analytics**: VM logs
- **Syslog**: Application logs
- **Docker logs**: Container logs
- **ContainerLab logs**: Topology events

### Alerting
- **Azure Alerts**: Infrastructure issues
- **Prometheus Alertmanager**: Application alerts
- **Custom scripts**: Lab-specific alerts

## Disaster Recovery

### Backup Strategy
1. **VM Snapshots**: Azure Backup
2. **Lab Configurations**: Git repository
3. **Container Images**: Azure Container Registry
4. **Data Disk**: Azure Backup

### Recovery Procedures
1. **VM Failure**: Restore from snapshot
2. **Lab Corruption**: Redeploy from Git
3. **Data Loss**: Restore from backup
4. **Region Failure**: Deploy to alternate region

## Cost Optimization

### Strategies
1. **Auto-shutdown**: Stop VM during off-hours
2. **Right-sizing**: Use appropriate VM size
3. **Reserved Instances**: For long-term use
4. **Spot Instances**: For non-critical workloads
5. **Storage optimization**: Delete unused images

### Cost Breakdown

**Monthly Estimates (USD)**:
- VM (D8s_v3): ~$280
- Storage (512 GB): ~$80
- Networking: ~$20
- **Total**: ~$380/month

**Cost Reduction**:
- Stop when not in use: Save 70%
- Use D4s_v3: Save 50%
- Reserved Instance: Save 40%

## Future Enhancements

### Planned Features
1. **Multi-region deployment**
2. **Kubernetes integration (Clabernetes)**
3. **CI/CD pipeline integration**
4. **Advanced monitoring dashboards**
5. **Automated testing framework**
6. **Template marketplace**
7. **User authentication for Antimony**
8. **REST API for automation**

### Integration Opportunities
1. **Azure DevOps**: CI/CD pipelines
2. **Azure AD**: SSO authentication
3. **Azure Key Vault**: Secrets management
4. **Azure Container Registry**: Image storage
5. **Azure Kubernetes Service**: Clabernetes backend

## Troubleshooting Guide

### Common Issues

**Issue**: VM won't start
- Check Azure portal for errors
- Verify quota limits
- Check NSG rules

**Issue**: Can't SSH to VM
- Verify SSH key
- Check NSG rules
- Verify VM is running

**Issue**: ContainerLab won't deploy
- Check Docker status
- Verify images are available
- Check disk space

**Issue**: Antimony GUI not accessible
- Check service status
- Verify port 8080 is open
- Check firewall rules

## References

- [ContainerLab Documentation](https://containerlab.dev)
- [Azure ARM Templates](https://docs.microsoft.com/azure/azure-resource-manager/templates/)
- [Docker Documentation](https://docs.docker.com)
- [VRNetlab GitHub](https://github.com/vrnetlab/vrnetlab)

---

**Version**: 1.0.0  
**Last Updated**: 2025-10-18
