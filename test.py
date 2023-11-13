import nmap
import requests

def search_vulnerabilities(service, version):
    # Format the search query
    query = f"{service} {version} vulnerability"

    # Make a request to a search engine or vulnerability database
    # and retrieve the search results
    search_results = requests.get(f"https://https://www.shodan.io/search?q={query}")

    # Process the search results and extract vulnerability information
    # based on the format of the search engine or database

    # Print the vulnerability information
    print(f"Vulnerabilities for {service} {version}:")
    print("------------------------------")
    print(search_results.text)
    print("\n")

# Create a PortScanner object
scanner = nmap.PortScanner()

# Specify the target IP address or hostname
target = input("Enter the target IP address or hostname: ")

# Define the arguments for the scan
arguments = "-p- -sV"

# Scan the target with the specified arguments
result = scanner.scan(target, arguments=arguments)

# Iterate over the scanned ports and retrieve service information
for port in scanner[target]['tcp']:
    state = scanner[target]['tcp'][port]['state']
    service = scanner[target]['tcp'][port]['name']
    version = scanner[target]['tcp'][port]['version']
    if state == 'open':
        # Print the open port, service, and version
        print(f"Port {port} is open. Service: {service} Version: {version}")

        # Search for vulnerabilities based on service and version
        search_vulnerabilities(service, version)

print("Scan completed!")
