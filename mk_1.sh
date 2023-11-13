#!/bin/bash

# Function to handle keyboard interrupt
function cleanup() {
    echo "Script interrupted. Cleaning up..."
    # Kill background processes
    kill -SIGTERM $FFUF_PID &> /dev/null
    kill -SIGTERM $GOBUSTER_PID &> /dev/null
    kill -SIGTERM $NIKTO_PID &> /dev/null
    exit
}

# Set keyboard interrupt signal handler
trap cleanup SIGINT

# Prompt the user to enter a URL
echo "Enter a URL:"
read url

# Prompt the user to enter IP addresses
echo "Enter IP addresses (space-separated):"
read -a ip_addresses

echo "Enter filetype for gobuster"
read filetype

wordlist_dir="/usr/share/wordlists/dirbuster"

echo "Choose a wordlist:"
select wordlist_path in "$wordlist_dir"/*; do
    if [ -n "$wordlist_path" ]; then
        echo "Selected wordlist: $wordlist_path"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done


# Open new GNOME Terminal window for ffuf subdomain scanning and keep it open after execution
gnome-terminal --title="FFUF" -- bash -c "ffuf -c -w /usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-110000.txt -u \"$url\" -H \"Host: FUZZ.$ip_addresses\" -fl 8; read -p 'Press Enter to close this terminal'"

# Open new GNOME Terminal window for Gobuster directory scanning and keep it open after execution
gnome-terminal --title="Gobuster" -- bash -c "gobuster dir -w \"$wordlist_path\" -u \"$url\" -x \"$filetype\"; read -p 'Press Enter to close this terminal'"

# Open new GNOME Terminal window for Nikto scan and keep it open after execution
gnome-terminal --title="Nikto" -- bash -c "for ip in \"${ip_addresses[@]}\"; do nikto -h \"$url\"; read -p 'Press Enter to close this terminal'; done"

# Iterate over IP addresses and run Nmap and searchsploit for each
for ip in "${ip_addresses[@]}"
do
    # Open new GNOME Terminal window for Nmap scan and keep it open after execution
    gnome-terminal --title="Nmap $ip" -- bash -c "sudo nmap -p- -sV -O -T4 \"$ip\" -oX scan_$ip.xml; read -p 'Press Enter to close this terminal'"

    # Wait for the XML file to be created
    while [[ ! -f "scan_$ip.xml" ]]
    do
        sleep 300
    done

    # Open new GNOME Terminal window for searchsploit scan and keep it open after execution
    gnome-terminal --title="Searchsploit $ip" -- bash -c "searchsploit -x --nmap scan_$ip.xml; read -p 'Press Enter to close this terminal'"
done

# Cleanup after completing the scans or on interrupt
cleanup
