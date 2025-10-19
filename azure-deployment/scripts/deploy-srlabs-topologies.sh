#!/bin/bash


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

log_info "Starting SR Labs topology deployment..."
echo ""

SRLABS_DIR="/data/srlabs"
mkdir -p "$SRLABS_DIR"
cd "$SRLABS_DIR" || exit 1

declare -a SRLABS_REPOS=(
    "srl-telemetry-lab"
    "opergroup-lab"
    "multivendor-evpn-lab"
    "nokia-evpn-lab"
    "srl-features-lab"
    "nokia-segment-routing-lab"
    "srl-sros-telemetry-lab"
    "srl-elk-lab"
    "srl-splunk-lab"
    "intent-based-ansible-lab"
    "sros-anysec-lab"
    "srl-k8s-anycast-lab"
    "srl-evpn-mh-lab"
    "sros-anysec-macsec-lab"
    "freeradius-lab"
    "srlinux-vlan-handling-lab"
    "netbox-nrx-clab"
    "srlinux-eos-vlan-handling-lab"
    "nokia-basic-dci-lab"
    "clab-workshop"
    "logging-with-loki-lab"
    "http-client-server-lab"
    "srl-acl-lab"
    "srl-rt5-l3evpn-basics-lab"
    "srl-netbox-demo"
    "srl-mirroring-lab"
    "srl-bfd-lab"
    "srlinux-getting-started"
    "srl-snmp-framework-lab"
    "srl-l3evpn-mh-lab"
)

log_info "Found ${#SRLABS_REPOS[@]} SR Labs repositories with topologies"
echo ""

success_count=0
failed_count=0
skipped_count=0

for repo in "${SRLABS_REPOS[@]}"; do
    log_info "Processing repository: $repo"
    
    if [ ! -d "$repo" ]; then
        log_info "Cloning $repo..."
        if git clone "https://github.com/srl-labs/$repo.git" 2>/dev/null; then
            log_success "✓ Cloned $repo"
        else
            log_error "✗ Failed to clone $repo"
            ((failed_count++))
            continue
        fi
    else
        log_info "Repository $repo already exists, pulling latest changes..."
        cd "$repo" && git pull origin main 2>/dev/null || git pull origin master 2>/dev/null
        cd "$SRLABS_DIR"
    fi
    
    cd "$repo" || continue
    
    topology_files=$(find . -maxdepth 2 -name "*.clab.yml" -o -name "*.clab.yaml" 2>/dev/null)
    
    if [ -z "$topology_files" ]; then
        log_warning "No topology files found in $repo"
        ((skipped_count++))
        cd "$SRLABS_DIR"
        continue
    fi
    
    for topology in $topology_files; do
        topology_name=$(basename "$topology")
        log_info "Deploying topology: $topology_name"
        
        if grep -q "vrnetlab" "$topology"; then
            log_warning "Topology requires VRNetlab images (skipping deployment, but keeping file)"
            ((skipped_count++))
            continue
        fi
        
        if grep -q "ceos" "$topology"; then
            log_warning "Topology requires Arista cEOS images (skipping deployment, but keeping file)"
            ((skipped_count++))
            continue
        fi
        
        if containerlab deploy -t "$topology" --reconfigure 2>&1 | tee /tmp/clab-deploy-$repo.log; then
            log_success "✓ Deployed $topology_name from $repo"
            ((success_count++))
        else
            log_error "✗ Failed to deploy $topology_name from $repo"
            log_info "Check /tmp/clab-deploy-$repo.log for details"
            ((failed_count++))
        fi
    done
    
    cd "$SRLABS_DIR"
    echo ""
done

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║              SR Labs Topology Deployment Summary                 ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

log_info "Deployment Statistics:"
echo "  Successfully deployed: $success_count"
echo "  Failed: $failed_count"
echo "  Skipped (missing images): $skipped_count"
echo ""

log_info "All SR Labs repositories cloned to: $SRLABS_DIR"
log_info "You can manually deploy topologies that require vendor images after importing them"
echo ""

log_info "Listing all deployed labs:"
containerlab inspect --all

echo ""
log_success "SR Labs topology deployment complete!"

exit 0
