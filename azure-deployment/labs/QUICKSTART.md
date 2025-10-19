# QuickStart Lab Guide

## Overview

This guide helps you deploy your first working ContainerLab topology using only publicly available images. No VRNetlab setup or custom image builds required!

## Which Labs Work Out-of-the-Box?

### ✅ Ready to Deploy (Public Images)
These labs use publicly available images and work immediately:

1. **quickstart-lab.clab.yml** - Simple leaf-spine with Nokia SR Linux + FRRouting
2. **nokia-srlinux-lab.clab.yml** - Nokia SR Linux leaf-spine BGP fabric
3. **frrouting-bgp-lab.clab.yml** - FRRouting BGP with route reflectors
4. **srl-example-02.clab.yml** - Nokia SR Linux example from community
5. **srl-example-03.clab.yml** - Nokia SR Linux example from community
6. **srl-ceos-example.clab.yml** - Nokia + Arista (if you have cEOS image)

### ⚠️ Require Manual Setup (VRNetlab)
These labs need vendor images to be manually downloaded and built:

1. **cisco-ios-xr-lab.clab.yml** - Requires Cisco IOS-XR image
2. **juniper-vmx-lab.clab.yml** - Requires Juniper vMX image
3. **paloalto-firewall-lab.clab.yml** - Requires Palo Alto PAN-OS image
4. **fortinet-fortigate-lab.clab.yml** - Requires Fortinet FortiOS image
5. **arista-ceos-lab.clab.yml** - Requires Arista cEOS image

### ⚠️ Require Custom Images
These labs need the Portnox custom images to be built:

1. **portnox-radius-802.1x.clab.yml** - Needs portnox/radius image
2. **portnox-tacacs-plus.clab.yml** - Needs portnox/tacacs image
3. **portnox-ztna-deployment.clab.yml** - Needs portnox/ztna-gateway image

## Quick Start: Deploy Your First Lab

### Step 1: Deploy the QuickStart Lab

```bash
# SSH to your VM
ssh -i azure_key azureuser@<vm-hostname>

# Deploy the quickstart lab
sudo containerlab deploy -t /data/labs/quickstart-lab.clab.yml
```

This will create:
- 3x Nokia SR Linux switches (spine + 2 leafs)
- 2x FRRouting routers
- 2x Test clients
- BGP routing between all nodes

### Step 2: Verify Deployment

```bash
# Check running containers
sudo containerlab inspect --all

# Should show 7 containers running
```

### Step 3: Access Devices

**Nokia SR Linux** (username: `admin`, password: `admin`):
```bash
# Get container name
sudo docker ps | grep srl

# Access CLI
sudo docker exec -it clab-quickstart-lab-srl-spine sr_cli
```

**FRRouting** (username: `admin`, password: `admin`):
```bash
# Access vtysh
sudo docker exec -it clab-quickstart-lab-frr-router1 vtysh
```

**Test Clients**:
```bash
# Access client
sudo docker exec -it clab-quickstart-lab-client1 bash

# Ping other client
ping 10.0.20.10
```

### Step 4: Explore the Topology

```bash
# View topology graph
sudo containerlab graph -t /data/labs/quickstart-lab.clab.yml

# This will show you the connections between all nodes
```

### Step 5: Clean Up

```bash
# Destroy the lab when done
sudo containerlab destroy -t /data/labs/quickstart-lab.clab.yml
```

## Building Custom Portnox Images

If you want to use the RADIUS, TACACS+, or ZTNA labs, you need to build the custom images first:

```bash
# SSH to your VM
ssh -i azure_key azureuser@<vm-hostname>

# Run the comprehensive image import script
sudo /tmp/import-images-comprehensive.sh
```

This will build:
- `portnox/portnox-radius:latest` - FreeRADIUS with LDAP/Kerberos support
- `portnox/portnox-tacacs:latest` - TACACS+ server with PAM integration
- `portnox/ztna-gateway:latest` - ZTNA gateway based on nginx

