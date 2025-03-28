

![portscepx_logo](https://github.com/user-attachments/assets/80520eed-b422-411e-8a85-09873c1e4c1d)



PortScepX
SCEP Certificate Enrollment and 802.1X Authentication Setup Tool
Overview
PortScepX is a robust shell script that automates the process of obtaining certificates via the SCEP (Simple Certificate Enrollment Protocol) and configuring 802.1X authentication for network interfaces on Linux systems. The script supports both direct enrollment (using OpenSSL and sscep) and certmonger-based certificate management, making it flexible for various deployment scenarios.
Features

Multiple Enrollment Methods: Direct (OpenSSL+sscep) or Certmonger-based
User/Device Certificates: Generate certificates for devices or individual users
Network Configuration: Automatically configure NetworkManager for 802.1X authentication
Multiple EAP Methods: Support for TLS, PEAP, and TTLS authentication types
Interactive Menu: User-friendly menu-driven interface
Troubleshooting Tools: Built-in diagnostics and validation tools
APT Repository Repair: Automatic fixing of common APT issues
Certificate Management: Tools for listing, validating, and cleaning certificates

Requirements

Linux distribution (Ubuntu, Debian, RHEL, CentOS, or Fedora)
NetworkManager for network configuration
sudo privileges for certificate and network operations
Internet connectivity to download certificates and dependencies

Installation

Download the script:
wget https://github.com/portnox/portscepx/raw/main/PortScepX.sh

Make it executable:
chmod +x PortScepX.sh

Run the script with sudo:
sudo ./PortScepX.sh


Usage
Interactive Mode
Simply run the script without arguments to enter the interactive menu:
sudo ./PortScepX.sh
From the menu, you can:

Configure and Setup 802.1X
Clean up certificates and CAs
Validate existing certificates
Run troubleshooting
Check dependency versions
View help documentation
List certificates and CAs
Show manual enrollment steps
View SSCEP installation instructions
Fix APT repository issues

Command Line Options
Usage: ./PortScepX.sh [OPTIONS]

Options:
  -h, --help           Show this help message and exit
  -v, --verbose        Enable verbose output and detailed logging
  -d, --dry-run        Simulate without making changes
  -c, --config FILE    Use specific configuration file
  --direct             Use direct OpenSSL+sscep enrollment
  --certmonger         Use certmonger enrollment
  --clean              Clean up existing certificates and CAs before running
  --no-updates         Skip apt/yum update checks
  --fix-apt            Fix APT repository issues before running
  --list-certs         List all certificates and CAs
  --show-sscep-install Show SSCEP installation instructions
Examples

Run in verbose mode:
sudo ./PortScepX.sh -v

Clean existing certificates before setup:
sudo ./PortScepX.sh --clean

Use direct enrollment method:
sudo ./PortScepX.sh --direct

Skip system updates:
sudo ./PortScepX.sh --no-updates

Fix APT repository issues:
sudo ./PortScepX.sh --fix-apt


Troubleshooting
If you encounter issues:

Run with verbose flag:
sudo ./PortScepX.sh -v

Check logs:
cat /var/log/portnox_setup.log

Use the built-in troubleshooting option (menu option 4)
If you have APT repository issues:
sudo ./PortScepX.sh --fix-apt

If SSCEP fails to install automatically, view manual installation steps:
sudo ./PortScepX.sh --show-sscep-install


Uninstallation
To remove SSCEP and Certmonger:
# For Debian/Ubuntu
sudo apt-get remove sscep certmonger
sudo apt-get autoremove

# For RHEL/CentOS/Fedora
sudo dnf remove sscep certmonger
To clean up certificates and configuration:
sudo ./PortScepX.sh --clean
License
MIT License
Contributing
Contributions are welcome! Please feel free to submit pull requests or report issues.
Author
Portnox Security
Version
1.4.1 - Last Updated: March 28, 2025
