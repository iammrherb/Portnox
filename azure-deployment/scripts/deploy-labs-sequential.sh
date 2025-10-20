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

LABS_DIR="/data/labs"
cd "$LABS_DIR" || exit 1

log_info "Starting sequential lab deployment..."
log_info "Each lab will be deployed, verified, then destroyed to save resources"
echo ""

declare -A lab_results
success_count=0
failed_count=0
skipped_count=0

lab_files=$(find . -maxdepth 1 -name "*.clab.yml" -type f | sort)

for lab_file in $lab_files; do
    lab_name=$(basename "$lab_file")
    
    log_info "═══════════════════════════════════════════════════════════"
    log_info "Processing: $lab_name"
    log_info "═══════════════════════════════════════════════════════════"
    
    if grep -q "vrnetlab/" "$lab_file" || grep -q "ceos:" "$lab_file"; then
        log_warning "Lab requires vendor images (VRNetlab/cEOS) - SKIPPING"
        lab_results["$lab_name"]="SKIPPED (vendor images required)"
        ((skipped_count++))
        echo ""
        continue
    fi
    
    log_info "Deploying $lab_name..."
    if containerlab deploy -t "$lab_file" --reconfigure 2>&1 | tee "/tmp/deploy-$lab_name.log"; then
        log_success "✓ Successfully deployed $lab_name"
        
        log_info "Waiting 10 seconds for containers to stabilize..."
        sleep 10
        
        log_info "Lab status:"
        containerlab inspect -t "$lab_file"
        
        log_info "Destroying $lab_name to free resources..."
        if containerlab destroy -t "$lab_file" --cleanup 2>&1 | tee "/tmp/destroy-$lab_name.log"; then
            log_success "✓ Successfully destroyed $lab_name"
            lab_results["$lab_name"]="SUCCESS (deployed and destroyed)"
            ((success_count++))
        else
            log_error "✗ Failed to destroy $lab_name"
            lab_results["$lab_name"]="PARTIAL (deployed but failed to destroy)"
            ((failed_count++))
        fi
    else
        log_error "✗ Failed to deploy $lab_name"
        log_info "Check /tmp/deploy-$lab_name.log for details"
        lab_results["$lab_name"]="FAILED (deployment error)"
        ((failed_count++))
    fi
    
    echo ""
    log_info "Waiting 5 seconds before next lab..."
    sleep 5
done

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║              Sequential Lab Deployment Summary                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

log_info "Deployment Statistics:"
echo "  Successfully deployed & destroyed: $success_count"
echo "  Failed: $failed_count"
echo "  Skipped (vendor images): $skipped_count"
echo ""

log_info "Detailed Results:"
for lab in "${!lab_results[@]}"; do
    result="${lab_results[$lab]}"
    if [[ "$result" == SUCCESS* ]]; then
        log_success "$lab: $result"
    elif [[ "$result" == SKIPPED* ]]; then
        log_warning "$lab: $result"
    else
        log_error "$lab: $result"
    fi
done

echo ""
log_info "All deployment logs saved to /tmp/deploy-*.log and /tmp/destroy-*.log"
echo ""

if [ $failed_count -eq 0 ]; then
    log_success "All labs deployed successfully!"
    exit 0
else
    log_warning "$failed_count lab(s) failed to deploy"
    exit 1
fi
