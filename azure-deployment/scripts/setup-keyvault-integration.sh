#!/bin/bash


set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/keyvault-setup.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    error "Please run as root (use sudo)"
    exit 1
fi

log "Starting Azure Key Vault integration setup..."

if ! command -v az &> /dev/null; then
    log "Installing Azure CLI..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    
    if ! command -v az &> /dev/null; then
        error "Failed to install Azure CLI"
        exit 1
    fi
    
    log "Azure CLI installed successfully"
else
    log "Azure CLI already installed"
fi

log "Creating Key Vault helper script..."

cat > /usr/local/bin/get-portnox-secrets << 'HELPER_SCRIPT'
#!/bin/bash


set -e

KEY_VAULT_NAME="${PORTNOX_KEY_VAULT_NAME:-portnox-containerlab-kv}"
CACHE_DIR="/var/cache/portnox-secrets"
CACHE_TTL=3600  # Cache secrets for 1 hour

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

if ! command -v az &> /dev/null; then
    error "Azure CLI is not installed. Please run setup-keyvault-integration.sh first."
    exit 1
fi

mkdir -p "$CACHE_DIR"
chmod 700 "$CACHE_DIR"

is_cache_valid() {
    local cache_file="$1"
    
    if [ ! -f "$cache_file" ]; then
        return 1
    fi
    
    local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
    
    if [ $cache_age -gt $CACHE_TTL ]; then
        return 1
    fi
    
    return 0
}

get_secret() {
    local secret_name="$1"
    local cache_file="$CACHE_DIR/$secret_name"
    
    if is_cache_valid "$cache_file"; then
        cat "$cache_file"
        return 0
    fi
    
    local secret_value
    secret_value=$(az keyvault secret show \
        --vault-name "$KEY_VAULT_NAME" \
        --name "$secret_name" \
        --query value \
        --output tsv 2>/dev/null)
    
    if [ -z "$secret_value" ]; then
        error "Failed to retrieve secret: $secret_name"
        return 1
    fi
    
    echo "$secret_value" > "$cache_file"
    chmod 600 "$cache_file"
    
    echo "$secret_value"
}

log "Authenticating with Azure using managed identity..."
if ! az login --identity &> /dev/null; then
    error "Failed to authenticate with Azure managed identity"
    error "Ensure the VM has a system-assigned managed identity and access to Key Vault"
    exit 1
fi

log "Retrieving Portnox credentials from Key Vault: $KEY_VAULT_NAME"

export PORTNOX_ORG_ID=$(get_secret "portnox-org-id")
if [ -z "$PORTNOX_ORG_ID" ]; then
    error "Failed to retrieve Organization ID"
    exit 1
fi

export PORTNOX_RADIUS_TOKEN=$(get_secret "portnox-radius-token" 2>/dev/null || echo "")
export PORTNOX_TACACS_TOKEN=$(get_secret "portnox-tacacs-token" 2>/dev/null || echo "")
export PORTNOX_ZTNA_TOKEN=$(get_secret "portnox-ztna-token" 2>/dev/null || echo "")
export PORTNOX_DHCP_TOKEN=$(get_secret "portnox-dhcp-token" 2>/dev/null || echo "")
export PORTNOX_SIEM_TOKEN=$(get_secret "portnox-siem-token" 2>/dev/null || echo "")
export PORTNOX_AUTOUPDATE_TOKEN=$(get_secret "portnox-autoupdate-token" 2>/dev/null || echo "")
export PORTNOX_UNIFI_TOKEN=$(get_secret "portnox-unifi-token" 2>/dev/null || echo "")

export PORTNOX_RADIUS_PROFILE=$(get_secret "portnox-radius-profile" 2>/dev/null || echo "default-profile")
export PORTNOX_TACACS_PROFILE=$(get_secret "portnox-tacacs-profile" 2>/dev/null || echo "default-tacacs-profile")
export PORTNOX_ZTNA_PROFILE=$(get_secret "portnox-ztna-profile" 2>/dev/null || echo "default-ztna-profile")

