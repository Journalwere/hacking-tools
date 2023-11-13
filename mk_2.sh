#!/bin/bash

# Function to handle keyboard interrupt
function cleanup() {
    echo "Script interrupted. Cleaning up..."
    # Kill background processes
    kill -SIGTERM $FFUF_PID &> /dev/null
    kill -SIGTERM $GOBUSTER_PID &> /dev/null
    kill -SIGTERM $NIKTO_PID &> /dev/null
    # Close tmux session
    tmux kill-session -t scanner
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

# Create a new tmux session
tmux new-session -d -s scanner

# Split the window vertically into three panes
tmux split-window -v -t scanner
tmux select-pane -t 0

# Run ffuf in the first pane
tmux send-keys "ffuf -c -w /usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-110000.txt -u \"$url\" -H \"Host: FUZZ.$ip_addresses\" -fl 8; read -p 'Press Enter to close this terminal'" C-m

# Split the second pane horizontally
tmux split-window -h -t scanner
tmux select-pane -t 1

# Run gobuster in the second pane
tmux send-keys "gobuster dir -w \"$wordlist_path\" -u \"$url\" -x \"$filetype\"; read -p 'Press Enter to close this terminal'" C-m

# Split the third pane horizontally
tmux split-window -h -t scanner
tmux select-pane -t 2

# Run nikto in the third pane
tmux send-keys "for ip in \"${ip_addresses[@]}\"; do nikto -h \"$url\"; read -p 'Press Enter to close this terminal'; done" C-m

# Attach to the tmux session
tmux attach-session -t scanner
