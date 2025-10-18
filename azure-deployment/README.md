# Portnox ContainerLab Azure Deployment

Complete automated deployment solution for Portnox ContainerLab environments on Azure, featuring full integration with Antimony GUI, comprehensive lab topologies, and support for RADIUS, TACACS+, and ZTNA scenarios.

## 🚀 Features

- **Fully Automated Deployment**: One-click deployment to Azure using GitHub Actions
- **Complete Infrastructure**: ARM template provisions VM, networking, storage, and security
- **Pre-configured Labs**: Ready-to-use topologies for:
  - 802.1X Authentication (RADIUS) with multiple EAP methods
  - TACACS+ Device Administration
  - Zero Trust Network Access (ZTNA)
- **Antimony GUI**: Web-based topology management interface
- **Multi-Vendor Support**: Cisco, Arista, Juniper, Palo Alto, Fortinet, and more
- **VRNetlab Integration**: Support for virtual network device images
- **Comprehensive Monitoring**: Built-in logging, metrics, and visualization

## 📋 Prerequisites

### Azure Requirements
- Active Azure subscription
- Azure CLI installed (for manual deployment)
- Contributor role on the subscription or resource group

### GitHub Requirements
- GitHub account with access to this repository
- GitHub Actions enabled
- Required secrets configured (see Configuration section)

### Local Requirements (for manual deployment)
- Bash shell (Linux/macOS/WSL)
- Azure CLI
- SSH client

## 🔧 Configuration

### GitHub Secrets

Configure the following secrets in your GitHub repository (Settings → Secrets and variables → Actions):

```
AZURE_SUBSCRIPTION_ID    - Your Azure subscription ID
AZURE_TENANT_ID          - Your Azure AD tenant ID
AZURE_CLIENT_ID          - Service principal client ID
AZURE_CLIENT_SECRET      - Service principal client secret
```

### Creating Azure Service Principal

```bash
# Login to Azure
az login

# Create service principal
az ad sp create-for-rbac \
  --name "portnox-containerlab-sp" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth

# Copy the output JSON and extract values for GitHub secrets
```

## 🚀 Deployment Options

### Option 1: GitHub Actions (Recommended)

1. Navigate to **Actions** tab in GitHub
2. Select **Deploy ContainerLab to Azure** workflow
3. Click **Run workflow**
4. Configure parameters:
   - **VM Name**: Name for your VM (default: portnox-containerlab)
   - **VM Size**: Azure VM size (default: Standard_D8s_v3)
   - **Resource Group**: Azure resource group name
   - **Location**: Azure region (default: eastus)
   - **Data Disk Size**: Size in GB (default: 512)
   - **Deploy Labs**: Whether to deploy pre-configured labs
   - **Import Images**: Whether to import container images
5. Click **Run workflow**

The workflow will:
- ✅ Create Azure infrastructure
- ✅ Install ContainerLab and dependencies
- ✅ Setup Antimony GUI
- ✅ Import container images
- ✅ Deploy lab topologies
- ✅ Provide access information

### Option 2: Azure CLI (Manual)

```bash
# Clone repository
git clone https://github.com/iammrherb/Portnox.git
cd Portnox/azure-deployment

# Login to Azure
az login

# Create resource group
az group create \
  --name portnox-containerlab-rg \
  --location eastus

# Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_portnox -N ""

# Deploy ARM template
az deployment group create \
  --resource-group portnox-containerlab-rg \
  --template-file templates/containerlab-vm.json \
  --parameters \
    vmName="portnox-containerlab" \
    vmSize="Standard_D8s_v3" \
    adminUsername="azureuser" \
    authenticationType="sshPublicKey" \
    adminPasswordOrKey="$(cat ~/.ssh/azure_portnox.pub)" \
    dataDiskSizeGB=512

# Get VM details
az deployment group show \
  --resource-group portnox-containerlab-rg \
  --name containerlab-vm \
  --query properties.outputs

# SSH into VM
ssh -i ~/.ssh/azure_portnox azureuser@<vm-hostname>
```

### Option 3: Azure Portal

1. Navigate to Azure Portal
2. Click **Create a resource** → **Template deployment**
3. Click **Build your own template in the editor**
4. Copy contents of `templates/containerlab-vm.json`
5. Fill in parameters
6. Review and create

## 📊 Accessing Your Deployment

