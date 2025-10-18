# Portnox ContainerLab Azure Deployment - Complete Solution

## 📦 What's Included

This deployment package provides a complete, production-ready solution for deploying Portnox ContainerLab environments on Azure with full automation and integration.

### Core Components

#### 1. Infrastructure as Code
- **ARM Template** (`templates/containerlab-vm.json`)
  - Complete Azure infrastructure definition
  - Configurable VM sizes and storage
  - Network security groups with all required ports
  - Public IP with DNS name
  - Premium SSD storage for performance

#### 2. Automation
- **GitHub Actions Workflow** (`.github/workflows/deploy-azure-containerlab.yml`)
  - Fully automated deployment pipeline
  - Multi-stage deployment (infrastructure → configuration → labs)
  - Artifact management for SSH keys
  - Deployment summary generation
  - CI/CD ready

- **Makefile** (`Makefile`)
  - 20+ commands for easy management
  - One-command deployment
  - Built-in validation and testing
  - Cost estimation
  - Backup and restore

#### 3. Installation Scripts
- **ContainerLab Setup** (`scripts/setup-containerlab.sh`)
  - Docker installation and configuration
  - ContainerLab latest version
  - Go, Python, Node.js environments
  - Network tools (FRRouting, iperf3, tcpdump)
  - VRNetlab support
  - Kubernetes tools (kubectl, Helm)
  - System optimization for networking
  - Helper scripts and aliases

- **Antimony GUI Setup** (`scripts/setup-antimony.sh`)
  - Node.js web application
  - REST API for ContainerLab management
  - Interactive web interface
  - Real-time lab monitoring
  - Container log viewing
  - Topology editor

- **Image Import** (`scripts/import-images.sh`)
  - Pre-defined image lists by category
  - Custom Portnox RADIUS image
  - Custom Portnox TACACS+ image
  - VRNetlab image support
  - Automatic image tagging

#### 4. Lab Topologies

##### RADIUS 802.1X Authentication Lab
**File**: `labs/portnox-radius-802.1x.clab.yml`

**Features**:
- Multi-vendor switch support (Cisco, Arista, Juniper)
- Multiple EAP methods (TLS, PEAP, TTLS)
- Identity provider integration (AD, LDAP)
- Certificate Authority
- Comprehensive logging

**Nodes**: 12 containers
**Use Cases**:
- Wired 802.1X testing
- Wireless authentication
- EAP method validation
- Multi-vendor interoperability

##### TACACS+ Device Administration Lab
**File**: `labs/portnox-tacacs-plus.clab.yml`

**Features**:
- Multi-vendor device support (Cisco, Arista, Juniper, Palo Alto, Fortinet)
- Multiple identity providers (AD, LDAP, SAML)
- Command authorization
- Audit logging
- Jump host for management

**Nodes**: 13 containers
**Use Cases**:
- Device administration
- Command authorization testing
- Audit compliance
- Multi-vendor AAA

##### Zero Trust Network Access Lab
**File**: `labs/portnox-ztna-deployment.clab.yml`

**Features**:
- ZTNA Gateway and Controller
- Multiple IdPs (Azure AD, Okta, Google Workspace)
- 6 protected applications (Web, API, DB, File, SSH, RDP)
- Security services (EDR, Posture Check, MFA)
- User endpoints (Corporate, BYOD, Mobile)
- Complete monitoring stack

**Nodes**: 24 containers
**Use Cases**:
- Zero Trust architecture
- Application access control
- Device posture validation
- MFA flows
- SAML/OIDC integration

#### 5. Documentation
- **README.md**: Complete user guide
- **QUICKSTART.md**: 3 deployment methods in under 10 minutes
- **ARCHITECTURE.md**: Technical architecture and design
- **DEPLOYMENT_SUMMARY.md**: This file

## 🚀 Deployment Methods

### Method 1: GitHub Actions (Recommended)
**Time**: 15-20 minutes  
**Difficulty**: Easy  
**Requirements**: GitHub account, Azure credentials

1. Configure GitHub secrets
2. Run workflow
3. Wait for completion
4. Access environment

**Best for**: Teams, CI/CD, reproducible deployments

### Method 2: Makefile
**Time**: 10-15 minutes  
**Difficulty**: Easy  
**Requirements**: Azure CLI, make

```bash
cd azure-deployment
make deploy
```

**Best for**: Developers, quick testing, local control