After building, you can deploy the Portnox labs:
```bash
sudo containerlab deploy -t /data/labs/portnox-radius-802.1x.clab.yml
```

## Setting Up VRNetlab Images

For Cisco, Juniper, Palo Alto, Fortinet, and other vendor labs, you need to:

### Step 1: Download Vendor Images

You need an account with each vendor to download their images:
- **Cisco**: Download from cisco.com (requires CCO account)
- **Juniper**: Download from juniper.net (requires JTAC account)
- **Palo Alto**: Download from paloaltonetworks.com
- **Fortinet**: Download from fortinet.com
- **Arista**: Download from arista.com (requires account)

### Step 2: Upload to VM

```bash
# From your local machine
scp -i azure_key <vendor-image>.qcow2 azureuser@<vm-hostname>:/tmp/
```

### Step 3: Build VRNetlab Image

```bash
# SSH to VM
ssh -i azure_key azureuser@<vm-hostname>

# Create vendor directory
sudo mkdir -p /data/vrnetlab/cisco-xrv9k
sudo mv /tmp/<cisco-image>.qcow2 /data/vrnetlab/cisco-xrv9k/

# Build the image
cd /opt/vrnetlab/xrv9k
sudo make docker-image

# Verify image was created
docker images | grep vrnetlab
```

### Step 4: Deploy Vendor Lab

```bash
sudo containerlab deploy -t /data/labs/cisco-ios-xr-lab.clab.yml
```

## Common Commands

```bash
# List all labs
ls -la /data/labs/

# Deploy a lab
sudo containerlab deploy -t /data/labs/<lab-file>

# List running labs
sudo containerlab inspect --all

# Destroy a lab
sudo containerlab destroy -t /data/labs/<lab-file>

# Destroy all labs
sudo containerlab destroy --all

# View lab topology
sudo containerlab graph -t /data/labs/<lab-file>

# Access a container
sudo docker exec -it <container-name> bash

# View container logs
sudo docker logs <container-name>

# List all images
docker images

# Check disk usage
docker system df
```

## Troubleshooting

### Issue: "pull access denied for vrnetlab/..."

**Cause**: VRNetlab images don't exist in Docker Hub - they must be built locally.

**Solution**: Follow the VRNetlab setup instructions above, or use a lab that doesn't require VRNetlab (like quickstart-lab.clab.yml).

### Issue: "pull access denied for portnox/..."

**Cause**: Custom Portnox images weren't built during deployment.

**Solution**: Run the image import script manually:
```bash
sudo /tmp/import-images-comprehensive.sh
```

### Issue: Container won't start

**Check logs**:
```bash
sudo docker logs <container-name>
```

**Check resources**:
```bash
# Some containers need significant resources
docker stats
free -h
df -h
```

### Issue: Can't connect to device

**Verify container is running**:
```bash
sudo docker ps | grep <container-name>
```

**Check container networking**:
```bash
sudo docker exec -it <container-name> ip addr
sudo docker network inspect <network-name>
```

## Next Steps

1. **Try the quickstart lab** - Get familiar with ContainerLab
2. **Explore Nokia SR Linux** - Learn the CLI and configuration
3. **Build custom images** - Deploy RADIUS/TACACS+ labs
4. **Set up VRNetlab** - Add vendor devices to your lab
5. **Create your own topology** - Combine different vendors and services

## Resources

- **ContainerLab Docs**: https://containerlab.dev/
- **Nokia SR Linux**: https://learn.srlinux.dev/
- **FRRouting**: https://frrouting.org/
- **VRNetlab**: https://github.com/vrnetlab/vrnetlab
- **Comprehensive Guide**: `/data/COMPREHENSIVE_GUIDE.md` on your VM

## Support

For issues or questions:
1. Check `/data/COMPREHENSIVE_GUIDE.md` for detailed documentation
2. Review ContainerLab documentation at https://containerlab.dev/
3. Check container logs: `sudo docker logs <container-name>`
4. Verify images are available: `docker images`

---

**Happy Labbing!** 🚀
