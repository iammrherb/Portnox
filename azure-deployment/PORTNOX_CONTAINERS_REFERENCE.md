# Portnox Official Containers Reference

This document provides comprehensive reference for all official Portnox Docker containers, including all environment variables, configuration options, and deployment examples.

## Container Images

All official Portnox containers are available on Docker Hub:
- `portnox/ztna-gateway` - ZTNA Gateway
- `portnox/portnox-radius` - RADIUS Gateway
- `portnox/portnox-tacacs` - TACACS+ Gateway
- `portnox/portnox-dhcp` - DHCP Relay
- `portnox/portnox-siem` - SIEM Forwarder
- `portnox/portnox-autoupdate` - Auto-Update Service
- `portnox/portnox-unifi-agent` - UniFi Agent

## 1. ZTNA Gateway (`portnox/ztna-gateway`)

### Purpose
Provides Zero Trust Network Access (ZTNA) for protecting applications and resources.

### Required Environment Variables
```yaml
APIUSER: <tenant-org-id>          # Your Portnox Cloud Organization ID
APIKEY: <api-token>                # API token from Portnox Cloud
GWID: <gateway-unique-id>          # Unique identifier for this gateway
```

### Optional Environment Variables
```yaml
PORTNOX_NAME: <gateway-name>       # Friendly name for the gateway
PORTNOX_LOG_LEVEL: info            # Log level: debug, info, warn, error
ZTNA_PORT: 443                     # HTTPS port for ZTNA connections
ZTNA_ADMIN_PORT: 8443              # Admin interface port
```

### Ports
- `443/tcp` - ZTNA HTTPS connections
- `8443/tcp` - Admin interface

### Example Deployment
```yaml
ztna-gateway:
  kind: linux
  image: portnox/ztna-gateway:latest
  env:
    APIUSER: your-org-id-here
    APIKEY: your-api-token-here
    GWID: ztna-gateway-001
    PORTNOX_NAME: production-ztna-gateway
    PORTNOX_LOG_LEVEL: info
  ports:
    - "443:443/tcp"
    - "8443:8443/tcp"
```

## 2. RADIUS Gateway (`portnox/portnox-radius`)

### Purpose
Provides RADIUS authentication for 802.1X wired/wireless network access control.

### Required Environment Variables
```yaml
RADIUS_GATEWAY_PROFILE: <profile-name>    # Profile name from Portnox Cloud
RADIUS_GATEWAY_ORG_ID: <org-id>           # Your Portnox Cloud Organization ID
RADIUS_GATEWAY_TOKEN: <gateway-token>     # Gateway token from Portnox Cloud
```

### Optional Environment Variables
```yaml
PORTNOX_NAME: <gateway-name>              # Friendly name for the gateway
PORTNOX_LOG_LEVEL: info                   # Log level: debug, info, warn, error
RADIUS_AUTH_PORT: 1812                    # RADIUS authentication port
RADIUS_ACCT_PORT: 1813                    # RADIUS accounting port
RADIUS_COA_PORT: 3799                     # RADIUS CoA/DM port
```

### Ports
- `1812/udp` - RADIUS authentication
- `1813/udp` - RADIUS accounting
- `3799/udp` - RADIUS CoA (Change of Authorization)

### Example Deployment
```yaml
radius-gateway:
  kind: linux
  image: portnox/portnox-radius:latest
  env:
    RADIUS_GATEWAY_PROFILE: default-profile
    RADIUS_GATEWAY_ORG_ID: your-org-id-here
    RADIUS_GATEWAY_TOKEN: your-gateway-token-here
    PORTNOX_NAME: production-radius-gateway
    PORTNOX_LOG_LEVEL: info
  ports:
    - "1812:1812/udp"
    - "1813:1813/udp"
    - "3799:3799/udp"
```

## 3. TACACS+ Gateway (`portnox/portnox-tacacs`)

### Purpose
Provides TACACS+ authentication for network device administration.

### Required Environment Variables
```yaml
TACACS_GATEWAY_PROFILE: <profile-name>    # Profile name from Portnox Cloud
TACACS_GATEWAY_ORG_ID: <org-id>           # Your Portnox Cloud Organization ID
TACACS_GATEWAY_TOKEN: <gateway-token>     # Gateway token from Portnox Cloud
```

### Optional Environment Variables
```yaml
PORTNOX_NAME: <gateway-name>              # Friendly name for the gateway
PORTNOX_LOG_LEVEL: info                   # Log level: debug, info, warn, error
TACACS_PORT: 49                           # TACACS+ port (default 49)
```

### Ports
- `49/tcp` - TACACS+ authentication

### Example Deployment
```yaml
tacacs-gateway:
  kind: linux
  image: portnox/portnox-tacacs:latest
  env:
    TACACS_GATEWAY_PROFILE: default-profile
    TACACS_GATEWAY_ORG_ID: your-org-id-here
    TACACS_GATEWAY_TOKEN: your-gateway-token-here
    PORTNOX_NAME: production-tacacs-gateway
    PORTNOX_LOG_LEVEL: info
  ports:
    - "49:49/tcp"
```