After deployment completes, you'll have access to:

### Antimony GUI
```
http://<vm-hostname>:8080
```
Web-based interface for managing ContainerLab topologies

### SSH Access
```bash
ssh -i <ssh-key> azureuser@<vm-hostname>
```

### ContainerLab CLI
```bash
# List all labs
clab-list

# Deploy a lab
clab-manage deploy /data/labs/portnox-radius-802.1x.clab.yml

# Destroy a lab
clab-manage destroy /data/labs/portnox-radius-802.1x.clab.yml

# Check container status
clab-ps

# Access container shell
clab-shell <container-name>
```

## 🔬 Available Lab Topologies

### 1. RADIUS 802.1X Authentication Lab
**File**: `labs/portnox-radius-802.1x.clab.yml`

**Components**:
- Portnox RADIUS server
- Cisco, Arista, Juniper switches (802.1X authenticators)
- Test clients with various EAP methods (TLS, PEAP, TTLS)
- Active Directory / LDAP identity providers
- Certificate Authority
- Syslog server

**Use Cases**:
- Testing wired 802.1X authentication
- Wireless authentication scenarios
- EAP method validation
- Multi-vendor authenticator testing

**Deploy**:
```bash
sudo containerlab deploy -t /data/labs/portnox-radius-802.1x.clab.yml
```

### 2. TACACS+ Device Administration Lab
**File**: `labs/portnox-tacacs-plus.clab.yml`

**Components**:
- Portnox TACACS+ server
- Multi-vendor network devices (Cisco, Arista, Juniper, Palo Alto, Fortinet)
- Active Directory / LDAP / SAML identity providers
- Audit logging server
- Jump host for management

**Use Cases**:
- Device administration authentication
- Command authorization testing
- Accounting and audit logging
- Multi-vendor TACACS+ client testing

**Deploy**:
```bash
sudo containerlab deploy -t /data/labs/portnox-tacacs-plus.clab.yml
```

### 3. Zero Trust Network Access (ZTNA) Lab
**File**: `labs/portnox-ztna-deployment.clab.yml`

**Components**:
- ZTNA Gateway and Controller
- Multiple identity providers (Azure AD, Okta, Google Workspace)
- Protected applications (Web, API, Database, File Server, SSH, RDP)
- Security services (EDR, Posture Check, MFA)
- User endpoints (Corporate, BYOD, Mobile)
- Monitoring and logging infrastructure

**Use Cases**:
- Zero Trust architecture testing
- Application access control
- Device posture validation
- Multi-factor authentication flows
- SAML/OIDC integration testing

**Deploy**:
```bash
sudo containerlab deploy -t /data/labs/portnox-ztna-deployment.clab.yml
```

## 🛠️ VM Specifications

### Recommended Sizes

| VM Size | vCPUs | RAM | Use Case |
|---------|-------|-----|----------|
| Standard_D4s_v3 | 4 | 16 GB | Small labs (1-5 nodes) |
| Standard_D8s_v3 | 8 | 32 GB | Medium labs (5-15 nodes) |
| Standard_D16s_v3 | 16 | 64 GB | Large labs (15-30 nodes) |
| Standard_D32s_v3 | 32 | 128 GB | Enterprise labs (30+ nodes) |

### Storage

- **OS Disk**: 128 GB Premium SSD
- **Data Disk**: 512 GB Premium SSD (configurable)
  - `/data/containerlab` - ContainerLab working directory
  - `/data/labs` - Lab topology files
  - `/data/images` - Container images
  - `/data/configs` - Configuration files
  - `/data/vrnetlab` - VRNetlab images

### Networking

**Inbound Ports**:
- 22 (SSH)
- 80 (HTTP)
- 443 (HTTPS)
- 1812-1813 (RADIUS)
- 49 (TACACS+)
- 8080 (Antimony GUI)
- 8443 (ContainerLab API)
- 8000-9000 (Lab services)

## 📦 Installed Software

### Core Components
- **Docker**: Container runtime
- **ContainerLab**: Network lab orchestration
- **Antimony GUI**: Web-based topology manager
- **Go**: Required for some tools
- **Python 3**: Automation and scripting
- **Node.js**: Antimony GUI backend

### Network Tools
- FRRouting
- iproute2, iptables, nftables
- tcpdump, wireshark-cli
- iperf3, netcat, socat