log "Portnox credentials loaded successfully from Azure Key Vault"
log "Organization ID: ${PORTNOX_ORG_ID:0:8}..."

echo ""
echo "Available credentials:"
[ -n "$PORTNOX_RADIUS_TOKEN" ] && echo "  ✓ RADIUS Gateway Token"
[ -n "$PORTNOX_TACACS_TOKEN" ] && echo "  ✓ TACACS+ Gateway Token"
[ -n "$PORTNOX_ZTNA_TOKEN" ] && echo "  ✓ ZTNA Gateway Token"
[ -n "$PORTNOX_DHCP_TOKEN" ] && echo "  ✓ DHCP Relay Token"
[ -n "$PORTNOX_SIEM_TOKEN" ] && echo "  ✓ SIEM Forwarder Token"
[ -n "$PORTNOX_AUTOUPDATE_TOKEN" ] && echo "  ✓ Auto-Update Token"
[ -n "$PORTNOX_UNIFI_TOKEN" ] && echo "  ✓ UniFi Agent Token"
echo ""
echo "To use these credentials in your current shell, run:"
echo "  source <(get-portnox-secrets)"
echo ""
echo "To deploy a lab with these credentials:"
echo "  source <(get-portnox-secrets)"
echo "  sudo -E containerlab deploy -t /data/labs/portnox-radius-802.1x.clab.yml"
HELPER_SCRIPT

chmod +x /usr/local/bin/get-portnox-secrets

log "Helper script created at /usr/local/bin/get-portnox-secrets"

log "Creating systemd service for automatic secret loading..."

cat > /etc/systemd/system/portnox-secrets.service << 'SERVICE_FILE'
[Unit]
Description=Load Portnox Secrets from Azure Key Vault
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/get-portnox-secrets
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE_FILE

systemctl daemon-reload
systemctl enable portnox-secrets.service

log "Systemd service created and enabled"

log "Creating ContainerLab environment loader..."

cat > /usr/local/bin/clab-deploy-with-secrets << 'CLAB_SCRIPT'
#!/bin/bash


set -e

