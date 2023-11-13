import nmap

# Create a new Nmap Scanner object
nm = nmap.PortScanner()

# Define the target host or IP address
target = "127.0.0.1"

# Configure the scan options
scan_args = "-O -A -T4"

# Perform the Nmap scan
nm.scan(hosts=target, arguments=scan_args)

# Get the scan results
scan_results = nm[target]

# Print the scan results
print(f"Scan results for {target}:")
for port in scan_results["tcp"]:
    print(f"Port {port}: {scan_results['tcp'][port]['state']}")

# Print OS and version information if available
if "osmatch" in scan_results:
    print("OS information:")
    for osmatch in scan_results["osmatch"]:
        print(f"Name: {osmatch['name']}, Accuracy: {osmatch['accuracy']}")

if "hostname" in scan_results:
    print(f"Hostname: {scan_results['hostname']}")
