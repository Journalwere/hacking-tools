#!/bin/bash

# Function to handle keyboard interrupt
function cleanup() {
    echo "Script interrupted. Cleaning up..."
    # Kill background processes
    kill -SIGTERM $FFUF_PID &> /dev/null
    kill -SIGTERM $GOBUSTER_PID &> /dev/null
    exit
}

# Set keyboard interrupt signal handler
trap cleanup SIGINT

# Prompt the user to enter a URL
#echo "Enter a URL:"
#read url

# Prompt the user to enter IP addresses
echo "Enter IP addresses (space-separated):"
read -a ip_addresses

# Subdomain scanning with ffuf (run in the background)
#osascript -e 'tell application "iTerm2" to activate' -e 'tell application "iTerm2" to create window with default profile' -e 'tell application "iTerm2" to tell current session of current window to write text "ffuf -c -w /usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-110000.txt -u \"$url\" -H \"Host: FUZZ.$ip_addresses\" -fl 8"'

# Gobuster directory scanning (run in a new terminal window)
#osascript -e 'tell application "iTerm2" to activate' -e 'tell application "iTerm2" to create window with default profile' -e 'tell application "iTerm2" to tell current session of current window to write text "gobuster dir -w /usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt -u \"$url\""'


# Iterate over IP addresses and run searchsploit for each
for ip in "${ip_addresses[@]}"
do
    # Nmap scan for open ports
    osascript -e 'tell application "iTerm2" to activate' -e 'tell application "iTerm2" to create window with default profile' -e "tell application \"iTerm2\" to tell current session of current window to write text \"sudo nmap -p- -sV -O -T4 \\\"$ip\\\" -oX scan_$ip.xml\""

    # Delay for nmap command to finish
    sleep 5

    # Wait for the XML file to be created
    while [[ ! -f "scan_$ip.xml" ]]
    do
        sleep 5
    done

    # searchsploit scan
    osascript -e 'tell application "iTerm2" to activate' -e 'tell application "iTerm2" to create window with default profile' -e "tell application \"iTerm2\" to tell current session of current window to write text \"searchsploit -x --nmap scan_$ip.xml\""
done

# Cleanup after completing the scans or on interrupt
cleanup
