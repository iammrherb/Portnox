# EVE-NG to ContainerLab Conversion Guide

This guide provides comprehensive instructions for converting EVE-NG QCOW2 images to ContainerLab-compatible Docker containers using VRNetlab.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [EVE-NG Image Locations](#eve-ng-image-locations)
4. [Conversion Methods](#conversion-methods)
5. [Automated Conversion Script](#automated-conversion-script)
6. [Vendor-Specific Instructions](#vendor-specific-instructions)
7. [Troubleshooting](#troubleshooting)

---

## Overview

EVE-NG stores network device images as QCOW2 files which can be converted to Docker containers using VRNetlab. This allows you to migrate your EVE-NG labs to ContainerLab while preserving your existing vendor images.

### Benefits of Converting to ContainerLab

- **Better Performance**: Native Docker containers vs full VM virtualization
- **Lower Resource Usage**: Containers use less CPU and RAM
- **Faster Boot Times**: Containers start in seconds vs minutes
- **Modern Tooling**: Git-based topology management, CI/CD integration
- **Scalability**: Run more devices on the same hardware

---

## Prerequisites

### On EVE-NG Server

```bash
# SSH access to EVE-NG server
ssh root@eve-ng-server

# Verify images exist
ls -la /opt/unetlab/addons/qemu/
```

### On ContainerLab Server

```bash
# Docker installed
docker --version

# VRNetlab cloned
git clone https://github.com/vrnetlab/vrnetlab.git
cd vrnetlab

# Make and QEMU tools
sudo apt-get install -y make qemu-utils

# Sufficient disk space (10GB+ per image)
df -h
```

---

## EVE-NG Image Locations

EVE-NG stores all QCOW2 images in `/opt/unetlab/addons/qemu/` with vendor-specific subdirectories.

### Common EVE-NG Image Paths

```bash
# Cisco IOS-XRv 9000
/opt/unetlab/addons/qemu/iosxrv9k-7.3.2/virtioa.qcow2

# Cisco IOS-XRv
/opt/unetlab/addons/qemu/iosxrv-6.6.3/virtioa.qcow2

# Cisco CSR 1000v
/opt/unetlab/addons/qemu/csr1000v-17.03.04a/virtioa.qcow2

# Cisco Nexus 9000v
/opt/unetlab/addons/qemu/titanium-d1.10.1.1/virtioa.qcow2

# Juniper vMX
/opt/unetlab/addons/qemu/vmx-20.4R1.12/virtioa.qcow2
/opt/unetlab/addons/qemu/vmx-20.4R1.12/virtiob.qcow2  # PFE image

# Juniper vQFX
/opt/unetlab/addons/qemu/vqfx-20.2R1.10/virtioa.qcow2
/opt/unetlab/addons/qemu/vqfx-20.2R1.10/virtiob.qcow2  # PFE image

# Juniper vSRX
/opt/unetlab/addons/qemu/vsrx-20.4R1.12/virtioa.qcow2

# Arista vEOS
/opt/unetlab/addons/qemu/veos-4.30.0F/virtioa.qcow2

# Palo Alto PAN-OS
/opt/unetlab/addons/qemu/paloalto-10.1.0/virtioa.qcow2

# Fortinet FortiGate
/opt/unetlab/addons/qemu/fortinet-7.2.0/virtioa.qcow2

# Aruba AOS-CX
/opt/unetlab/addons/qemu/aoscx-10.10.1000/virtioa.qcow2

# Dell OS10
/opt/unetlab/addons/qemu/dellos10-10.5.2.4/virtioa.qcow2
```

### List All EVE-NG Images

```bash
# On EVE-NG server
find /opt/unetlab/addons/qemu/ -name "*.qcow2" -type f
```

---

## Conversion Methods

### Method 1: Direct SCP Transfer

**Step 1: Copy image from EVE-NG**
```bash
# From ContainerLab server
scp root@eve-ng-server:/opt/unetlab/addons/qemu/iosxrv9k-7.3.2/virtioa.qcow2 /tmp/xrv9k-7.3.2.qcow2
```

**Step 2: Build with VRNetlab**
```bash
cd vrnetlab/xrv9k
cp /tmp/xrv9k-7.3.2.qcow2 .
make docker-image
```

**Step 3: Verify image**
```bash
docker images | grep vrnetlab/vr-xrv9k
```

### Method 2: Mount EVE-NG Filesystem (NFS)

**Step 1: Export EVE-NG filesystem**
```bash
# On EVE-NG server
apt-get install -y nfs-kernel-server
echo "/opt/unetlab/addons/qemu *(ro,sync,no_subtree_check)" >> /etc/exports
exportfs -a
systemctl restart nfs-kernel-server
```

**Step 2: Mount on ContainerLab server**
```bash
# On ContainerLab server
apt-get install -y nfs-common
mkdir -p /mnt/eve-ng
mount eve-ng-server:/opt/unetlab/addons/qemu /mnt/eve-ng
```

**Step 3: Build directly from mount**
```bash
cd vrnetlab/xrv9k
cp /mnt/eve-ng/iosxrv9k-7.3.2/virtioa.qcow2 .
make docker-image
```

### Method 3: Rsync (Bulk Transfer)

```bash
# Sync all EVE-NG images
rsync -avz --progress root@eve-ng-server:/opt/unetlab/addons/qemu/ /data/eve-ng-images/

# Build images from local copy
cd vrnetlab/xrv9k
cp /data/eve-ng-images/iosxrv9k-7.3.2/virtioa.qcow2 .
make docker-image
```

---

## Automated Conversion Script

Save this script as `/data/scripts/convert-eve-ng-images.sh`:

```bash
#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root or with sudo"
    exit 1
fi

EVE_SERVER="${1:-}"
VRNETLAB_DIR="${2:-/opt/vrnetlab}"

if [ -z "$EVE_SERVER" ]; then
    log_error "Usage: $0 <eve-ng-server-ip> [vrnetlab-directory]"
    log_error "Example: $0 192.168.1.100 /opt/vrnetlab"
    exit 1
fi

log_info "EVE-NG to ContainerLab Image Conversion"
log_info "EVE-NG Server: $EVE_SERVER"
log_info "VRNetlab Directory: $VRNETLAB_DIR"
echo ""

if [ ! -d "$VRNETLAB_DIR" ]; then
    log_error "VRNetlab directory not found: $VRNETLAB_DIR"
    log_info "Cloning VRNetlab..."
    git clone https://github.com/vrnetlab/vrnetlab.git "$VRNETLAB_DIR"
fi

log_info "Testing SSH connection to EVE-NG server..."
if ! ssh -o ConnectTimeout=5 root@$EVE_SERVER "echo 'Connection successful'" > /dev/null 2>&1; then
    log_error "Cannot connect to EVE-NG server via SSH"
    log_info "Please ensure:"
    log_info "  1. EVE-NG server is accessible"
    log_info "  2. SSH key is configured (ssh-copy-id root@$EVE_SERVER)"
    exit 1
fi
log_success "SSH connection successful"

log_info "Scanning EVE-NG for available images..."
EVE_IMAGES=$(ssh root@$EVE_SERVER "find /opt/unetlab/addons/qemu/ -name 'virtioa.qcow2' -type f")

if [ -z "$EVE_IMAGES" ]; then
    log_warning "No QCOW2 images found on EVE-NG server"
    exit 0
fi

echo "$EVE_IMAGES" | while read -r image_path; do
    vendor_dir=$(dirname "$image_path")
    vendor_name=$(basename "$vendor_dir")
    
    log_info "Found image: $vendor_name"
    
    case "$vendor_name" in
        iosxrv9k-*)
            vrnetlab_vendor="xrv9k"
            ;;
        iosxrv-*)
            vrnetlab_vendor="xrv"
            ;;
        csr1000v-*)
            vrnetlab_vendor="csr"
            ;;
        titanium-*|n9kv-*)
            vrnetlab_vendor="n9kv"
            ;;
        vmx-*)
            vrnetlab_vendor="vmx"
            ;;
        vqfx-*)
            vrnetlab_vendor="vqfx"
            ;;
        vsrx-*)
            vrnetlab_vendor="vsrx"
            ;;
        veos-*)
            vrnetlab_vendor="veos"
            ;;
        paloalto-*)
            vrnetlab_vendor="pan"
            ;;
        fortinet-*)
            vrnetlab_vendor="fortios"
            ;;
        aoscx-*)
            vrnetlab_vendor="aoscx"
            ;;
        dellos10-*)
            vrnetlab_vendor="dellos10"
            ;;
        *)
            log_warning "Unknown vendor: $vendor_name - skipping"
            continue
            ;;
    esac
    
    if [ ! -d "$VRNETLAB_DIR/$vrnetlab_vendor" ]; then
        log_warning "VRNetlab directory not found for $vrnetlab_vendor - skipping"
        continue
    fi
    
    log_info "Converting $vendor_name to vrnetlab/$vrnetlab_vendor..."
    
    temp_image="/tmp/${vendor_name}.qcow2"
    log_info "Downloading image from EVE-NG..."
    scp root@$EVE_SERVER:$image_path "$temp_image"
    
    if [ "$vrnetlab_vendor" = "vmx" ] || [ "$vrnetlab_vendor" = "vqfx" ]; then
        pfe_image="${image_path/virtioa/virtiob}"
        if ssh root@$EVE_SERVER "[ -f $pfe_image ]"; then
            log_info "Downloading PFE image..."
            scp root@$EVE_SERVER:$pfe_image "/tmp/${vendor_name}-pfe.qcow2"
            cp "/tmp/${vendor_name}-pfe.qcow2" "$VRNETLAB_DIR/$vrnetlab_vendor/"
        fi
    fi
    
    cp "$temp_image" "$VRNETLAB_DIR/$vrnetlab_vendor/"
    
    log_info "Building Docker image..."
    cd "$VRNETLAB_DIR/$vrnetlab_vendor"
    if make docker-image; then
        log_success "✓ Successfully built vrnetlab/vr-$vrnetlab_vendor"
    else
        log_error "✗ Failed to build vrnetlab/vr-$vrnetlab_vendor"
    fi
    
    rm -f "$temp_image"
    rm -f "/tmp/${vendor_name}-pfe.qcow2"
    
    cd - > /dev/null
    echo ""
done

log_success "Conversion complete!"
echo ""
log_info "Available VRNetlab images:"
docker images | grep vrnetlab

exit 0
```

### Usage

```bash
# Make script executable
chmod +x /data/scripts/convert-eve-ng-images.sh

# Run conversion
sudo /data/scripts/convert-eve-ng-images.sh 192.168.1.100

# With custom VRNetlab directory
sudo /data/scripts/convert-eve-ng-images.sh 192.168.1.100 /opt/vrnetlab
```

---

## Vendor-Specific Instructions

### Cisco IOS-XRv 9000

```bash
# EVE-NG path
/opt/unetlab/addons/qemu/iosxrv9k-7.3.2/virtioa.qcow2

# Copy to ContainerLab
scp root@eve-ng:/opt/unetlab/addons/qemu/iosxrv9k-7.3.2/virtioa.qcow2 /tmp/

# Build with VRNetlab
cd vrnetlab/xrv9k
cp /tmp/virtioa.qcow2 ./iosxrv-k9-demo-7.3.2.qcow2
make docker-image

# Result
docker images | grep vr-xrv9k
```

### Cisco Nexus 9000v

```bash
# EVE-NG path
/opt/unetlab/addons/qemu/titanium-d1.10.1.1/virtioa.qcow2

# Copy to ContainerLab
scp root@eve-ng:/opt/unetlab/addons/qemu/titanium-d1.10.1.1/virtioa.qcow2 /tmp/

# Build with VRNetlab
cd vrnetlab/n9kv
cp /tmp/virtioa.qcow2 ./nexus9300v.10.1.1.qcow2
make docker-image

# Result
docker images | grep vr-n9kv
```

### Juniper vMX (Requires 2 Images)

```bash
# EVE-NG paths
/opt/unetlab/addons/qemu/vmx-20.4R1.12/virtioa.qcow2  # RE
/opt/unetlab/addons/qemu/vmx-20.4R1.12/virtiob.qcow2  # PFE

# Copy both images
scp root@eve-ng:/opt/unetlab/addons/qemu/vmx-20.4R1.12/virtioa.qcow2 /tmp/vmx-re.qcow2
scp root@eve-ng:/opt/unetlab/addons/qemu/vmx-20.4R1.12/virtiob.qcow2 /tmp/vmx-pfe.qcow2

# Build with VRNetlab
cd vrnetlab/vmx
cp /tmp/vmx-re.qcow2 ./vmx-20.4R1.12-re.qcow2
cp /tmp/vmx-pfe.qcow2 ./vmx-20.4R1.12-pfe.qcow2
make docker-image

# Result
docker images | grep vr-vmx
```

### Juniper vQFX (Requires 2 Images)

```bash
# EVE-NG paths
/opt/unetlab/addons/qemu/vqfx-20.2R1.10/virtioa.qcow2  # RE
/opt/unetlab/addons/qemu/vqfx-20.2R1.10/virtiob.qcow2  # PFE

# Copy both images
scp root@eve-ng:/opt/unetlab/addons/qemu/vqfx-20.2R1.10/virtioa.qcow2 /tmp/vqfx-re.qcow2
scp root@eve-ng:/opt/unetlab/addons/qemu/vqfx-20.2R1.10/virtiob.qcow2 /tmp/vqfx-pfe.qcow2

# Build with VRNetlab
cd vrnetlab/vqfx
cp /tmp/vqfx-re.qcow2 ./vqfx-20.2R1.10-re.qcow2
cp /tmp/vqfx-pfe.qcow2 ./vqfx-20.2R1.10-pfe.qcow2
make docker-image

# Result
docker images | grep vr-vqfx
```

### Arista vEOS

```bash
# EVE-NG path
/opt/unetlab/addons/qemu/veos-4.30.0F/virtioa.qcow2

# Copy to ContainerLab
scp root@eve-ng:/opt/unetlab/addons/qemu/veos-4.30.0F/virtioa.qcow2 /tmp/

# Build with VRNetlab
cd vrnetlab/veos
cp /tmp/virtioa.qcow2 ./vEOS-lab-4.30.0F.qcow2
make docker-image

# Result
docker images | grep vr-veos
```

### Palo Alto PAN-OS

```bash
# EVE-NG path
/opt/unetlab/addons/qemu/paloalto-10.1.0/virtioa.qcow2

# Copy to ContainerLab
scp root@eve-ng:/opt/unetlab/addons/qemu/paloalto-10.1.0/virtioa.qcow2 /tmp/

# Build with VRNetlab
cd vrnetlab/pan
cp /tmp/virtioa.qcow2 ./PA-VM-10.1.0.qcow2
make docker-image

# Result
docker images | grep vr-pan
```

### Fortinet FortiGate

```bash
# EVE-NG path
/opt/unetlab/addons/qemu/fortinet-7.2.0/virtioa.qcow2

# Copy to ContainerLab
scp root@eve-ng:/opt/unetlab/addons/qemu/fortinet-7.2.0/virtioa.qcow2 /tmp/

# Build with VRNetlab
cd vrnetlab/fortios
cp /tmp/virtioa.qcow2 ./FGT_VM64-v7.2.0.F-build1157-FORTINET.out.kvm.qcow2
make docker-image

# Result
docker images | grep vr-fortios
```

---

## Troubleshooting

### Issue: SSH Connection Failed

**Error:**
```
Cannot connect to EVE-NG server via SSH
```

**Solution:**
```bash
# Set up SSH key
ssh-keygen -t rsa -b 4096
ssh-copy-id root@eve-ng-server

# Test connection
ssh root@eve-ng-server "echo 'Success'"
```

### Issue: Image Not Found

**Error:**
```
No such file or directory: /opt/unetlab/addons/qemu/...
```

**Solution:**
```bash
# List all available images on EVE-NG
ssh root@eve-ng-server "find /opt/unetlab/addons/qemu/ -name '*.qcow2'"

# Verify exact path
ssh root@eve-ng-server "ls -la /opt/unetlab/addons/qemu/iosxrv9k-7.3.2/"
```

### Issue: VRNetlab Build Failed

**Error:**
```
make: *** [docker-image] Error 1
```

**Solution:**
```bash
# Check QCOW2 file is valid
qemu-img info image.qcow2

# Check disk space
df -h

# Check Docker is running
docker ps

# Try building with verbose output
make docker-image VERBOSE=1
```

### Issue: Insufficient Disk Space

**Error:**
```
No space left on device
```

**Solution:**
```bash
# Check disk usage
df -h

# Clean up Docker
docker system prune -a

# Remove old images
docker rmi $(docker images -q -f dangling=true)
```

### Issue: Image Too Large

**Error:**
```
Image size exceeds available space
```

**Solution:**
```bash
# Compress QCOW2 image
qemu-img convert -O qcow2 -c input.qcow2 output.qcow2

# Use compressed image for VRNetlab build
cd vrnetlab/<vendor>
cp output.qcow2 .
make docker-image
```

---

## Best Practices

1. **Backup EVE-NG Images**: Always keep a backup of original EVE-NG images
2. **Test Before Production**: Test converted images in a lab environment first
3. **Document Versions**: Keep track of which EVE-NG version maps to which Docker image
4. **Automate Conversion**: Use the automated script for bulk conversions
5. **Monitor Resources**: Ensure sufficient disk space and memory during conversion
6. **Verify Images**: Test each converted image before deploying to production labs

---

## Additional Resources

- **VRNetlab Documentation**: https://github.com/vrnetlab/vrnetlab
- **EVE-NG Documentation**: https://www.eve-ng.net/index.php/documentation/
- **ContainerLab Documentation**: https://containerlab.dev/
- **QEMU Documentation**: https://www.qemu.org/documentation/

---

**Last Updated**: 2025-10-18
