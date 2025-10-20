# Inter-VNET Routing and External Connectivity Guide

This guide explains how to configure network routing for ContainerLab containers to communicate with external Azure resources, other VNETs, and the internet.

## Table of Contents

1. [Overview](#overview)
2. [Network Architecture](#network-architecture)
3. [IP Forwarding Configuration](#ip-forwarding-configuration)
4. [VNET Peering](#vnet-peering)
5. [Route Tables](#route-tables)
6. [Container Networking](#container-networking)
7. [Testing Connectivity](#testing-connectivity)
8. [Troubleshooting](#troubleshooting)

## Overview

The ContainerLab VM is configured with IP forwarding enabled, allowing containers to route traffic through the VM to external networks. This enables:

- **Internet Access**: Containers can reach external services and APIs
- **VNET Peering**: Containers can communicate with resources in other Azure VNETs
- **Azure Services**: Containers can access Azure PaaS services (Storage, SQL, etc.)
- **On-Premises Networks**: Containers can reach on-premises resources via VPN/ExpressRoute

## Network Architecture

### Default Configuration

```
┌─────────────────────────────────────────────────────────┐
│                    Azure VNET                           │
│                  10.0.0.0/16                            │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │           ContainerLab Subnet                    │  │
│  │              10.0.0.0/24                         │  │
│  │                                                  │  │
│  │  ┌────────────────────────────────────────────┐ │  │
│  │  │      ContainerLab VM                       │ │  │
│  │  │      10.0.0.4 (example)                    │ │  │
│  │  │                                            │ │  │
│  │  │  IP Forwarding: Enabled                   │ │  │
│  │  │  NAT: Enabled via iptables                │ │  │
│  │  │                                            │ │  │
│  │  │  ┌──────────────────────────────────────┐ │ │  │
│  │  │  │   Docker Bridge Network              │ │ │  │
│  │  │  │   172.17.0.0/16                      │ │ │  │
│  │  │  │                                      │ │ │  │
│  │  │  │  ┌─────────┐  ┌─────────┐           │ │ │  │
│  │  │  │  │Container│  │Container│  ...      │ │ │  │
│  │  │  │  │172.17.0.2│ │172.17.0.3│          │ │ │  │
│  │  │  │  └─────────┘  └─────────┘           │ │ │  │
│  │  │  └──────────────────────────────────────┘ │ │  │
│  │  │                                            │ │  │
│  │  │  ┌──────────────────────────────────────┐ │ │  │
│  │  │  │   ContainerLab Networks              │ │ │  │
│  │  │  │   (Custom bridge networks)           │ │ │  │
│  │  │  │                                      │ │ │  │
│  │  │  │  clab-net-1: 172.20.0.0/24          │ │ │  │
│  │  │  │  clab-net-2: 172.21.0.0/24          │ │ │  │
│  │  │  │  ...                                 │ │ │  │
│  │  │  └──────────────────────────────────────┘ │ │  │
│  │  └────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  Public IP: x.x.x.x                                    │
│  NSG: Allows outbound to Internet and VNET            │
└─────────────────────────────────────────────────────────┘
                        │
                        │ Internet Gateway
                        ▼
                   Internet / Azure Services
```

### With VNET Peering

```
┌─────────────────────────────────────┐     ┌─────────────────────────────────────┐
│   ContainerLab VNET                 │     │   Application VNET                  │
│   10.0.0.0/16                       │     │   10.1.0.0/16                       │
│                                     │     │                                     │
│  ┌───────────────────────────────┐ │     │ ┌───────────────────────────────┐  │
│  │ ContainerLab VM               │ │     │ │ App Service                   │  │
│  │ 10.0.0.4                      │ │     │ │ 10.1.0.5                      │  │
│  │                               │ │     │ │                               │  │
│  │ Containers: 172.17.0.0/16    │ │     │ │ Database: 10.1.1.10          │  │
│  └───────────────────────────────┘ │     │ └───────────────────────────────┘  │
│                                     │     │                                     │
└─────────────────────────────────────┘     └─────────────────────────────────────┘
                │                                           │
                │         VNET Peering (bidirectional)      │
                └───────────────────────────────────────────┘
```

## IP Forwarding Configuration

### VM-Level IP Forwarding

IP forwarding is already enabled in the ARM template:

```json
{
  "type": "Microsoft.Network/networkInterfaces",
  "properties": {
    "enableIPForwarding": true
  }
}
```

### OS-Level IP Forwarding

The setup script automatically enables IP forwarding in the Linux kernel:

```bash
# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1

# Make it persistent
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" | sudo tee -a /etc/sysctl.conf
```

### NAT Configuration

NAT is configured to allow containers to access external networks:

```bash
# Enable NAT for Docker networks
sudo iptables -t nat -A POSTROUTING -s 172.17.0.0/16 -o eth0 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -s 172.20.0.0/14 -o eth0 -j MASQUERADE

# Save iptables rules
sudo apt-get install -y iptables-persistent
sudo netfilter-persistent save
```

## VNET Peering

### Creating VNET Peering

To enable communication between ContainerLab containers and resources in another VNET:

#### 1. Create Peering from ContainerLab VNET to Target VNET

```bash
# Set variables
CONTAINERLAB_VNET="portnox-containerlab-vnet"
CONTAINERLAB_RG="portnox-containerlab-rg"
TARGET_VNET="app-vnet"
TARGET_RG="app-rg"

# Create peering from ContainerLab to Target
az network vnet peering create \
  --name containerlab-to-app \
  --resource-group $CONTAINERLAB_RG \
  --vnet-name $CONTAINERLAB_VNET \
  --remote-vnet $(az network vnet show --resource-group $TARGET_RG --name $TARGET_VNET --query id -o tsv) \
  --allow-vnet-access \
  --allow-forwarded-traffic
```

#### 2. Create Reverse Peering from Target VNET to ContainerLab VNET

```bash
# Create peering from Target to ContainerLab
az network vnet peering create \
  --name app-to-containerlab \
  --resource-group $TARGET_RG \
  --vnet-name $TARGET_VNET \
  --remote-vnet $(az network vnet show --resource-group $CONTAINERLAB_RG --name $CONTAINERLAB_VNET --query id -o tsv) \
  --allow-vnet-access \
  --allow-forwarded-traffic
```

#### 3. Verify Peering Status

```bash
# Check peering status
az network vnet peering list \
  --resource-group $CONTAINERLAB_RG \
  --vnet-name $CONTAINERLAB_VNET \
  --output table

# Should show "Connected" status
```

### Peering with Gateway Transit

If you have a VPN Gateway or ExpressRoute in another VNET and want containers to access on-premises networks:

```bash
# Create peering with gateway transit
az network vnet peering create \
  --name containerlab-to-hub \
  --resource-group $CONTAINERLAB_RG \
  --vnet-name $CONTAINERLAB_VNET \
  --remote-vnet $(az network vnet show --resource-group hub-rg --name hub-vnet --query id -o tsv) \
  --allow-vnet-access \
  --allow-forwarded-traffic \
  --use-remote-gateways

# Hub VNET peering (with gateway transit enabled)
az network vnet peering create \
  --name hub-to-containerlab \
  --resource-group hub-rg \
  --vnet-name hub-vnet \
  --remote-vnet $(az network vnet show --resource-group $CONTAINERLAB_RG --name $CONTAINERLAB_VNET --query id -o tsv) \
  --allow-vnet-access \
  --allow-forwarded-traffic \
  --allow-gateway-transit
```

## Route Tables

### Custom Route Tables for Advanced Routing

For more complex routing scenarios, create custom route tables:

#### 1. Create Route Table

```bash
# Create route table
az network route-table create \
  --name containerlab-routes \
  --resource-group $CONTAINERLAB_RG \
  --location eastus
```

#### 2. Add Routes

```bash
# Route to on-premises network via VPN Gateway
az network route-table route create \
  --name to-onprem \
  --resource-group $CONTAINERLAB_RG \
  --route-table-name containerlab-routes \
  --address-prefix 192.168.0.0/16 \
  --next-hop-type VirtualNetworkGateway

# Route to another VNET
az network route-table route create \
  --name to-app-vnet \
  --resource-group $CONTAINERLAB_RG \
  --route-table-name containerlab-routes \
  --address-prefix 10.1.0.0/16 \
  --next-hop-type VnetPeering

# Route to Azure Firewall
az network route-table route create \
  --name to-firewall \
  --resource-group $CONTAINERLAB_RG \
  --route-table-name containerlab-routes \
  --address-prefix 0.0.0.0/0 \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address 10.2.0.4
```

#### 3. Associate Route Table with Subnet

```bash
az network vnet subnet update \
  --resource-group $CONTAINERLAB_RG \
  --vnet-name $CONTAINERLAB_VNET \
  --name containerlab-subnet \
  --route-table containerlab-routes
```

## Container Networking

### Docker Network Configuration

ContainerLab creates custom bridge networks for each topology. To ensure proper routing:

#### 1. Verify Docker Networks

```bash
# List Docker networks
docker network ls

# Inspect a ContainerLab network
docker network inspect clab-<topology-name>
```

#### 2. Configure Container DNS

For containers to resolve Azure private DNS zones:

```bash
# Create Docker daemon configuration
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "dns": ["168.63.129.16", "8.8.8.8"],
  "dns-search": ["azure.com"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# Restart Docker
sudo systemctl restart docker
```

#### 3. Custom Bridge Networks

For specific routing requirements, create custom networks:

```bash
# Create custom network with specific subnet
docker network create \
  --driver bridge \
  --subnet 172.25.0.0/24 \
  --gateway 172.25.0.1 \
  --opt "com.docker.network.bridge.name"="clab-custom" \
  clab-custom-network
```

### ContainerLab Network Configuration

In your `.clab.yml` files, you can specify custom networks:

```yaml
topology:
  defaults:
    network-mode: bridge
  
  nodes:
    router1:
      kind: linux
      image: alpine:latest
      network-mode: bridge
      # Container will use default Docker bridge
    
    router2:
      kind: linux
      image: alpine:latest
      network-mode: container:router1
      # Container shares network namespace with router1
```

## Testing Connectivity

### Test Internet Connectivity

```bash
# From the VM
ping -c 3 8.8.8.8
curl -I https://www.google.com

# From a container
docker exec <container-name> ping -c 3 8.8.8.8
docker exec <container-name> curl -I https://www.google.com
```

### Test VNET Peering

```bash
# From the VM to peered VNET
ping -c 3 10.1.0.5

# From a container to peered VNET
docker exec <container-name> ping -c 3 10.1.0.5
```

### Test Azure Service Endpoints

```bash
# Test Azure Storage
docker exec <container-name> curl -I https://<storage-account>.blob.core.windows.net

# Test Azure SQL
docker exec <container-name> nc -zv <sql-server>.database.windows.net 1433
```

### Test DNS Resolution

```bash
# From container
docker exec <container-name> nslookup google.com
docker exec <container-name> nslookup <private-endpoint>.privatelink.database.windows.net
```

### Comprehensive Connectivity Test Script

Create a test script `/usr/local/bin/test-container-connectivity.sh`:

```bash
#!/bin/bash

CONTAINER_NAME="${1:-}"

if [ -z "$CONTAINER_NAME" ]; then
    echo "Usage: test-container-connectivity.sh <container-name>"
    exit 1
fi

echo "Testing connectivity from container: $CONTAINER_NAME"
echo "=================================================="

# Test Internet
echo ""
echo "1. Testing Internet connectivity..."
docker exec $CONTAINER_NAME ping -c 3 8.8.8.8 && echo "✓ Internet (ICMP)" || echo "✗ Internet (ICMP)"
docker exec $CONTAINER_NAME curl -s -I https://www.google.com > /dev/null && echo "✓ Internet (HTTPS)" || echo "✗ Internet (HTTPS)"

# Test DNS
echo ""
echo "2. Testing DNS resolution..."
docker exec $CONTAINER_NAME nslookup google.com > /dev/null && echo "✓ Public DNS" || echo "✗ Public DNS"
docker exec $CONTAINER_NAME nslookup azure.microsoft.com > /dev/null && echo "✓ Azure DNS" || echo "✗ Azure DNS"

# Test Azure Services
echo ""
echo "3. Testing Azure service connectivity..."
docker exec $CONTAINER_NAME curl -s -I https://management.azure.com > /dev/null && echo "✓ Azure Management API" || echo "✗ Azure Management API"

# Test VNET Gateway (if configured)
echo ""
echo "4. Testing VNET gateway..."
GATEWAY_IP=$(ip route | grep default | awk '{print $3}')
docker exec $CONTAINER_NAME ping -c 3 $GATEWAY_IP && echo "✓ VNET Gateway" || echo "✗ VNET Gateway"

# Test Container-to-Container
echo ""
echo "5. Testing container-to-container connectivity..."
OTHER_CONTAINERS=$(docker ps --format '{{.Names}}' | grep -v $CONTAINER_NAME | head -1)
if [ -n "$OTHER_CONTAINERS" ]; then
    OTHER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $OTHER_CONTAINERS)
    docker exec $CONTAINER_NAME ping -c 3 $OTHER_IP && echo "✓ Container-to-Container" || echo "✗ Container-to-Container"
else
    echo "⚠ No other containers running"
fi

echo ""
echo "=================================================="
echo "Connectivity test complete"
```

Make it executable:

```bash
sudo chmod +x /usr/local/bin/test-container-connectivity.sh
```

## Troubleshooting

### Issue: Containers Cannot Reach Internet

**Symptoms:**
- Containers can ping VM gateway but not external IPs
- DNS resolution fails

**Solutions:**

1. **Check IP Forwarding:**
   ```bash
   # Verify kernel IP forwarding
   sysctl net.ipv4.ip_forward
   # Should return: net.ipv4.ip_forward = 1
   
   # If not enabled
   sudo sysctl -w net.ipv4.ip_forward=1
   ```

2. **Check NAT Rules:**
   ```bash
   # List NAT rules
   sudo iptables -t nat -L -n -v
   
   # Should see MASQUERADE rules for Docker networks
   # If missing, add them:
   sudo iptables -t nat -A POSTROUTING -s 172.17.0.0/16 -o eth0 -j MASQUERADE
   ```

3. **Check NSG Rules:**
   ```bash
   # Verify outbound rules allow Internet
   az network nsg rule list \
     --resource-group $CONTAINERLAB_RG \
     --nsg-name portnox-containerlab-nsg \
     --query "[?direction=='Outbound']" \
     --output table
   ```

4. **Check Docker DNS:**
   ```bash
   # Verify Docker DNS configuration
   docker inspect <container-name> | jq '.[0].HostConfig.Dns'
   
   # Should include Azure DNS: 168.63.129.16
   ```

### Issue: Containers Cannot Reach Peered VNET

**Symptoms:**
- VM can reach peered VNET but containers cannot
- Routing appears correct but traffic doesn't flow

**Solutions:**

1. **Verify VNET Peering Status:**
   ```bash
   az network vnet peering show \
     --resource-group $CONTAINERLAB_RG \
     --vnet-name $CONTAINERLAB_VNET \
     --name containerlab-to-app \
     --query peeringState
   # Should return: "Connected"
   ```

2. **Check Allow Forwarded Traffic:**
   ```bash
   az network vnet peering show \
     --resource-group $CONTAINERLAB_RG \
     --vnet-name $CONTAINERLAB_VNET \
     --name containerlab-to-app \
     --query allowForwardedTraffic
   # Should return: true
   ```

3. **Verify Route Tables:**
   ```bash
   # Check effective routes on VM NIC
   az network nic show-effective-route-table \
     --resource-group $CONTAINERLAB_RG \
     --name portnox-containerlab-nic \
     --output table
   ```

4. **Check Target VNET NSG:**
   ```bash
   # Ensure target VNET allows traffic from ContainerLab subnet
   # Source: 10.0.0.0/24 (ContainerLab subnet)
   # Or: 172.17.0.0/16 (Docker bridge network)
   ```

### Issue: DNS Resolution Fails

**Symptoms:**
- Containers cannot resolve domain names
- `nslookup` or `dig` commands fail

**Solutions:**

1. **Check Docker DNS Configuration:**
   ```bash
   cat /etc/docker/daemon.json
   # Should include: "dns": ["168.63.129.16", "8.8.8.8"]
   ```

2. **Restart Docker:**
   ```bash
   sudo systemctl restart docker
   ```

3. **Test DNS from VM:**
   ```bash
   nslookup google.com
   # If VM DNS works but container DNS doesn't, it's a Docker config issue
   ```

4. **Check Container DNS:**
   ```bash
   docker exec <container-name> cat /etc/resolv.conf
   # Should show nameservers: 168.63.129.16, 8.8.8.8
   ```

### Issue: High Latency or Packet Loss

**Symptoms:**
- Slow network performance
- Intermittent connectivity

**Solutions:**

1. **Check Network Interface:**
   ```bash
   # Verify accelerated networking is enabled
   az network nic show \
     --resource-group $CONTAINERLAB_RG \
     --name portnox-containerlab-nic \
     --query enableAcceleratedNetworking
   # Should return: true
   ```

2. **Monitor Network Traffic:**
   ```bash
   # Install monitoring tools
   sudo apt-get install -y iftop nethogs
   
   # Monitor interface
   sudo iftop -i eth0
   ```

3. **Check VM Size:**
   ```bash
   # Ensure VM size supports required network bandwidth
   # D4s_v3: 2 Gbps
   # D8s_v3: 4 Gbps
   # D16s_v3: 8 Gbps
   ```

### Issue: Cannot Access Azure Private Endpoints

**Symptoms:**
- Cannot connect to Azure services via private endpoints
- DNS resolves to public IP instead of private IP

**Solutions:**

1. **Configure Private DNS Zones:**
   ```bash
   # Link private DNS zone to ContainerLab VNET
   az network private-dns link vnet create \
     --resource-group dns-rg \
     --zone-name privatelink.database.windows.net \
     --name containerlab-link \
     --virtual-network $CONTAINERLAB_VNET \
     --registration-enabled false
   ```

2. **Verify DNS Resolution:**
   ```bash
   # Should resolve to private IP (10.x.x.x)
   nslookup <service>.privatelink.database.windows.net
   ```

3. **Check NSG Rules:**
   ```bash
   # Ensure NSG allows traffic to private endpoint subnet
   ```

## Best Practices

1. **Use VNET Peering for Production:**
   - More secure than public internet
   - Lower latency
   - No data transfer charges within same region

2. **Implement Network Segmentation:**
   - Use separate subnets for different lab types
   - Apply NSG rules at subnet level

3. **Monitor Network Traffic:**
   - Enable Network Watcher
   - Use flow logs for troubleshooting
   - Set up alerts for unusual traffic patterns

4. **Document Custom Routes:**
   - Maintain documentation of all custom routes
   - Use tags to identify route purposes

5. **Test Before Production:**
   - Always test connectivity in dev environment
   - Verify all routes and peerings work as expected

6. **Use Azure Bastion:**
   - Avoid exposing SSH directly to internet
   - Use Azure Bastion for secure VM access

## Additional Resources

- **Azure Virtual Network Documentation:** https://docs.microsoft.com/azure/virtual-network/
- **VNET Peering:** https://docs.microsoft.com/azure/virtual-network/virtual-network-peering-overview
- **Docker Networking:** https://docs.docker.com/network/
- **ContainerLab Networking:** https://containerlab.dev/manual/network/
- **Azure Network Watcher:** https://docs.microsoft.com/azure/network-watcher/

## Summary

The ContainerLab VM is pre-configured with:
- ✅ IP forwarding enabled at VM and OS level
- ✅ NAT configured for container internet access
- ✅ NSG rules allowing outbound traffic
- ✅ Support for VNET peering
- ✅ Azure DNS integration

For most use cases, containers will have internet access and can communicate with peered VNETs without additional configuration. For advanced scenarios, use the route tables and custom network configurations described in this guide.
