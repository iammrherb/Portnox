# Quick Start Guide

Get your Portnox ContainerLab environment running in Azure in under 10 minutes!

## Prerequisites

- Azure subscription
- GitHub account (for GitHub Actions deployment) OR Azure CLI (for manual deployment)

## Method 1: GitHub Actions (Easiest) ⚡

### Step 1: Configure GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add:

```
Name: AZURE_SUBSCRIPTION_ID
Value: <your-subscription-id>

Name: AZURE_TENANT_ID
Value: <your-tenant-id>

Name: AZURE_CLIENT_ID
Value: <your-client-id>

Name: AZURE_CLIENT_SECRET
Value: <your-client-secret>
```

**To get these values:**
```bash
az login
az ad sp create-for-rbac --name "portnox-sp" --role contributor --scopes /subscriptions/{subscription-id} --sdk-auth
```

### Step 2: Run Workflow

1. Go to **Actions** tab
2. Select **Deploy ContainerLab to Azure**
3. Click **Run workflow**
4. Use defaults or customize:
   - VM Name: `portnox-containerlab`
   - VM Size: `Standard_D8s_v3`
   - Location: `eastus`
   - Deploy labs: ✅
   - Import images: ✅
5. Click **Run workflow**

### Step 3: Wait for Completion

The workflow takes about 15-20 minutes. You'll see:
- ✅ Infrastructure deployment
- ✅ VM configuration
- ✅ Lab deployment
- ✅ Image import
- ✅ Antimony setup

### Step 4: Access Your Environment

Check the workflow summary for:
- SSH command
- Antimony GUI URL
- VM hostname and IP

Download the SSH key from artifacts and:
```bash
chmod 600 azure_key
ssh -i azure_key azureuser@<vm-hostname>
```

## Method 2: Makefile (Quick) 🚀

### Step 1: Install Prerequisites

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login
az login
```

### Step 2: Deploy

```bash
cd azure-deployment
make deploy
```

That's it! The Makefile handles everything:
- ✅ SSH key generation
- ✅ Resource group creation
- ✅ ARM template deployment
- ✅ Displays access information

### Step 3: Access

```bash
# SSH into VM
make ssh

# Open Antimony GUI
make open-gui

# Check status
make status
```

## Method 3: Azure CLI (Manual) 🔧

### Step 1: Setup

```bash
# Clone repo
git clone https://github.com/iammrherb/Portnox.git
cd Portnox/azure-deployment

# Login to Azure
az login

# Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_portnox -N ""
```

### Step 2: Deploy

```bash
# Create resource group
az group create --name portnox-clab-rg --location eastus

# Deploy
az deployment group create \
  --resource-group portnox-clab-rg \
  --template-file templates/containerlab-vm.json \
  --parameters \
    vmName="portnox-clab" \
    adminUsername="azureuser" \
    authenticationType="sshPublicKey" \
    adminPasswordOrKey="$(cat ~/.ssh/azure_portnox.pub)"
```

### Step 3: Get Access Info

```bash
# Get hostname
az deployment group show \
  --resource-group portnox-clab-rg \
  --name containerlab-vm \
  --query properties.outputs.hostname.value -o tsv

# SSH
ssh -i ~/.ssh/azure_portnox azureuser@<hostname>
```

## First Steps After Deployment

### 1. Verify Installation

```bash
# Check ContainerLab
containerlab version

# Check Docker
docker ps

# Check Antimony GUI
curl http://localhost:8080
```

### 2. Deploy Your First Lab

```bash
# List available labs
ls /data/labs/

# Deploy RADIUS lab
sudo containerlab deploy -t /data/labs/portnox-radius-802.1x.clab.yml

# Check status
sudo containerlab inspect --all
```

### 3. Access Antimony GUI

Open browser to: `http://<vm-hostname>:8080`

### 4. Explore Containers

```bash
# List running containers
clab-ps

# Access container shell
clab-shell portnox-radius

# Get container IP
clab-ip portnox-radius
```

## Common Commands

```bash
# Lab Management
clab-list                    # List all labs
clab-manage deploy <file>    # Deploy lab
clab-manage destroy <file>   # Destroy lab
clab-ps                      # Show containers

# Container Access
clab-shell <name>            # Open shell
clab-ip <name>               # Get IP address
docker logs <name>           # View logs

# Navigation
cdlabs                       # Go to labs directory
cdimages                     # Go to images directory
cdconfigs                    # Go to configs directory
```

## Troubleshooting

### Can't SSH?
```bash
# Check VM is running
az vm get-instance-view \
  --resource-group portnox-clab-rg \
  --name portnox-clab \
  --query instanceView.statuses

# Check NSG rules
az network nsg rule list \
  --resource-group portnox-clab-rg \
  --nsg-name portnox-clab-nsg \
  --output table
```

### Antimony GUI not loading?
```bash
# SSH into VM
ssh -i <key> azureuser@<hostname>

# Check service
sudo systemctl status antimony-gui

# Restart service
sudo systemctl restart antimony-gui

# View logs
sudo journalctl -u antimony-gui -f
```

### Lab won't deploy?
```bash
# Check Docker
sudo docker ps

# Check images
sudo docker images

# Re-import images
sudo /tmp/import-images.sh

# Check ContainerLab logs
sudo containerlab deploy -t <lab-file> --debug
```

## Next Steps

1. **Explore Labs**: Try all three pre-configured labs
2. **Customize**: Edit lab files in `/data/labs/`
3. **Add Images**: Import your own container images
4. **Create Topologies**: Use Antimony GUI to design new labs
5. **Automate**: Write scripts using ContainerLab CLI

## Cleanup

### Stop VM (save costs)
```bash
make stop
# or
az vm stop --resource-group portnox-clab-rg --name portnox-clab
```

### Delete Everything
```bash
make destroy
# or
az group delete --name portnox-clab-rg --yes
```

## Cost Estimation

| VM Size | Monthly Cost (USD) | Use Case |
|---------|-------------------|----------|
| Standard_D4s_v3 | ~$140 | Testing |
| Standard_D8s_v3 | ~$280 | Development |
| Standard_D16s_v3 | ~$560 | Production |

**Tips to reduce costs:**
- Stop VM when not in use
- Use smaller VM sizes for testing
- Delete resources when done
- Use Azure Reserved Instances for long-term use

## Support

- **Documentation**: See [README.md](README.md)
- **Issues**: https://github.com/iammrherb/Portnox/issues
- **ContainerLab**: https://containerlab.dev

---

**Happy Labbing! 🚀**