## 4. DHCP Relay (`portnox/portnox-dhcp`)

### Purpose
Provides DHCP relay functionality for network access control.

### Required Environment Variables
```yaml
DHCP_RELAY_ORG_ID: <org-id>               # Your Portnox Cloud Organization ID
DHCP_RELAY_TOKEN: <relay-token>           # DHCP relay token from Portnox Cloud
```

### Optional Environment Variables
```yaml
PORTNOX_NAME: <relay-name>                # Friendly name for the relay
PORTNOX_LOG_LEVEL: info                   # Log level: debug, info, warn, error
DHCP_SERVER: <dhcp-server-ip>             # Upstream DHCP server IP
DHCP_PORT: 67                             # DHCP server port
```

### Ports
- `67/udp` - DHCP server
- `68/udp` - DHCP client

### Example Deployment
```yaml
dhcp-relay:
  kind: linux
  image: portnox/portnox-dhcp:latest
  env:
    DHCP_RELAY_ORG_ID: your-org-id-here
    DHCP_RELAY_TOKEN: your-relay-token-here
    PORTNOX_NAME: production-dhcp-relay
    DHCP_SERVER: 10.0.0.1
    PORTNOX_LOG_LEVEL: info
  ports:
    - "67:67/udp"
    - "68:68/udp"
```

## 5. SIEM Forwarder (`portnox/portnox-siem`)

### Purpose
Forwards Portnox logs to external SIEM systems (Splunk, ELK, etc.).

### Required Environment Variables
```yaml
SIEM_FORWARDER_ORG_ID: <org-id>           # Your Portnox Cloud Organization ID
SIEM_FORWARDER_TOKEN: <forwarder-token>   # SIEM forwarder token from Portnox Cloud
SIEM_SERVER: <siem-server-address>        # SIEM server hostname or IP
SIEM_PORT: <siem-port>                    # SIEM server port
```

### Optional Environment Variables
```yaml
PORTNOX_NAME: <forwarder-name>            # Friendly name for the forwarder
PORTNOX_LOG_LEVEL: info                   # Log level: debug, info, warn, error
SIEM_PROTOCOL: tcp                        # Protocol: tcp, udp, tls
SIEM_FORMAT: cef                          # Log format: cef, json, syslog
SIEM_TLS_VERIFY: true                     # Verify TLS certificates
```

### Example Deployment
```yaml
siem-forwarder:
  kind: linux
  image: portnox/portnox-siem:latest
  env:
    SIEM_FORWARDER_ORG_ID: your-org-id-here
    SIEM_FORWARDER_TOKEN: your-forwarder-token-here
    SIEM_SERVER: splunk.example.com
    SIEM_PORT: 514
    SIEM_PROTOCOL: tcp
    SIEM_FORMAT: cef
    PORTNOX_NAME: production-siem-forwarder
    PORTNOX_LOG_LEVEL: info
```

## 6. Auto-Update Service (`portnox/portnox-autoupdate`)

### Purpose
Automatically updates Portnox containers to the latest versions.

### Required Environment Variables
```yaml
AUTOUPDATE_ORG_ID: <org-id>               # Your Portnox Cloud Organization ID
AUTOUPDATE_TOKEN: <autoupdate-token>      # Auto-update token from Portnox Cloud
```

### Optional Environment Variables
```yaml
PORTNOX_NAME: <service-name>              # Friendly name for the service
PORTNOX_LOG_LEVEL: info                   # Log level: debug, info, warn, error
UPDATE_CHECK_INTERVAL: 3600               # Check interval in seconds (default 1 hour)
UPDATE_WINDOW_START: 02:00                # Update window start time (HH:MM)
UPDATE_WINDOW_END: 04:00                  # Update window end time (HH:MM)
```

### Volumes
- `/var/run/docker.sock:/var/run/docker.sock` - Required for Docker access

### Example Deployment
```yaml
autoupdate:
  kind: linux
  image: portnox/portnox-autoupdate:latest
  env:
    AUTOUPDATE_ORG_ID: your-org-id-here
    AUTOUPDATE_TOKEN: your-autoupdate-token-here
    UPDATE_CHECK_INTERVAL: 3600
    UPDATE_WINDOW_START: "02:00"
    UPDATE_WINDOW_END: "04:00"
    PORTNOX_NAME: production-autoupdate
    PORTNOX_LOG_LEVEL: info
  binds:
    - /var/run/docker.sock:/var/run/docker.sock
```

## 7. UniFi Agent (`portnox/portnox-unifi-agent`)

### Purpose
Integrates Portnox with Ubiquiti UniFi network infrastructure.

### Required Environment Variables
```yaml
UNIFI_AGENT_ORG_ID: <org-id>              # Your Portnox Cloud Organization ID
UNIFI_AGENT_TOKEN: <agent-token>          # UniFi agent token from Portnox Cloud
UNIFI_CONTROLLER: <controller-address>    # UniFi Controller hostname or IP
```

