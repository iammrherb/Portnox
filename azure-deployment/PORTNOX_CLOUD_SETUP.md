# Portnox Cloud Setup Guide

This guide explains how to obtain the necessary credentials and configuration values for deploying Portnox containers in your ContainerLab environment.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Portnox Cloud Account Setup](#portnox-cloud-account-setup)
3. [Obtaining Gateway Tokens](#obtaining-gateway-tokens)
4. [Obtaining Organization IDs](#obtaining-organization-ids)
5. [Creating Gateway Profiles](#creating-gateway-profiles)
6. [Configuring ContainerLab](#configuring-containerlab)
7. [Credential Management](#credential-management)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

Before you begin, ensure you have:

- A Portnox Cloud account (sign up at https://cloud.portnox.com)
- Administrative access to your Portnox Cloud organization
- Access to your Azure ContainerLab VM
- Basic understanding of RADIUS, TACACS+, or ZTNA concepts

## Portnox Cloud Account Setup

### Step 1: Create a Portnox Cloud Account

1. Navigate to https://cloud.portnox.com
2. Click **Sign Up** or **Start Free Trial**
3. Complete the registration form:
   - Business email address
   - Company name
   - Contact information
4. Verify your email address
5. Complete the initial setup wizard

### Step 2: Access Your Organization

1. Log in to Portnox Cloud
2. Navigate to **Settings** → **Organization**
3. Note your **Organization Name** and **Organization ID**

## Obtaining Gateway Tokens

Gateway tokens are required for all Portnox containers to authenticate with Portnox Cloud.

### For RADIUS Gateway

1. Log in to Portnox Cloud
2. Navigate to **RADIUS** → **Gateways**
3. Click **Add Gateway**
4. Configure the gateway:
   - **Name**: `containerlab-radius-gateway` (or your preferred name)
   - **Description**: `ContainerLab RADIUS Gateway`
   - **Location**: Select your Azure region
5. Click **Create**
6. Copy the **Gateway Token** (shown only once)
7. Save this token securely - you'll need it for the RADIUS container

**Example Token Format:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJvcmdJZCI6IjEyMzQ1Njc4OTAiLCJnYXRld2F5SWQiOiJhYmNkZWZnaGlqa2xtbm9wcXJzdHV2d3h5eiIsImlhdCI6MTYzMjQ4NjQwMH0.abcdefghijklmnopqrstuvwxyz1234567890
```

### For TACACS+ Gateway

1. Navigate to **TACACS+** → **Gateways**
2. Click **Add Gateway**
3. Configure the gateway:
   - **Name**: `containerlab-tacacs-gateway`
   - **Description**: `ContainerLab TACACS+ Gateway`
   - **Location**: Select your Azure region
4. Click **Create**
5. Copy the **Gateway Token**
6. Save this token securely

### For ZTNA Gateway

1. Navigate to **ZTNA** → **Gateways**
2. Click **Add Gateway**
3. Configure the gateway:
   - **Name**: `containerlab-ztna-gateway`
   - **Description**: `ContainerLab ZTNA Gateway`
   - **Location**: Select your Azure region
   - **Gateway Type**: Select based on your needs (Cloud/On-Premises)
4. Click **Create**
5. Copy the **Gateway Token**
6. Save this token securely

## Obtaining Organization IDs

Your Organization ID is required for all Portnox containers.

### Method 1: Via Web Interface

1. Log in to Portnox Cloud
2. Navigate to **Settings** → **Organization**
3. Copy the **Organization ID** field

**Example Organization ID:**
```
1234567890abcdef
```

### Method 2: Via API

```bash
curl -X GET "https://api.portnox.com/v1/organizations" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json"
```

## Creating Gateway Profiles

Gateway profiles define the authentication and authorization policies for your gateways.

### RADIUS Gateway Profile

1. Navigate to **RADIUS** → **Profiles**
2. Click **Create Profile**
3. Configure the profile:
   - **Name**: `default-profile` (or your preferred name)
   - **Authentication Methods**: Select EAP-TLS, PEAP, EAP-TTLS, etc.
   - **Authorization Rules**: Configure based on your requirements
   - **VLAN Assignment**: Configure dynamic VLAN assignment if needed
4. Click **Save**
5. Note the **Profile Name** - you'll use this in your container configuration

### TACACS+ Gateway Profile

1. Navigate to **TACACS+** → **Profiles**
2. Click **Create Profile**
3. Configure the profile:
   - **Name**: `default-tacacs-profile`
   - **Command Authorization**: Configure command sets
   - **Privilege Levels**: Define privilege levels
   - **Accounting**: Enable accounting if needed
4. Click **Save**
5. Note the **Profile Name**

### ZTNA Gateway Profile

1. Navigate to **ZTNA** → **Profiles**
2. Click **Create Profile**
3. Configure the profile:
   - **Name**: `default-ztna-profile`
   - **Access Policies**: Define who can access what
   - **MFA Requirements**: Configure MFA settings
   - **Device Posture**: Set device compliance requirements
4. Click **Save**
5. Note the **Profile Name**

## Configuring ContainerLab

Once you have your credentials, update your ContainerLab topology files.

### Example: RADIUS Gateway Configuration

Edit `/data/labs/portnox-radius-802.1x.clab.yml`:

```yaml
topology:
  nodes:
    radius-server:
      kind: linux
      image: portnox/portnox-radius:latest
      env:
        RADIUS_GATEWAY_PROFILE: default-profile
        RADIUS_GATEWAY_ORG_ID: 1234567890abcdef
        RADIUS_GATEWAY_TOKEN: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
        PORTNOX_NAME: lab-radius-gateway
        PORTNOX_LOG_LEVEL: debug
        PORTNOX_CLOUD_URL: https://cloud.portnox.com
      ports:
        - "1812:1812/udp"
        - "1813:1813/udp"
```

### Example: TACACS+ Gateway Configuration

Edit `/data/labs/portnox-tacacs-plus.clab.yml`:

```yaml
topology:
  nodes:
    tacacs-server:
      kind: linux
      image: portnox/portnox-tacacs:latest
      env:
        TACACS_GATEWAY_PROFILE: default-tacacs-profile
        TACACS_GATEWAY_ORG_ID: 1234567890abcdef
        TACACS_GATEWAY_TOKEN: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
        PORTNOX_NAME: lab-tacacs-gateway
        PORTNOX_LOG_LEVEL: debug
        PORTNOX_CLOUD_URL: https://cloud.portnox.com
      ports:
        - "49:49/tcp"
```

### Example: ZTNA Gateway Configuration

Edit `/data/labs/portnox-ztna-deployment.clab.yml`:

```yaml
topology:
  nodes:
    ztna-gateway:
      kind: linux
      image: portnox/ztna-gateway:latest
      env:
        ZTNA_GATEWAY_PROFILE: default-ztna-profile
        ZTNA_GATEWAY_ORG_ID: 1234567890abcdef
        ZTNA_GATEWAY_TOKEN: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
        PORTNOX_NAME: lab-ztna-gateway
        PORTNOX_LOG_LEVEL: debug
        PORTNOX_CLOUD_URL: https://cloud.portnox.com
      ports:
        - "443:443/tcp"
        - "8443:8443/tcp"
```

## Credential Management

### Option 1: Environment Variables (Quick Testing)

For quick testing, you can set environment variables before deploying:

```bash
export PORTNOX_ORG_ID="1234567890abcdef"
export PORTNOX_RADIUS_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
export PORTNOX_TACACS_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
export PORTNOX_ZTNA_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Deploy with environment variables
sudo -E containerlab deploy -t /data/labs/portnox-radius-802.1x.clab.yml
```

### Option 2: Azure Key Vault (Recommended for Production)

For production deployments, use Azure Key Vault to securely store credentials.

#### Step 1: Store Secrets in Azure Key Vault

```bash
# Create Key Vault (if not exists)
az keyvault create \
  --name portnox-containerlab-kv \
  --resource-group portnox-containerlab-rg \
  --location eastus

# Store Portnox credentials
az keyvault secret set \
  --vault-name portnox-containerlab-kv \
  --name portnox-org-id \
  --value "1234567890abcdef"

az keyvault secret set \
  --vault-name portnox-containerlab-kv \
  --name portnox-radius-token \
  --value "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

az keyvault secret set \
  --vault-name portnox-containerlab-kv \
  --name portnox-tacacs-token \
  --value "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

az keyvault secret set \
  --vault-name portnox-containerlab-kv \
  --name portnox-ztna-token \
  --value "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

#### Step 2: Grant VM Access to Key Vault

```bash
# Enable system-assigned managed identity on VM
az vm identity assign \
  --resource-group portnox-containerlab-rg \
  --name portnox-containerlab

# Get the VM's principal ID
PRINCIPAL_ID=$(az vm show \
  --resource-group portnox-containerlab-rg \
  --name portnox-containerlab \
  --query identity.principalId \
  --output tsv)

# Grant VM access to Key Vault
az keyvault set-policy \
  --name portnox-containerlab-kv \
  --object-id $PRINCIPAL_ID \
  --secret-permissions get list
```

#### Step 3: Retrieve Secrets on VM

Create a helper script `/usr/local/bin/get-portnox-secrets.sh`:

```bash
#!/bin/bash

# Install Azure CLI if not present
if ! command -v az &> /dev/null; then
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

# Login using managed identity
az login --identity

# Retrieve secrets
export PORTNOX_ORG_ID=$(az keyvault secret show \
  --vault-name portnox-containerlab-kv \
  --name portnox-org-id \
  --query value \
  --output tsv)

export PORTNOX_RADIUS_TOKEN=$(az keyvault secret show \
  --vault-name portnox-containerlab-kv \
  --name portnox-radius-token \
  --query value \
  --output tsv)

export PORTNOX_TACACS_TOKEN=$(az keyvault secret show \
  --vault-name portnox-containerlab-kv \
  --name portnox-tacacs-token \
  --query value \
  --output tsv)

export PORTNOX_ZTNA_TOKEN=$(az keyvault secret show \
  --vault-name portnox-containerlab-kv \
  --name portnox-ztna-token \
  --query value \
  --output tsv)

echo "Portnox credentials loaded from Azure Key Vault"
```

Make it executable:

```bash
sudo chmod +x /usr/local/bin/get-portnox-secrets.sh
```

Use it before deploying labs:

```bash
source /usr/local/bin/get-portnox-secrets.sh
sudo -E containerlab deploy -t /data/labs/portnox-radius-802.1x.clab.yml
```

### Option 3: Configuration Files (Not Recommended)

You can store credentials in configuration files, but this is **not recommended** for security reasons.

Create `/data/configs/portnox-credentials.env`:

```bash
PORTNOX_ORG_ID=1234567890abcdef
PORTNOX_RADIUS_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
PORTNOX_TACACS_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
PORTNOX_ZTNA_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Secure the file:

```bash
sudo chmod 600 /data/configs/portnox-credentials.env
sudo chown azureuser:azureuser /data/configs/portnox-credentials.env
```

Load before deploying:

```bash
source /data/configs/portnox-credentials.env
sudo -E containerlab deploy -t /data/labs/portnox-radius-802.1x.clab.yml
```

## Troubleshooting

### Gateway Not Connecting to Portnox Cloud

**Symptom:** Container starts but doesn't appear in Portnox Cloud console.

**Solutions:**

1. **Verify Token:**
   ```bash
   docker logs <container-name> | grep -i "token\|auth\|error"
   ```

2. **Check Network Connectivity:**
   ```bash
   docker exec <container-name> ping -c 3 cloud.portnox.com
   docker exec <container-name> curl -v https://cloud.portnox.com
   ```

3. **Verify Organization ID:**
   - Ensure the Organization ID matches exactly (case-sensitive)
   - Check for extra spaces or special characters

4. **Check Firewall Rules:**
   - Ensure outbound HTTPS (443) is allowed
   - Verify Azure NSG allows outbound traffic

### Invalid Gateway Token

**Symptom:** Container logs show "Invalid token" or "Authentication failed".

**Solutions:**

1. **Regenerate Token:**
   - Go to Portnox Cloud → Gateways
   - Delete the old gateway
   - Create a new gateway and copy the new token

2. **Check Token Expiration:**
   - Some tokens may have expiration dates
   - Verify token is still valid in Portnox Cloud

3. **Verify Token Format:**
   - Ensure no line breaks or extra characters
   - Token should be a single continuous string

### Gateway Profile Not Found

**Symptom:** Container logs show "Profile not found" or "Invalid profile".

**Solutions:**

1. **Verify Profile Name:**
   - Check exact spelling and case
   - Profile names are case-sensitive

2. **Create Profile:**
   - Ensure the profile exists in Portnox Cloud
   - Navigate to RADIUS/TACACS+/ZTNA → Profiles

3. **Check Profile Assignment:**
   - Verify the profile is assigned to your organization

### Container Fails to Start

**Symptom:** Container exits immediately or fails to start.

**Solutions:**

1. **Check Container Logs:**
   ```bash
   docker logs <container-name>
   ```

2. **Verify Environment Variables:**
   ```bash
   docker inspect <container-name> | jq '.[0].Config.Env'
   ```

3. **Test with Minimal Configuration:**
   ```bash
   docker run -it --rm \
     -e PORTNOX_ORG_ID="your-org-id" \
     -e RADIUS_GATEWAY_TOKEN="your-token" \
     -e PORTNOX_LOG_LEVEL="debug" \
     portnox/portnox-radius:latest
   ```

### Authentication Requests Not Working

**Symptom:** RADIUS/TACACS+ requests fail or timeout.

**Solutions:**

1. **Verify Port Mappings:**
   ```bash
   docker port <container-name>
   ```

2. **Check Gateway Status in Portnox Cloud:**
   - Navigate to Gateways
   - Verify gateway shows as "Online"

3. **Test Connectivity:**
   ```bash
   # For RADIUS
   radtest testuser testpass localhost 1812 testing123
   
   # For TACACS+
   tactest -u testuser -p testpass -s localhost -k testing123
   ```

4. **Review Logs:**
   ```bash
   docker logs -f <container-name>
   ```

## Additional Resources

- **Portnox Cloud Documentation:** https://docs.portnox.com
- **Portnox Support:** https://support.portnox.com
- **ContainerLab Documentation:** https://containerlab.dev
- **Azure Key Vault Documentation:** https://docs.microsoft.com/azure/key-vault

## Security Best Practices

1. **Never commit credentials to Git:**
   - Add `*.env` to `.gitignore`
   - Use Azure Key Vault or GitHub Secrets

2. **Rotate tokens regularly:**
   - Set up a rotation schedule (e.g., every 90 days)
   - Update tokens in Key Vault when rotated

3. **Use least privilege:**
   - Grant only necessary permissions to service accounts
   - Use separate tokens for different environments

4. **Monitor access:**
   - Enable audit logging in Portnox Cloud
   - Review gateway connection logs regularly

5. **Secure the VM:**
   - Keep SSH keys secure
   - Use Azure Bastion for SSH access
   - Enable Azure Security Center

## Next Steps

After configuring your Portnox credentials:

1. Deploy a test lab to verify connectivity
2. Configure authentication policies in Portnox Cloud
3. Test authentication with real devices
4. Set up monitoring and alerting
5. Document your specific configuration for your team

For questions or issues, contact Portnox support or refer to the comprehensive documentation at https://docs.portnox.com.
