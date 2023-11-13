#!/bin/bash

cleanup() {
    # Cleanup logic
    echo "Script interrupted. Cleaning up..."
    # Kill background processes and remove temporary files
    kill -SIGTERM $GOBUSTER_PID &> /dev/null
    # ... (similar cleanup for other tools)
    exit
}

trap cleanup SIGINT

get_protocol() {
    # Function to get the protocol (HTTP or HTTPS) from the user
    select service in "HTTP" "HTTPS"; do
        case $service in
            "HTTP") protocol="http://"; break;;
            "HTTPS") protocol="https://"; break;;
            *) echo "Invalid choice. Please try again.";;
        esac
    done
}

get_url() {
    # Function to get the URL from the user
    read -p "Enter the URL (without protocol): " url
}

get_ip_addresses() {
    # Function to get IP addresses from the user
    echo "Enter IP addresses (space-separated):"
    read -a ip_addresses
}

select_tools() {
    # Function to select penetration testing tools
    echo "Choose which tools to use:"
    echo "1. gobuster"
    echo "2. nikto"
    echo "3. nuclei"
    echo "4. nmap"

    selected_tools=()

    while true; do
        read -p "Enter the number of a tool (0 to finish): " choice
        case $choice in
            0) break;;
            1) selected_tools+=("gobuster");;
            2) selected_tools+=("nikto");;
            3) selected_tools+=("nuclei");;
            4) selected_tools+=("nmap");;
            *) echo "Invalid choice. Please try again.";;
        esac
    done
}

get_gobuster_wordlist() {
    # Function to get the gobuster wordlist
    gobuster_wordlist_dir="/usr/share/wordlists/dirbuster"
    echo "Choose a wordlist for gobuster:"
    select gobuster_wordlist_path in "$gobuster_wordlist_dir"/*; do
        [ -n "$gobuster_wordlist_path" ] && break || echo "Invalid selection. Please try again."
    done
}

open_burp_suite() {
    # Function to open Burp Suite
    read -p "Do you want to open Burp Suite? (y/n): " open_burp

    if [[ $open_burp == "y" || $open_burp == "Y" ]]; then
        gnome-terminal --title="Burp Suite" -- bash -c "java -jar -Xmx4g /home/kali/Downloads/burpsuite_community_v2023.5.2.jar; read -p 'Press Enter to close Burp Suite'"
    fi
}

run_tools() {
    # Function to run selected penetration testing tools
    for tool in "${selected_tools[@]}"; do
        case $tool in
            "gobuster") run_gobuster;;
            "nikto") run_nikto;;
            "nuclei") run_nuclei;;
            "nmap") run_nmap;;
            *) echo "Unknown tool: $tool";;
        esac
    done
}

run_gobuster() {
    # Function to run gobuster
    echo "Enter a filetype for gobuster:"
    read filetype

    gnome-terminal --title="Gobuster" -- bash -c "gobuster dir -w \"$gobuster_wordlist_path\" -u \"$protocol$url\" -x \"$filetype\" | tee -a gobuster_results.txt; read -p 'Press Enter to close this terminal'"
}

run_nikto() {
    # Function to run nikto
    for ip in "${ip_addresses[@]}"; do
        gnome-terminal --title="Nikto $ip" -- bash -c "nikto -h \"$protocol$url\" | tee -a nikto_results.txt; read -p 'Press Enter to close this terminal'"
    done
}

run_nuclei() {
    # Function to run nuclei
    for ip in "${ip_addresses[@]}"; do
        gnome-terminal --title="Nuclei Scan" -- bash -c "nuclei -u \"$url\" | tee -a nuclei_results.txt; read -p 'Press Enter to close this terminal'"
    done
}

run_nmap() {
    # Function to run nmap
    for ip in "${ip_addresses[@]}"; do
        gnome-terminal --title="Nmap $ip" -- bash -c "sudo nmap -p- -sV -O -T4 \"$ip\" -oX scan.xml | tee -a nmap_results.txt; read -p 'Press Enter to close this terminal'"

        read -p "Do you want to initiate the searchsploit scan for $ip? (y/n): " initiate_searchsploit

        if [[ $initiate_searchsploit == "y" || $initiate_searchsploit == "Y" ]]; then
            gnome-terminal --title="Searchsploit $ip" -- bash -c "searchsploit -x --nmap scan.xml | tee -a searchsploit_results.txt; read -p 'Press Enter to close this terminal'"
        fi
    done
}

generate_comprehensive_report() {
    # Function to generate a comprehensive report
    echo "Generating comprehensive report..."
    cat nmap_results.txt gobuster_results.txt searchsploit_results.txt nikto_results.txt nuclei_results.txt > comprehensive_report.txt
    echo "Nmap headers information:" >> comprehensive_report.txt
    grep -oP '(?<=<service name=").*(?=")' scan.xml >> comprehensive_report.txt
    cat comprehensive_report.txt
}

# Main script logic

get_protocol
get_url
get_ip_addresses
select_tools

if [[ " ${selected_tools[@]} " =~ "gobuster" ]]; then
    get_gobuster_wordlist
fi

open_burp_suite
run_tools
generate_comprehensive_report
cleanup