### Optional Environment Variables
```yaml
PORTNOX_NAME: <agent-name>                # Friendly name for the agent
PORTNOX_LOG_LEVEL: info                   # Log level: debug, info, warn, error
UNIFI_CONTROLLER_PORT: 8443               # UniFi Controller port
UNIFI_SITE: default                       # UniFi site name
UNIFI_USERNAME: <username>                # UniFi Controller username
UNIFI_PASSWORD: <password>                # UniFi Controller password
```

### Example Deployment
```yaml
unifi-agent:
  kind: linux
  image: portnox/portnox-unifi-agent:latest
  env:
    UNIFI_AGENT_ORG_ID: your-org-id-here
    UNIFI_AGENT_TOKEN: your-agent-token-here
    UNIFI_CONTROLLER: unifi.example.com
    UNIFI_CONTROLLER_PORT: 8443
    UNIFI_SITE: default
    PORTNOX_NAME: production-unifi-agent
    PORTNOX_LOG_LEVEL: info
```

## Getting Tokens and Credentials

All tokens, organization IDs, and profile names are obtained from your Portnox Cloud portal:

1. **Log in to Portnox Cloud**: https://yourorg.portnox.cloud
2. **Navigate to Gateways**: Settings → Gateways
3. **Create Gateway**: Click "Add Gateway" and select the type
4. **Copy Credentials**: Copy the Organization ID, Profile Name, and Token
5. **Use in Deployment**: Add to your ContainerLab topology file

## Security Best Practices

1. **Never commit tokens to Git**: Use environment variables or secrets management
2. **Rotate tokens regularly**: Generate new tokens every 90 days
3. **Use separate tokens**: Don't reuse tokens across different gateways
4. **Enable TLS**: Always use TLS for SIEM and external connections
5. **Restrict network access**: Use firewall rules to limit access to gateways
6. **Monitor logs**: Enable debug logging during initial deployment, then switch to info

## Troubleshooting

### Container won't start
```bash
# Check logs
docker logs <container-name>

# Verify environment variables
docker inspect <container-name> | grep -A 20 Env

# Test network connectivity
docker exec <container-name> ping portnox.cloud
```

### Authentication failures
```bash
# Verify token is correct
# Check Portnox Cloud portal for gateway status
# Ensure organization ID matches your tenant
# Verify profile name is correct (case-sensitive)
```

### Network connectivity issues
```bash
# Verify ports are exposed
docker port <container-name>

# Check firewall rules
sudo ufw status

# Test from external host
nc -zv <vm-ip> 1812  # RADIUS
nc -zv <vm-ip> 49    # TACACS+
```

## Example: Complete Multi-Service Deployment

```yaml
name: portnox-complete

topology:
  nodes:
    # RADIUS Gateway
    radius-gateway:
      kind: linux
      image: portnox/portnox-radius:latest
      env:
        RADIUS_GATEWAY_PROFILE: production-profile
        RADIUS_GATEWAY_ORG_ID: your-org-id-here
        RADIUS_GATEWAY_TOKEN: your-radius-token-here
        PORTNOX_NAME: prod-radius-gateway
      ports:
        - "1812:1812/udp"
        - "1813:1813/udp"
    
    # TACACS+ Gateway
    tacacs-gateway:
      kind: linux
      image: portnox/portnox-tacacs:latest
      env:
        TACACS_GATEWAY_PROFILE: production-profile
        TACACS_GATEWAY_ORG_ID: your-org-id-here
        TACACS_GATEWAY_TOKEN: your-tacacs-token-here
        PORTNOX_NAME: prod-tacacs-gateway
      ports:
        - "49:49/tcp"
    
    # ZTNA Gateway
    ztna-gateway:
      kind: linux
      image: portnox/ztna-gateway:latest
      env:
        APIUSER: your-org-id-here
        APIKEY: your-ztna-token-here
        GWID: ztna-gateway-001
        PORTNOX_NAME: prod-ztna-gateway
      ports:
        - "443:443/tcp"
        - "8443:8443/tcp"
    
    # SIEM Forwarder
    siem-forwarder:
      kind: linux
      image: portnox/portnox-siem:latest
      env:
        SIEM_FORWARDER_ORG_ID: your-org-id-here
        SIEM_FORWARDER_TOKEN: your-siem-token-here
        SIEM_SERVER: splunk.example.com
        SIEM_PORT: 514
        SIEM_PROTOCOL: tcp
        SIEM_FORMAT: cef
    
    # Auto-Update Service
    autoupdate:
      kind: linux
      image: portnox/portnox-autoupdate:latest
      env:
        AUTOUPDATE_ORG_ID: your-org-id-here
        AUTOUPDATE_TOKEN: your-autoupdate-token-here
        UPDATE_CHECK_INTERVAL: 3600
      binds:
        - /var/run/docker.sock:/var/run/docker.sock
```

## Additional Resources

- **Portnox Documentation**: https://docs.portnox.com
- **Docker Hub**: https://hub.docker.com/u/portnox
- **Support**: support@portnox.com
- **Community**: https://community.portnox.com
