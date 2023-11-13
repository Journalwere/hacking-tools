#!/bin/bash

# Function to handle keyboard interrupt
function cleanup() {
    echo "Script interrupted. Cleaning up..."
    # Kill background processes
    kill -SIGTERM $GOBUSTER_PID &> /dev/null
    kill -SIGTERM $NIKTO_PID &> /dev/null
    kill -SIGTERM $NUCLEI_PID &> /dev/null
    kill -SIGTERM $NMAP_PID &> /dev/null
    rm -f scan.xml &> /dev/null
    rm -f gobuster_results.txt &> /dev/null
    rm -f searchsploit_results.txt &> /dev/null
    rm -f nikto_results.txt &> /dev/null
    rm -f nuclei_results.txt &> /dev/null
    rm -f nmap_results.txt &> /dev/null
    exit
}

# Set keyboard interrupt signal handler
trap cleanup SIGINT

# Prompt the user to choose the service (HTTP or HTTPS)
echo "Choose the service:"
select service in "HTTP" "HTTPS"; do
    case $service in
        "HTTP")
            protocol="http://"
            break
            ;;
        "HTTPS")
            protocol="https://"
            break
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac
done

# Prompt the user to enter a URL without the protocol
read -p "Enter the URL (without protocol): " url

# Prompt the user to enter IP addresses
echo "Enter IP addresses (space-separated):"
read -a ip_addresses

# Prompt the user to choose tools
echo "Choose which tools to use:"
echo "1. gobuster"
echo "2. nikto"
echo "3. nuclei"
echo "4. nmap"

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
            selected_tools+=("gobuster")
            ;;
        2)
            selected_tools+=("nikto")
            ;;
        3)
            selected_tools+=("nuclei")
            echo "Choose Nuclei templates to use (space-separated):"
            read -a selected_templates
            templates+=("${selected_templates[@]}")
            ;;
        4)
            selected_tools+=("nmap")
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac
done

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

# Ask the user if they want to open Burp Suite
read -p "Do you want to open Burp Suite? (y/n): " open_burp

if [[ $open_burp == "y" || $open_burp == "Y" ]]; then
    osascript -e 'tell application "iTerm"
        create window with default profile
        tell current window
            create tab with default profile
            tell current session
                write text "java -jar -Xmx4g /home/kali/Downloads/burpsuite_community_v2023.5.2.jar"
            end tell
        end tell
        activate
    end tell'
    read -p "Press Enter to close Burp Suite"
fi

# Run selected tools and capture the output to separate files
for tool in "${selected_tools[@]}"; do
    case $tool in
        "gobuster")
            echo "Enter a filetype for gobuster:"
            read filetype

            osascript -e 'tell application "iTerm"
                create window with default profile
                tell current window
                    create tab with default profile
                    tell current session
                        write text "gobuster dir -w \"$gobuster_wordlist_path\" -u \"$protocol$url\" -x \"$filetype\""
                    end tell
                end tell
                activate
            end tell'
            read -p "Press Enter to close this terminal"
            ;;
        "nikto")
            for ip in "${ip_addresses[@]}"; do
                osascript -e 'tell application "iTerm"
                    create window with default profile
                    tell current window
                        create tab with default profile
                        tell current session
                            write text "nikto -h \"$protocol$url\""
                        end tell
                    end tell
                    activate
                end tell'
                read -p "Press Enter to close this terminal"
            done
            ;;
        "nuclei")
            for template in "${templates[@]}"; do
                osascript -e 'tell application "iTerm"
                    create window with default profile
                    tell current window
                        create tab with default profile
                        tell current session
                            write text "nuclei -u \"$url\" -t \"$template\""
                        end tell
                    end tell
                    activate
                end tell'
                read -p "Press Enter to close this terminal"
            done
            ;;
        "nmap")
            for ip in "${ip_addresses[@]}"; do
                osascript -e 'tell application "iTerm"
                    create window with default profile
                    tell current window
                        create tab with default profile
                        tell current session
                            write text "sudo nmap -p- -sV -O -T4 \"$ip\" -oX scan.xml"
                        end tell
                    end tell
                    activate
                end tell'
                read -p "Press Enter to close this terminal"

                read -p "Do you want to initiate the searchsploit scan for $ip? (y/n): " initiate_searchsploit

                if [[ $initiate_searchsploit == "y" || $initiate_searchsploit == "Y" ]]; then
                    osascript -e 'tell application "iTerm"
                        create window with default profile
                        tell current window
                            create tab with default profile
                            tell current session
                                write text "searchsploit -x --nmap scan.xml"
                            end tell
                        end tell
                        activate
                    end tell'
                    read -p "Press Enter to close this terminal"
                fi
            done
            ;;
        *)
            echo "Unknown tool: $tool"
            ;;
    esac
done

# Generate a comprehensive report by combining all the results
echo "Generating comprehensive report..."

# Combine nmap, gobuster, and searchsploit results
cat nmap_results.txt gobuster_results.txt searchsploit_results.txt nikto_results.txt nuclei_results.txt > comprehensive_report.txt

# Add headers information from the nmap scan
echo "Nmap headers information:" >> comprehensive_report.txt
grep -oP '(?<=<service name=").*(?=")' scan.xml >> comprehensive_report.txt

# Print the comprehensive report to the console
cat comprehensive_report.txt

# Cleanup after completing the scans or on interrupt
cleanup
