#!/usr/bin/env bash

# Termux Device Scanner - With MAC Address & Menu
# Portable shebang for GitHub and Termux
# Requires: ping, arp (or ip), nslookup, (optional: nmap)

set -euo pipefail
IFS=$'\n\t'

function get_local_subnet() {
    # Find first non-loopback IP/subnet (returns in CIDR form if available)
    ip_cidr=$(ip addr show scope global | grep 'inet ' | awk '{print $2}' | head -n 1 || true)
    if [ -n "$ip_cidr" ]; then
        echo "$ip_cidr"
    else
        echo "192.168.1.0/24"
    fi
}

function show_menu() {
    echo -e "\033[1;34mTermux Device Scanner\033[0m"
    echo "1) Use detected local subnet"
    echo "2) Enter custom subnet (CIDR, e.g. 192.168.0.0/24)"
    read -rp "Select subnet option [1-2]: " subnet_choice

    if [ "$subnet_choice" = "2" ]; then
        read -rp "Enter subnet (CIDR): " subnet
    else
        subnet=$(get_local_subnet)
    fi

    echo "Scan type:"
    echo "1) Ping Sweep (Fast, shows MAC & Hostname)"
    echo "2) Nmap Scan (Detailed, requires nmap)"
    read -rp "Choose scan type [1-2]: " scan_choice

    echo "Save results to file?"
    echo "1) Yes"
    echo "2) No"
    read -rp "Save? [1-2]: " save_choice

    scan_network "$subnet" "$scan_choice" "$save_choice"
}

function ping_sweep() {
    subnet="$1"
    # base: take first three octets of the IPv4 address portion
    base=$(echo "$subnet" | cut -d'/' -f1 | awk -F'.' '{print $1"."$2"."$3}')
    echo -e "Scanning \033[1;32m${base}.0/24\033[0m ..."
    printf "% -15s %-20s %-30s\n" "IP" "MAC Address" "Hostname"
    for i in $(seq 1 254); do
        ip_addr="${base}.${i}"
        if ping -c 1 -W 1 "$ip_addr" >/dev/null 2>&1; then
            mac=""
            # Try ip neigh first (more modern than arp)
            if command -v ip >/dev/null 2>&1; then
                mac=$(ip neigh show "$ip_addr" 2>/dev/null | awk '{print $5}' | head -n 1 || true)
            fi
            if [ -z "$mac" ]; then
                mac=$(arp -a | grep "($ip_addr)" | awk '{print $4}' | head -n 1 || true)
            fi
            host=$(nslookup "$ip_addr" 2>/dev/null | grep 'name = ' | awk '{print $4}' | sed 's/\.$//' || true)
            printf "% -15s %-20s %-30s\n" "$ip_addr" "${mac:-Unknown}" "${host:-No Hostname}"
        fi
    done
    echo "Scan complete."
}

function nmap_scan() {
    subnet="$1"
    if ! command -v nmap >/dev/null 2>&1; then
        echo "nmap not found. Install nmap to use this option." >&2
        return 1
    fi
    echo "Running nmap scan on $subnet ..."
    nmap -sn "$subnet" | tee nmap_scan_results.txt
}

function scan_network() {
    subnet="$1"
    scan_choice="$2"
    save_choice="$3"

    if [ "$scan_choice" = "1" ]; then
        ping_sweep "$subnet" | tee scan_results.txt
        result_file="scan_results.txt"
    elif [ "$scan_choice" = "2" ]; then
        if nmap_scan "$subnet"; then
            result_file="nmap_scan_results.txt"
        else
            echo "nmap scan failed or nmap missing." >&2
            exit 1
        fi
    else
        echo "Invalid scan type." >&2
        exit 1
    fi

    if [ "$save_choice" = "1" ]; then
        read -rp "Enter filename to save results: " filename
        cp "$result_file" "$filename"
        echo "Results saved to $filename."
    fi
    echo "Done."
}

# Entry point
if [ "
${BASH_SOURCE[0]}" = "$0" ]; then
    show_menu
fi
