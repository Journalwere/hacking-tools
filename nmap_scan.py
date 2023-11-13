import nmap

target = input("Enter the target IP address or hostname: ")

# Create a PortScanner object
scanner = nmap.PortScanner()

# Define the arguments for the scan
arguments = '-p- -sV -O -T4'

# Scan the target with the specified arguments
result = scanner.scan(target, arguments=arguments)

# Retrieve the OS information
os = result['scan'][target]['osmatch'][0]['name']

# Get the total number of open ports
open_ports = [port for port in scanner[target]['tcp'] if scanner[target]['tcp'][port]['state'] == 'open']

# Iterate over the scanned ports and retrieve service information
for port in open_ports:
    state = scanner[target]['tcp'][port]['state']
    service = scanner[target]['tcp'][port]['name']
    version = scanner[target]['tcp'][port]['version']
    if state == 'open':
        print("Port {} is open. Service: {} Version: {} OS: {}".format(port, service, version, os))

print("Scan completed!")