### Method 3: Azure CLI
**Time**: 15-20 minutes  
**Difficulty**: Medium  
**Requirements**: Azure CLI, manual steps

```bash
az group create --name rg --location eastus
az deployment group create --template-file template.json
```

**Best for**: Custom configurations, learning, troubleshooting

## 📊 What Gets Deployed

### Azure Resources
1. **Resource Group**: Container for all resources
2. **Virtual Network**: 10.0.0.0/16 with subnet
3. **Network Security Group**: 9 inbound rules
4. **Public IP**: Static with DNS name
5. **Network Interface**: With accelerated networking
6. **Virtual Machine**: Ubuntu 22.04 LTS
7. **OS Disk**: 128 GB Premium SSD
8. **Data Disk**: 512 GB Premium SSD

### Software Stack
1. **Docker Engine**: Latest stable
2. **ContainerLab**: Latest version
3. **Antimony GUI**: Web interface on port 8080
4. **Go**: 1.21.5
5. **Python 3**: With networking libraries
6. **Node.js**: 20.x
7. **Network Tools**: FRRouting, tcpdump, iperf3
8. **Automation Tools**: Ansible, Netmiko, NAPALM
9. **Kubernetes Tools**: kubectl, Helm

### Container Images
**Network OS**:
- Nokia SR Linux
- FRRouting

**Authentication**:
- FreeRADIUS
- TACACS+
- Custom Portnox images

**Identity Providers**:
- OpenLDAP
- SAML IdP simulator

**Applications**:
- Nginx
- HAProxy
- PostgreSQL
- Redis

**Utilities**:
- Ubuntu
- Alpine
- iperf3

**Monitoring**:
- Prometheus
- Grafana

## 🎯 Key Features

### Automation
- ✅ One-click deployment
- ✅ Automated software installation
- ✅ Pre-configured labs
- ✅ Image import automation
- ✅ Service auto-start
- ✅ Health checks

### Integration
- ✅ Antimony GUI for topology management
- ✅ VRNetlab for virtual devices
- ✅ Kubernetes support (Clabernetes ready)
- ✅ CI/CD pipeline integration
- ✅ Monitoring and logging

### Security
- ✅ SSH key authentication
- ✅ Network security groups
- ✅ Isolated lab networks
- ✅ Encrypted storage
- ✅ Audit logging

### Scalability
- ✅ Multiple VM sizes supported
- ✅ Configurable storage
- ✅ Multi-lab deployment
- ✅ Resource optimization
- ✅ Cost management

## 📈 Performance Characteristics

### VM Sizing Guide

| VM Size | vCPUs | RAM | Max Containers | Concurrent Labs | Monthly Cost |
|---------|-------|-----|----------------|-----------------|--------------|
| D4s_v3  | 4     | 16GB | 10-15         | 1-2            | ~$140        |
| D8s_v3  | 8     | 32GB | 20-30         | 2-4            | ~$280        |
| D16s_v3 | 16    | 64GB | 40-60         | 4-8            | ~$560        |
| D32s_v3 | 32    | 128GB| 80-100        | 8-16           | ~$1,120      |

### Network Performance
- **Accelerated Networking**: Enabled
- **Bandwidth**: Up to 16 Gbps (D8s_v3)
- **Latency**: <1ms between containers
- **Throughput**: 10+ Gbps inter-container

### Storage Performance
- **OS Disk**: Premium SSD, 120 IOPS/GB
- **Data Disk**: Premium SSD, 120 IOPS/GB
- **Throughput**: Up to 900 MB/s
- **Latency**: <2ms

## 🔧 Management Commands

### Quick Commands
```bash
# Deployment
make deploy              # Deploy everything
make deploy-quick        # Quick deploy with defaults
make info                # Show deployment info

# VM Management
make status              # Check VM status
make start               # Start VM
make stop                # Stop VM
make restart             # Restart VM
make ssh                 # SSH into VM

# Lab Management
clab-list                # List all labs
clab-manage deploy       # Deploy lab
clab-manage destroy      # Destroy lab
clab-ps                  # Show containers

# Monitoring
make logs                # View boot logs
make test                # Run tests
make cost                # Show costs

# Cleanup
make destroy             # Delete everything
make clean               # Clean local files
```

### Antimony GUI Commands
Access at `http://<vm-hostname>:8080`

- View active labs
- Browse lab files
- Manage container images
- Edit topologies
- Deploy/destroy labs
- View logs

## 🔐 Security Best Practices

