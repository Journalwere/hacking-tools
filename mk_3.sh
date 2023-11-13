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

# Prompt the user to choose tools
echo "Choose which tools to use:"
echo "1. ffuf"
echo "2. gobuster"
echo "3. nmap"
echo "4. nikto"

# Array to store selected tools
selected_tools=()

# Read user's tool selections
while true; do
    read -p "Enter the number of a tool (0 to finish): " choice
    case $choice in
        0)
            break
            ;;
        1)
            selected_tools+=("ffuf")
            ;;
        2)
            selected_tools+=("gobuster")
            ;;
        3)
            selected_tools+=("nmap")
            ;;
        4)
            selected_tools+=("nikto")
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac
done

# Debug: Print selected tools
echo "Selected tools: ${selected_tools[@]}"

# Prompt the user to choose a wordlist for ffuf if selected
if [[ " ${selected_tools[@]} " =~ "ffuf" ]]; then
    ffuf_wordlist_dir="/usr/share/wordlists/dirb"
    echo "Choose a wordlist for ffuf:"
    select ffuf_wordlist_path in "$ffuf_wordlist_dir"/*; do
        if [ -n "$ffuf_wordlist_path" ]; then
            echo "Selected wordlist for ffuf: $ffuf_wordlist_path"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done
fi

# Prompt the user to choose a wordlist for gobuster if selected
if [[ " ${selected_tools[@]} " =~ "gobuster" ]]; then
    gobuster_wordlist_dir="/usr/share/wordlists/dirbuster"
    echo "Choose a wordlist for gobuster:"
    select gobuster_wordlist_path in "$gobuster_wordlist_dir"/*; do
        if [ -n "$gobuster_wordlist_path" ]; then
            echo "Selected wordlist for gobuster: $gobuster_wordlist_path"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done
fi

# Debug: Print wordlist paths
echo "FFUF wordlist: $ffuf_wordlist_path"
echo "Gobuster wordlist: $gobuster_wordlist_path"

# Ask the user if they want to open Burp Suite
read -p "Do you want to open Burp Suite? (y/n): " open_burp

# Debug: Print Burp Suite selection
echo "Open Burp Suite: $open_burp"

# Launch Burp Suite if requested
if [[ $open_burp == "y" || $open_burp == "Y" ]]; then
    gnome-terminal --title="Burp Suite" -- bash -c "java -jar -Xmx4g /home/kali/Downloads/burpsuite_community_v2023.5.2.jar; read -p 'Press Enter to close Burp Suite'"
fi

# Run selected tools
for tool in "${selected_tools[@]}"; do
    case $tool in
        "ffuf")
            # Open new GNOME Terminal window for ffuf subdomain scanning and keep it open after execution
            echo "Running ffuf..."
            gnome-terminal --title="FFUF" -- bash -c "ffuf -c -w \"$ffuf_wordlist_path\" -u \"$url\" -H \"Host: FUZZ.$url\" -fl 8; read -p 'Press Enter to close this terminal'"
            ;;
        "gobuster")
            # Prompt the user to enter a filetype for gobuster
            echo "Enter a filetype for gobuster:"
            read filetype

            # Open new GNOME Terminal window for Gobuster directory scanning and keep it open after execution
            echo "Running gobuster..."
            gnome-terminal --title="Gobuster" -- bash -c "gobuster dir -w \"$gobuster_wordlist_path\" -u \"$url\" -x \"$filetype\"; read -p 'Press Enter to close this terminal'"
            ;;
        "nmap")
            for ip in "${ip_addresses[@]}"; do
                # Open new GNOME Terminal window for Nmap scan and keep it open after execution
                echo "Running Nmap on $ip..."
                gnome-terminal --title="Nmap $ip" -- bash -c "sudo nmap -sV -O -T4 \"$ip\" -oX scan_$ip.xml; read -p 'Press Enter to close this terminal'"

                # Open new GNOME Terminal window for searchsploit scan and keep it open after execution
                echo "Running searchsploit on $ip..."
                gnome-terminal --title="Searchsploit $ip" -- bash -c "while [[ ! -f \"scan_$ip.xml\" ]]; do sleep 1; done; searchsploit -x --nmap scan_$ip.xml; read -p 'Press Enter to close this terminal'"
            done
            ;;
        "nikto")
            for ip in "${ip_addresses[@]}"; do
                # Open new GNOME Terminal window for Nikto scan and keep it open after execution
                echo "Running Nikto on $ip..."
                gnome-terminal --title="Nikto $ip" -- bash -c "nikto -h \"$url\"; read -p 'Press Enter to close this terminal'"
            done
            ;;
        *)
            echo "Unknown tool: $tool"
            ;;
    esac
done

# Cleanup after completing the scans or on interrupt
cleanup