if [ $# -eq 0 ]; then
    echo "Usage: clab-deploy-with-secrets <lab-file.clab.yml>"
    echo ""
    echo "Example:"
    echo "  clab-deploy-with-secrets /data/labs/portnox-radius-802.1x.clab.yml"
    exit 1
fi

LAB_FILE="$1"

if [ ! -f "$LAB_FILE" ]; then
    echo "Error: Lab file not found: $LAB_FILE"
    exit 1
fi

echo "Loading Portnox credentials from Azure Key Vault..."
source <(get-portnox-secrets)

echo "Deploying ContainerLab topology: $LAB_FILE"
sudo -E containerlab deploy -t "$LAB_FILE"
CLAB_SCRIPT

chmod +x /usr/local/bin/clab-deploy-with-secrets

log "ContainerLab deployment helper created at /usr/local/bin/clab-deploy-with-secrets"

log "Creating usage documentation..."

cat > /usr/local/share/portnox-keyvault-usage.txt << 'USAGE_DOC'


This VM is configured to retrieve Portnox credentials from Azure Key Vault
using a system-assigned managed identity. This provides secure credential
management without storing secrets on the VM.


1. Azure Key Vault must be created with the name: portnox-containerlab-kv
   (or set PORTNOX_KEY_VAULT_NAME environment variable)

2. The VM must have a system-assigned managed identity with access to the Key Vault

3. The following secrets should be stored in Key Vault:
   - portnox-org-id (required)
   - portnox-radius-token (optional)
   - portnox-tacacs-token (optional)
   - portnox-ztna-token (optional)
   - portnox-dhcp-token (optional)
   - portnox-siem-token (optional)
   - portnox-autoupdate-token (optional)
   - portnox-unifi-token (optional)
   - portnox-radius-profile (optional, default: default-profile)
   - portnox-tacacs-profile (optional, default: default-tacacs-profile)
   - portnox-ztna-profile (optional, default: default-ztna-profile)



Use the helper script to deploy labs with automatic secret loading:

    clab-deploy-with-secrets /data/labs/portnox-radius-802.1x.clab.yml


Load secrets into your current shell session:

    source <(get-portnox-secrets)
    sudo -E containerlab deploy -t /data/labs/portnox-radius-802.1x.clab.yml


The portnox-secrets service automatically loads secrets on boot:

    sudo systemctl start portnox-secrets.service
    sudo systemctl status portnox-secrets.service



    az keyvault create \
      --name portnox-containerlab-kv \
      --resource-group portnox-containerlab-rg \
      --location eastus


    az keyvault secret set \
      --vault-name portnox-containerlab-kv \
      --name portnox-org-id \
      --value "your-org-id-here"

    az keyvault secret set \
      --vault-name portnox-containerlab-kv \
      --name portnox-radius-token \
      --value "your-radius-token-here"


    PRINCIPAL_ID=$(az vm show \
      --resource-group portnox-containerlab-rg \
      --name portnox-containerlab \
      --query identity.principalId \
      --output tsv)

    az keyvault set-policy \
      --name portnox-containerlab-kv \
      --object-id $PRINCIPAL_ID \
      --secret-permissions get list



    az login --identity
    az account show


    az keyvault secret show \
      --vault-name portnox-containerlab-kv \
      --name portnox-org-id


    ls -la /var/cache/portnox-secrets/


    sudo rm -rf /var/cache/portnox-secrets/*


    sudo journalctl -u portnox-secrets.service


- Secrets are cached for 1 hour to reduce Key Vault API calls
- Cache files are stored with 600 permissions in /var/cache/portnox-secrets/
- The VM's managed identity has read-only access to Key Vault
- Never commit secrets to Git or store them in plain text files


- Azure Key Vault Documentation: https://docs.microsoft.com/azure/key-vault
- Portnox Cloud Setup Guide: /data/PORTNOX_CLOUD_SETUP.md
- Portnox Container Reference: /data/PORTNOX_CONTAINERS_REFERENCE.md
USAGE_DOC

log "Usage documentation created at /usr/local/share/portnox-keyvault-usage.txt"

log "Creating shell aliases..."

cat >> /etc/bash.bashrc << 'ALIASES'

alias load-portnox-secrets='source <(get-portnox-secrets)'
alias clab-deploy='clab-deploy-with-secrets'
alias show-portnox-help='cat /usr/local/share/portnox-keyvault-usage.txt'
ALIASES

log "Shell aliases added to /etc/bash.bashrc"

echo ""
echo "=========================================="
echo "Azure Key Vault Integration Setup Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Create Azure Key Vault (if not exists):"
echo "   az keyvault create --name portnox-containerlab-kv --resource-group portnox-containerlab-rg --location eastus"
echo ""
echo "2. Store your Portnox credentials:"
echo "   az keyvault secret set --vault-name portnox-containerlab-kv --name portnox-org-id --value 'your-org-id'"
echo "   az keyvault secret set --vault-name portnox-containerlab-kv --name portnox-radius-token --value 'your-token'"
echo ""
echo "3. Grant VM access to Key Vault:"
echo "   PRINCIPAL_ID=\$(az vm show --resource-group portnox-containerlab-rg --name portnox-containerlab --query identity.principalId -o tsv)"
echo "   az keyvault set-policy --name portnox-containerlab-kv --object-id \$PRINCIPAL_ID --secret-permissions get list"
echo ""
echo "4. Deploy labs with automatic secret loading:"
echo "   clab-deploy-with-secrets /data/labs/portnox-radius-802.1x.clab.yml"
echo ""
echo "For detailed usage instructions, run:"
echo "   show-portnox-help"
echo ""
echo "=========================================="

log "Azure Key Vault integration setup completed successfully"
