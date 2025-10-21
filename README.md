# Wifispy - Termux Device Scanner

termux-device-scanner.sh is a small shell script intended for use in Termux (Android) or other Linux environments to discover devices on a local network. It performs a ping sweep, shows MAC addresses and reverse DNS hostnames, and can optionally run nmap for more detailed scans.

Requirements
- Termux: bash, ip (iproute2), ping, nslookup (dnsutils), arp (optional)
- On Debian/Ubuntu: sudo apt update && sudo apt install iproute2 iputils-ping dnsutils net-tools
- Optional: nmap (for detailed scans)

Installation & Usage
1. Clone this repository or download the script file.
2. Make the script executable (the repository stores the executable bit already):
   chmod +x termux-device-scanner.sh
3. Run the script:
   ./termux-device-scanner.sh
4. Follow the interactive menu to select subnet, scan type, and save options.

Notes
- The script uses a portable shebang (#!/usr/bin/env bash) so it works both in Termux and standard Linux.
- If using on networks that are not /24, provide the CIDR when prompted. The ping sweep currently assumes a /24 range for scanning.
- Running network scans may require appropriate permissions on managed networks. Use responsibly and only on networks you own or are authorized to scan.

License
This repository contains no explicit license. If you want to add a license (recommended), add a LICENSE file (for example MIT).