### Implemented
1. ✅ SSH key authentication (no passwords)
2. ✅ Network security groups
3. ✅ Isolated management network
4. ✅ Premium SSD with encryption
5. ✅ Accelerated networking
6. ✅ Audit logging

### Recommended
1. 🔸 Restrict NSG to known IPs
2. 🔸 Enable Azure Security Center
3. 🔸 Use Azure Key Vault for secrets
4. 🔸 Enable diagnostic logging
5. 🔸 Regular security updates
6. 🔸 Implement backup strategy

## 💰 Cost Management

### Cost Breakdown (D8s_v3)
- **VM**: $280/month
- **Storage**: $80/month
- **Networking**: $20/month
- **Total**: ~$380/month

### Cost Optimization
1. **Stop when not in use**: Save 70%
2. **Use smaller VM**: Save 50%
3. **Reserved Instances**: Save 40%
4. **Spot Instances**: Save 80% (non-critical)
5. **Auto-shutdown**: Schedule off-hours

### Cost Monitoring
```bash
make cost                # View current costs
az consumption usage list # Detailed usage
```

## 🐛 Troubleshooting

### Common Issues

**VM won't start**
```bash
make status
az vm get-instance-view --resource-group rg --name vm
```

**Can't SSH**
```bash
# Check NSG
az network nsg rule list --resource-group rg --nsg-name nsg

# Verify key
ssh-keygen -l -f ~/.ssh/azure_portnox.pub
```

**Lab won't deploy**
```bash
# Check Docker
make ssh-cmd CMD="sudo docker ps"

# Check images
make ssh-cmd CMD="sudo docker images"

# Re-import
make ssh-cmd CMD="sudo /tmp/import-images.sh"
```

**Antimony GUI not loading**
```bash
# Check service
make ssh-cmd CMD="sudo systemctl status antimony-gui"

# Restart
make ssh-cmd CMD="sudo systemctl restart antimony-gui"

# View logs
make ssh-cmd CMD="sudo journalctl -u antimony-gui -f"
```

## 📚 Additional Resources

### Documentation
- [README.md](README.md) - Complete user guide
- [QUICKSTART.md](QUICKSTART.md) - Quick start guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical architecture

### External Links
- [ContainerLab](https://containerlab.dev)
- [VRNetlab](https://github.com/vrnetlab/vrnetlab)
- [Azure ARM Templates](https://docs.microsoft.com/azure/azure-resource-manager/templates/)
- [Docker](https://docs.docker.com)

### Support
- GitHub Issues: https://github.com/iammrherb/Portnox/issues
- ContainerLab Slack: https://containerlab.dev/community/

## 🎓 Learning Path

### Beginner
1. Deploy using GitHub Actions
2. Access Antimony GUI
3. Deploy RADIUS lab
4. Explore containers

### Intermediate
1. Deploy using Makefile
2. Customize lab topologies
3. Add custom containers
4. Configure monitoring

### Advanced
1. Deploy using Azure CLI
2. Create custom labs
3. Integrate with CI/CD
4. Implement Clabernetes

## 🔄 Update and Maintenance

### Regular Updates
```bash
# Update ContainerLab
sudo bash -c "$(curl -sL https://get.containerlab.dev)"

# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Update images
sudo /tmp/import-images.sh
```

### Backup Strategy
```bash
# Backup labs
make backup

# Restore labs
make restore BACKUP_DATE=20231018
```

### Monitoring
- Azure Monitor for VM metrics
- Prometheus for container metrics
- Grafana for visualization
- Syslog for application logs

## 🚀 Next Steps

1. **Deploy**: Choose your deployment method
2. **Explore**: Try all three lab topologies
3. **Customize**: Modify labs for your needs
4. **Integrate**: Connect to your CI/CD
5. **Scale**: Add more VMs or upgrade size
6. **Automate**: Build custom workflows

## 📝 Changelog

### Version 1.0.0 (2025-10-18)
- Initial release
- ARM template for Azure deployment
- GitHub Actions workflow
- Three pre-configured labs
- Antimony GUI integration
- Complete documentation
- Makefile for easy management

## 🙏 Credits

- **ContainerLab Team**: Amazing orchestration tool
- **VRNetlab Project**: Virtual device support
- **Nokia**: SR Linux container images
- **Open Source Community**: Various container images

---

**Version**: 1.0.0  
**Author**: iammrherb@gmail.com  
**Repository**: https://github.com/iammrherb/Portnox  
**License**: MIT
