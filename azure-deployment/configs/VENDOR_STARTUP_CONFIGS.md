# Vendor Startup Configurations and Default Credentials

This document provides startup configurations and default credentials for all supported network vendor images in ContainerLab.

## Table of Contents
- [Cisco IOS/IOS-XE](#cisco-iosios-xe)
- [Cisco IOS-XR](#cisco-ios-xr)
- [Cisco Nexus (NX-OS)](#cisco-nexus-nx-os)
- [Arista cEOS](#arista-ceos)
- [Juniper vMX/vQFX](#juniper-vmxvqfx)
- [Nokia SR Linux](#nokia-sr-linux)
- [Fortinet FortiGate](#fortinet-fortigate)
- [Palo Alto PAN-OS](#palo-alto-pan-os)
- [Aruba AOS-CX](#aruba-aos-cx)
- [Dell OS10](#dell-os10)

---

## Cisco IOS/IOS-XE

### Default Credentials
- **Username**: `admin`
- **Password**: `admin`
- **Enable Password**: `admin`

### Basic Startup Config
```
hostname cisco-router
!
enable secret admin
!
username admin privilege 15 secret admin
!
aaa new-model
aaa authentication login default local
aaa authorization exec default local
!
ip domain-name example.com
crypto key generate rsa modulus 2048
!
interface GigabitEthernet1
 description Management
 ip address dhcp
 no shutdown
!
interface GigabitEthernet2
 description Data
 no shutdown
!
line con 0
 login authentication default
 logging synchronous
!
line vty 0 4
 login authentication default
 transport input ssh
!
end
```

### With RADIUS/TACACS+
```
hostname cisco-router
!
enable secret admin
!
username admin privilege 15 secret admin
!
aaa new-model
!
! RADIUS Configuration
radius server portnox-radius
 address ipv4 172.20.20.50 auth-port 1812 acct-port 1813
 key testing123
!
aaa group server radius PORTNOX-RADIUS
 server name portnox-radius
!
! TACACS+ Configuration
tacacs server portnox-tacacs
 address ipv4 172.20.20.51
 port 49
 key tacacskey123
!
aaa group server tacacs+ PORTNOX-TACACS
 server name portnox-tacacs
!
! Authentication
aaa authentication login default group PORTNOX-RADIUS local
aaa authentication login console local
aaa authorization exec default group PORTNOX-TACACS local
aaa authorization commands 15 default group PORTNOX-TACACS local
aaa accounting exec default start-stop group PORTNOX-TACACS
aaa accounting commands 15 default start-stop group PORTNOX-TACACS
!
ip domain-name example.com
crypto key generate rsa modulus 2048
!
line con 0
 login authentication console
 logging synchronous
!
line vty 0 4
 login authentication default
 authorization exec default
 transport input ssh
!
end
```

---

## Cisco IOS-XR

### Default Credentials
- **Username**: `admin`
- **Password**: `admin`

### Basic Startup Config
```
hostname cisco-xr-router
!
username admin
 group root-lr
 group cisco-support
 secret admin
!
interface MgmtEth0/RP0/CPU0/0
 description Management
 ipv4 address dhcp
 no shutdown
!
interface GigabitEthernet0/0/0/0
 description Data
 no shutdown
!
ssh server v2
ssh server vrf default
!
end
```

### With TACACS+
```
hostname cisco-xr-router
!
username admin
 group root-lr
 group cisco-support
 secret admin
!
tacacs-server host 172.20.20.51 port 49
 key tacacskey123
!
tacacs-server timeout 5
!
aaa group server tacacs+ PORTNOX-TACACS
 server 172.20.20.51
!
aaa authentication login default group PORTNOX-TACACS local
aaa authorization exec default group PORTNOX-TACACS local
aaa authorization commands default group PORTNOX-TACACS local
aaa accounting exec default start-stop group PORTNOX-TACACS
aaa accounting commands default start-stop group PORTNOX-TACACS
!
interface MgmtEth0/RP0/CPU0/0
 description Management
 ipv4 address dhcp
 no shutdown
!
ssh server v2
ssh server vrf default
!
end
```

---

## Cisco Nexus (NX-OS)

### Default Credentials
- **Username**: `admin`
- **Password**: `admin`

### Basic Startup Config
```
hostname cisco-nexus
!
feature ssh
feature tacacs+
!
username admin password admin role network-admin
!
interface mgmt0
 description Management
 ip address dhcp
 no shutdown
!
interface Ethernet1/1
 description Data
 no shutdown
!
line vty
!
end
```

### With TACACS+
```
hostname cisco-nexus
!
feature ssh
feature tacacs+
!
username admin password admin role network-admin
!
tacacs-server host 172.20.20.51 key tacacskey123
!
aaa group server tacacs+ PORTNOX-TACACS
 server 172.20.20.51
 use-vrf management
!
aaa authentication login default group PORTNOX-TACACS local
aaa authorization commands default group PORTNOX-TACACS local
aaa accounting default group PORTNOX-TACACS
!
interface mgmt0
 description Management
 ip address dhcp
 no shutdown
!
line vty
!
end
```

---

## Arista cEOS

### Default Credentials
- **Username**: `admin`
- **Password**: `admin`

### Basic Startup Config
```
hostname arista-switch
!
username admin privilege 15 secret admin
!
management api http-commands
 no shutdown
!
interface Management1
 description Management
 ip address dhcp
 no shutdown
!
interface Ethernet1
 description Data
 no shutdown
!
end
```

### With RADIUS/TACACS+
```
hostname arista-switch
!
username admin privilege 15 secret admin
!
! RADIUS Configuration
radius-server host 172.20.20.50 key testing123
!
aaa group server radius PORTNOX-RADIUS
 server 172.20.20.50
!
! TACACS+ Configuration
tacacs-server host 172.20.20.51 key tacacskey123
!
aaa group server tacacs+ PORTNOX-TACACS
 server 172.20.20.51
!
! Authentication
aaa authentication login default group PORTNOX-RADIUS local
aaa authorization exec default group PORTNOX-TACACS local
aaa authorization commands all default group PORTNOX-TACACS local
aaa accounting exec default start-stop group PORTNOX-TACACS
aaa accounting commands all default start-stop group PORTNOX-TACACS
!
management api http-commands
 no shutdown
!
interface Management1
 description Management
 ip address dhcp
 no shutdown
!
end
```

---

## Juniper vMX/vQFX

### Default Credentials
- **Username**: `admin`
- **Password**: `admin`

### Basic Startup Config
```
system {
    host-name juniper-router;
    root-authentication {
        encrypted-password "$1$admin$admin";
    }
    login {
        user admin {
            uid 2000;
            class super-user;
            authentication {
                encrypted-password "$1$admin$admin";
            }
        }
    }
    services {
        ssh;
        netconf {
            ssh;
        }
    }
}
interfaces {
    fxp0 {
        unit 0 {
            description "Management";
            family inet {
                dhcp;
            }
        }
    }
    ge-0/0/0 {
        unit 0 {
            description "Data";
        }
    }
}
```

### With RADIUS/TACACS+
```
system {
    host-name juniper-router;
    root-authentication {
        encrypted-password "$1$admin$admin";
    }
    login {
        user admin {
            uid 2000;
            class super-user;
            authentication {
                encrypted-password "$1$admin$admin";
            }
        }
    }
    radius-server {
        172.20.20.50 {
            port 1812;
            accounting-port 1813;
            secret "testing123";
            source-address 172.20.20.1;
        }
    }
    tacplus-server {
        172.20.20.51 {
            port 49;
            secret "tacacskey123";
            source-address 172.20.20.1;
        }
    }
    authentication-order [ radius tacplus password ];
    accounting {
        events [ login interactive-commands ];
        destination {
            tacplus {
                server {
                    172.20.20.51;
                }
            }
        }
    }
    services {
        ssh;
        netconf {
            ssh;
        }
    }
}
interfaces {
    fxp0 {
        unit 0 {
            description "Management";
            family inet {
                dhcp;
            }
        }
    }
}
```

---

## Nokia SR Linux

### Default Credentials
- **Username**: `admin`
- **Password**: `admin`

### Basic Startup Config
```
set / system information location "ContainerLab"
set / system information contact "admin@example.com"
set / system aaa authentication admin-user password admin

set / interface ethernet-1/1 admin-state enable
set / interface ethernet-1/1 subinterface 0 ipv4 admin-state enable

set / interface mgmt0 admin-state enable
set / interface mgmt0 subinterface 0 admin-state enable
set / interface mgmt0 subinterface 0 ipv4 admin-state enable
set / interface mgmt0 subinterface 0 ipv4 dhcp-client

set / network-instance default type default
set / network-instance default interface ethernet-1/1.0

set / system ssh-server admin-state enable
set / system ssh-server network-instance mgmt
```

### Note on RADIUS/TACACS+
Nokia SR Linux does not support traditional RADIUS/TACACS+ configuration via CLI. Authentication must be configured through the management interface or using external authentication systems integrated with the SR Linux management plane.

---

## Fortinet FortiGate

### Default Credentials
- **Username**: `admin`
- **Password**: `admin`

### Basic Startup Config
```
config system admin
    edit "admin"
        set password admin
    next
end

config system interface
    edit "port1"
        set mode dhcp
        set allowaccess ping https ssh
    next
    edit "port2"
        set mode static
        set ip 192.168.1.1 255.255.255.0
        set allowaccess ping
    next
end

config system global
    set hostname "fortigate-fw"
    set admin-sport 443
end
```

### With RADIUS/TACACS+
```
config system admin
    edit "admin"
        set password admin
    next
end

config user radius
    edit "portnox-radius"
        set server "172.20.20.50"
        set secret "testing123"
        set auth-type auto
    next
end

config user tacacs+
    edit "portnox-tacacs"
        set server "172.20.20.51"
        set key "tacacskey123"
        set authen-type auto
    next
end

config system accprofile
    edit "portnox-admin"
        set secfabgrp read-write
        set ftviewgrp read-write
        set authgrp read-write
        set sysgrp read-write
        set netgrp read-write
        set loggrp read-write
        set fwgrp read-write
        set vpngrp read-write
        set utmgrp read-write
        set wanoptgrp read-write
        set wifi read-write
    next
end

config user group
    edit "portnox-users"
        set member "portnox-radius" "portnox-tacacs"
    next
end

config system admin
    edit "portnox-admin"
        set remote-auth enable
        set accprofile "portnox-admin"
        set vdom "root"
        set wildcard enable
        set remote-group "portnox-users"
    next
end

config system interface
    edit "port1"
        set mode dhcp
        set allowaccess ping https ssh
    next
end

config system global
    set hostname "fortigate-fw"
end
```

---

## Palo Alto PAN-OS

### Default Credentials
- **Username**: `admin`
- **Password**: `admin`

### Basic Startup Config (XML)
```xml
<config>
  <devices>
    <entry name="localhost.localdomain">
      <deviceconfig>
        <system>
          <hostname>paloalto-fw</hostname>
          <dns-setting>
            <servers>
              <primary>8.8.8.8</primary>
              <secondary>8.8.4.4</secondary>
            </servers>
          </dns-setting>
        </system>
      </deviceconfig>
      <network>
        <interface>
          <ethernet>
            <entry name="ethernet1/1">
              <layer3>
                <dhcp-client>
                  <enable>yes</enable>
                </dhcp-client>
              </layer3>
            </entry>
          </ethernet>
        </interface>
      </network>
      <vsys>
        <entry name="vsys1">
          <zone>
            <entry name="trust">
              <network>
                <layer3>
                  <member>ethernet1/1</member>
                </layer3>
              </network>
            </entry>
          </zone>
        </entry>
      </vsys>
    </entry>
  </devices>
  <mgt-config>
    <users>
      <entry name="admin">
        <phash>$1$admin$admin</phash>
        <permissions>
          <role-based>
            <superuser>yes</superuser>
          </role-based>
        </permissions>
      </entry>
    </users>
  </mgt-config>
</config>
```

---

## Aruba AOS-CX

### Default Credentials
- **Username**: `admin`
- **Password**: `admin`

### Basic Startup Config
```
hostname aruba-switch
!
user admin group administrators password plaintext admin
!
interface mgmt
 no shutdown
 ip dhcp
!
interface 1/1/1
 no shutdown
 description Data
!
ssh server vrf mgmt
!
https-server vrf mgmt
```

### With RADIUS/TACACS+
```
hostname aruba-switch
!
user admin group administrators password plaintext admin
!
! RADIUS Configuration
radius-server host 172.20.20.50 key plaintext testing123
!
aaa group server radius PORTNOX-RADIUS
 server 172.20.20.50
!
! TACACS+ Configuration
tacacs-server host 172.20.20.51 key plaintext tacacskey123
!
aaa group server tacacs+ PORTNOX-TACACS
 server 172.20.20.51
!
! Authentication
aaa authentication login default group PORTNOX-RADIUS local
aaa authorization commands default group PORTNOX-TACACS local
aaa accounting all default start-stop group PORTNOX-TACACS
!
interface mgmt
 no shutdown
 ip dhcp
!
ssh server vrf mgmt
https-server vrf mgmt
```

---

## Dell OS10

### Default Credentials
- **Username**: `admin`
- **Password**: `admin`

### Basic Startup Config
```
hostname dell-switch
!
username admin password admin role sysadmin
!
interface mgmt 1/1/1
 no shutdown
 ip address dhcp
!
interface ethernet 1/1/1
 no shutdown
 description Data
!
end
```

### With TACACS+
```
hostname dell-switch
!
username admin password admin role sysadmin
!
tacacs-server host 172.20.20.51 key tacacskey123
!
aaa group server tacacs+ PORTNOX-TACACS
 server 172.20.20.51
!
aaa authentication login default group PORTNOX-TACACS local
aaa authorization commands all default group PORTNOX-TACACS local
aaa accounting commands all default start-stop group PORTNOX-TACACS
!
interface mgmt 1/1/1
 no shutdown
 ip address dhcp
!
end
```

---

## Usage in ContainerLab

### Method 1: Inline Startup Config
```yaml
nodes:
  cisco-router:
    kind: cisco_csr1000v
    image: vrnetlab/vr-csr:17.03.06
    startup-config: |
      hostname cisco-router
      username admin privilege 15 secret admin
      !
      interface GigabitEthernet1
       ip address dhcp
       no shutdown
```

### Method 2: External Config File
```yaml
nodes:
  cisco-router:
    kind: cisco_csr1000v
    image: vrnetlab/vr-csr:17.03.06
    startup-config: /data/configs/vendor-startup-configs/cisco/router-basic.cfg
```

### Method 3: Bind Mount Config Directory
```yaml
nodes:
  cisco-router:
    kind: cisco_csr1000v
    image: vrnetlab/vr-csr:17.03.06
    binds:
      - /data/configs/vendor-startup-configs/cisco:/configs
    startup-config: /configs/router-basic.cfg
```

---

## Important Notes

1. **VRNetlab Images**: Most vendor images (Cisco, Juniper, Palo Alto, etc.) require VRNetlab to convert QCOW2/VMDK images to Docker containers. See VRNetlab documentation for building images.

2. **Default Passwords**: Always change default passwords in production environments. These configs are for lab/testing purposes only.

3. **RADIUS/TACACS+ Secrets**: Use strong, unique secrets for each deployment. Never use "testing123" or "tacacskey123" in production.

4. **Management Access**: Ensure management interfaces are properly secured and not exposed to untrusted networks.

5. **Config Persistence**: Some platforms require additional steps to save configurations permanently. Consult vendor documentation.

6. **Licensing**: Some vendor images require valid licenses to enable full functionality.

---

## Additional Resources

- **VRNetlab**: https://github.com/vrnetlab/vrnetlab
- **ContainerLab**: https://containerlab.dev
- **Vendor Documentation**: Consult each vendor's official documentation for detailed configuration guides
