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

show_usage() {
    cat <<EOF
╔═══════════════════════════════════════════════════════════════════╗
║              Portnox ContainerLab VM Shutdown Script              ║
╚═══════════════════════════════════════════════════════════════════╝

Usage: $0 [OPTIONS]

Shutdown Options:
  --graceful              Gracefully stop all labs and containers (default)
  --preserve-labs         Stop VM but keep labs running (resume on restart)
  --destroy-labs          Destroy all labs before shutdown
  --quick                 Quick shutdown without stopping containers
  --deallocate            Deallocate VM (saves costs, loses ephemeral IP)
  --stop                  Stop VM (keeps IP, still charges for storage)

Additional Options:
  --backup                Create backup before shutdown
  --no-backup             Skip backup (default)
  --schedule <time>       Schedule shutdown at specific time (HH:MM format)
  --help                  Show this help message

Examples:
  $0 --graceful --backup

  $0 --quick

  $0 --destroy-labs --deallocate

  $0 --graceful --schedule 02:00

  $0 --preserve-labs --stop

Cost Savings:
  --deallocate: Saves ~70% of costs (only pay for storage)
  --stop:       Saves ~30% of costs (still pay for compute reservation)

EOF
}

backup_data() {
    log_info "Creating backup of lab data..."
    
    BACKUP_DIR="/data/backups"
    BACKUP_FILE="$BACKUP_DIR/containerlab-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    mkdir -p "$BACKUP_DIR"
    
    tar -czf "$BACKUP_FILE" \
        /data/labs \
        /data/configs \
        /data/images 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "Backup created: $BACKUP_FILE"
        log_info "Backup size: $(du -h $BACKUP_FILE | cut -f1)"
    else
        log_error "Backup failed"
        return 1
    fi
}

stop_labs_graceful() {
    log_info "Gracefully stopping all ContainerLab deployments..."
    
    LABS=$(containerlab inspect --all 2>/dev/null | grep -oP '(?<=name: )[^ ]+' || true)
    
    if [ -z "$LABS" ]; then
        log_info "No running labs found"
        return 0
    fi
    
    for LAB in $LABS; do
        log_info "Stopping lab: $LAB"
        containerlab destroy --topo "$LAB" --cleanup 2>/dev/null || log_warning "Failed to stop $LAB"
    done
    
    log_success "All labs stopped gracefully"
}

destroy_all_labs() {
    log_warning "Destroying all ContainerLab deployments..."
    
    LABS=$(containerlab inspect --all 2>/dev/null | grep -oP '(?<=name: )[^ ]+' || true)
    
    if [ -z "$LABS" ]; then
        log_info "No running labs found"
        return 0
    fi
    
    for LAB in $LABS; do
        log_info "Destroying lab: $LAB"
        containerlab destroy --topo "$LAB" --cleanup --force 2>/dev/null || log_warning "Failed to destroy $LAB"
    done
    
    log_info "Cleaning up Docker resources..."
    docker system prune -af --volumes 2>/dev/null || true
    
    log_success "All labs destroyed"
}

stop_containers() {
    log_info "Stopping all Docker containers..."
    
    CONTAINERS=$(docker ps -q)
    
    if [ -z "$CONTAINERS" ]; then
        log_info "No running containers found"
        return 0
    fi
    
    docker stop $(docker ps -q) 2>/dev/null || log_warning "Some containers failed to stop"
    
    log_success "All containers stopped"
}

preserve_labs() {
    log_info "Preserving lab state for resume on restart..."
    
    containerlab inspect --all > /data/lab-state-$(date +%Y%m%d-%H%M%S).json 2>/dev/null || true
    
    log_success "Lab state preserved"
}

schedule_shutdown() {
    local SCHEDULE_TIME=$1
    
    log_info "Scheduling shutdown at $SCHEDULE_TIME..."
    
    if ! command -v at &> /dev/null; then
        log_error "The 'at' command is not installed. Installing..."
        apt-get update && apt-get install -y at
        systemctl enable atd
        systemctl start atd
    fi
    
    echo "$0 ${ORIGINAL_ARGS[@]}" | at "$SCHEDULE_TIME" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_success "Shutdown scheduled for $SCHEDULE_TIME"
        log_info "View scheduled jobs: atq"
        log_info "Cancel scheduled job: atrm <job-id>"
        exit 0
    else
        log_error "Failed to schedule shutdown"
        exit 1
    fi
}

shutdown_vm() {
    local SHUTDOWN_TYPE=$1
    
    log_info "Initiating VM shutdown..."
    
    case $SHUTDOWN_TYPE in
        deallocate)
            log_warning "VM will be deallocated (saves ~70% costs)"
            log_info "To restart: az vm start --resource-group <rg> --name <vm-name>"
            ;;
        stop)
            log_warning "VM will be stopped (saves ~30% costs)"
            log_info "To restart: az vm start --resource-group <rg> --name <vm-name>"
            ;;
        *)
            log_info "VM will be shut down normally"
            ;;
    esac
    
    sync
    
    log_success "Shutdown complete!"
    
    if [ "$SHUTDOWN_TYPE" = "quick" ]; then
        shutdown -h now
    else
        shutdown -h +1 "ContainerLab VM shutting down in 1 minute..."
    fi
}

SHUTDOWN_MODE="graceful"
BACKUP_ENABLED=false
SHUTDOWN_TYPE="normal"
SCHEDULE_TIME=""
ORIGINAL_ARGS=("$@")

if [ $# -eq 0 ]; then
    show_usage
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --graceful)
            SHUTDOWN_MODE="graceful"
            shift
            ;;
        --preserve-labs)
            SHUTDOWN_MODE="preserve"
            shift
            ;;
        --destroy-labs)
            SHUTDOWN_MODE="destroy"
            shift
            ;;
        --quick)
            SHUTDOWN_MODE="quick"
            SHUTDOWN_TYPE="quick"
            shift
            ;;
        --deallocate)
            SHUTDOWN_TYPE="deallocate"
            shift
            ;;
        --stop)
            SHUTDOWN_TYPE="stop"
            shift
            ;;
        --backup)
            BACKUP_ENABLED=true
            shift
            ;;
        --no-backup)
            BACKUP_ENABLED=false
            shift
            ;;
        --schedule)
            SCHEDULE_TIME="$2"
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

if [ ! -z "$SCHEDULE_TIME" ]; then
    schedule_shutdown "$SCHEDULE_TIME"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║              Portnox ContainerLab VM Shutdown                     ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

log_info "Shutdown mode: $SHUTDOWN_MODE"
log_info "Shutdown type: $SHUTDOWN_TYPE"
log_info "Backup enabled: $BACKUP_ENABLED"
echo ""

if [ "$BACKUP_ENABLED" = true ]; then
    backup_data
fi

case $SHUTDOWN_MODE in
    graceful)
        stop_labs_graceful
        stop_containers
        ;;
    preserve)
        preserve_labs
        ;;
    destroy)
        destroy_all_labs
        ;;
    quick)
        log_warning "Quick shutdown - containers will not be stopped gracefully"
        ;;
    *)
        log_error "Invalid shutdown mode: $SHUTDOWN_MODE"
        exit 1
        ;;
esac

shutdown_vm "$SHUTDOWN_TYPE"

exit 0
