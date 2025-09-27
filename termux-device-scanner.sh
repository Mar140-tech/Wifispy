#!/data/data/com.termux/files/usr/bin/bash

# Termux Device Scanner - With MAC Address & Menu
# Requires: ping, arp, ip, (optional: nmap)

function get_local_subnet() {
    # Find first non-loopback IP/subnet
    ip=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -n 1)
    [ -n "$ip" ] && echo "$ip" || echo "192.168.1.0/24"
}

function show_menu() {
    echo -e "\033[1;34mTermux Device Scanner\033[0m"
    echo "1) Use detected local subnet"
    echo "2) Enter custom subnet (CIDR, e.g. 192.168.0.0/24)"
    read -p "Select subnet option [1-2]: " subnet_choice

    if [ "$subnet_choice" = "2" ]; then
        read -p "Enter subnet (CIDR): " subnet
    else
        subnet=$(get_local_subnet)
    fi

    echo "Scan type:"
    echo "1) Ping Sweep (Fast, shows MAC & Hostname)"
    echo "2) Nmap Scan (Detailed, requires nmap)"
    read -p "Choose scan type [1-2]: " scan_choice

    echo "Save results to file?"
    echo "1) Yes"
    echo "2) No"
    read -p "Save? [1-2]: " save_choice

    scan_network "$subnet" "$scan_choice" "$save_choice"
}

function ping_sweep() {
    subnet="$1"
    base=$(echo $subnet | cut -d'/' -f1 | cut -d'.' -f1-3)
    echo -e "Scanning \033[1;32m${base}.0/24\033[0m ..."
    printf "% -15s %-20s %-30s\n" "IP" "MAC Address" "Hostname"
    for i in $(seq 1 254); do
        ip="${base}.${i}"
        ping -c 1 -W 1 $ip >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            mac=$(arp -a | grep "($ip)" | awk '{print $4}' | head -n 1)
            host=$(nslookup $ip 2>/dev/null | grep 'name = ' | awk '{print $4}' | sed 's/\.$//')
            printf "% -15s %-20s %-30s\n" "$ip" "${mac:-Unknown}" "${host:-No Hostname}"
        fi
    done
    echo "Scan complete."
}

function nmap_scan() {
    subnet="$1"
    echo "Running nmap scan on $subnet ..."
    nmap -sn $subnet | tee nmap_scan_results.txt
}

function scan_network() {
    subnet="$1"
    scan_choice="$2"
    save_choice="$3"

    if [ "$scan_choice" = "1" ]; then
        ping_sweep "$subnet" | tee scan_results.txt
        result_file="scan_results.txt"
    elif [ "$scan_choice" = "2" ]; then
        nmap_scan "$subnet"
        result_file="nmap_scan_results.txt"
    else
        echo "Invalid scan type."
        exit 1
    fi

    if [ "$save_choice" = "1" ]; then
        read -p "Enter filename to save results: " filename
        cp "$result_file" "$filename"
        echo "Results saved to $filename."
    fi
    echo "Done."
}

# Entry point
show_menu