### Automation Tools
- Ansible
- Netmiko, NAPALM, Nornir
- Python networking libraries

### Monitoring
- Prometheus
- Grafana
- kubectl, Helm (for Clabernetes)

## 🔐 Security Considerations

### Network Security
- Network Security Group (NSG) controls inbound traffic
- Accelerated networking enabled for better performance
- Management network isolated from lab networks

### Authentication
- SSH key-based authentication (recommended)
- Password authentication available but not recommended
- Service accounts for automation

### Best Practices
1. Use SSH keys instead of passwords
2. Restrict NSG rules to known IP ranges
3. Regularly update VM and containers
4. Enable Azure Security Center
5. Use Azure Key Vault for secrets
6. Enable diagnostic logging

## 📚 Documentation

### ContainerLab
- Official docs: https://containerlab.dev
- Lab examples: https://containerlab.dev/lab-examples/
- Manual: https://containerlab.dev/manual/

### VRNetlab
- GitHub: https://github.com/vrnetlab/vrnetlab
- Supported platforms: https://github.com/vrnetlab/vrnetlab#supported-platforms

### Antimony
- Integrated web GUI for topology management
- Access at `http://<vm-ip>:8080`

## 🐛 Troubleshooting

### VM Not Accessible
```bash
# Check VM status
az vm get-instance-view \
  --resource-group portnox-containerlab-rg \
  --name portnox-containerlab \
  --query instanceView.statuses

# Check NSG rules
az network nsg show \
  --resource-group portnox-containerlab-rg \
  --name portnox-containerlab-nsg
```

### ContainerLab Issues
```bash
# Check ContainerLab version
containerlab version

# Inspect all labs
sudo containerlab inspect --all

# Check Docker
sudo docker ps
sudo docker logs <container-name>

# View ContainerLab logs
sudo journalctl -u containerlab-autostart
```

### Antimony GUI Not Loading
```bash
# Check service status
sudo systemctl status antimony-gui

# View logs
sudo journalctl -u antimony-gui -f

# Restart service
sudo systemctl restart antimony-gui
```

### Container Image Issues
```bash
# List images
docker images

# Re-run import script
sudo /tmp/import-images.sh

# Pull specific image
docker pull <image-name>
```

## 🔄 Updating

### Update ContainerLab
```bash
sudo bash -c "$(curl -sL https://get.containerlab.dev)"
```

### Update System Packages
```bash
sudo apt-get update
sudo apt-get upgrade -y
```

### Update Container Images
```bash
sudo /tmp/import-images.sh
```

## 🗑️ Cleanup

### Destroy Labs
```bash
# Destroy specific lab
sudo containerlab destroy -t /data/labs/<lab-file>.clab.yml

# Destroy all labs
sudo containerlab destroy --all
```

### Delete Azure Resources
```bash
# Delete entire resource group
az group delete \
  --name portnox-containerlab-rg \
  --yes \
  --no-wait
```

## 💡 Tips and Tricks

### Bash Aliases
The following aliases are pre-configured:

```bash
clab              # containerlab command
clab-list         # List all deployed labs
clab-ps           # Show running containers
clab-shell <name> # Open shell in container
clab-ip <name>    # Get container IP address
cdlabs            # cd /data/labs
cdimages          # cd /data/images
cdconfigs         # cd /data/configs
```

### Quick Commands
```bash
# Deploy all labs
for lab in /data/labs/*.clab.yml; do
  sudo containerlab deploy -t "$lab"
done

# Export lab topology
sudo containerlab graph -t <lab-file>.clab.yml

# Save running configs
sudo containerlab save -t <lab-file>.clab.yml

# Generate topology diagram
sudo containerlab graph -t <lab-file>.clab.yml --drawio
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see LICENSE.txt file for details.

## 📞 Support

For issues and questions:
- GitHub Issues: https://github.com/iammrherb/Portnox/issues
- ContainerLab Slack: https://containerlab.dev/community/
- Portnox Support: https://www.portnox.com/support/

## 🙏 Acknowledgments

- ContainerLab team for the amazing orchestration tool
- VRNetlab project for virtual network device support
- Nokia for SR Linux container images
- Open source community for various container images

---

**Version**: 1.0.0  
**Last Updated**: 2025-10-18  
**Author**: iammrherb@gmail.com
