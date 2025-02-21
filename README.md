# Jamf Trust ZTNA WireGuard Test Script

This Bash script performs network connectivity tests to specific domains and ports while toggling Jamf Trust (ZTNA WireGuard) on and off. The script runs various tests, including DNS resolution, cURL requests, port connectivity checks, ping tests, and IP address verification.

## Features
- Tests connectivity to predefined domains and ports
- Runs tests with Jamf Trust enabled and disabled
- Includes DNS, cURL, port, and ping tests
- Saves results automatically to a timestamped directory
- Optionally compresses results into a ZIP file

## Prerequisites
- Bash shell (macOS)
- `curl` installed
- `nc` (netcat) for port testing
- `ping` for ICMP tests
- `zip` (if enabling result compression)

## Usage
1. Clone or download this repository.
2. Make the script executable:
   ```bash
   chmod +x jt-ztna-wireguard-test.sh
   ```
3. Run the script:
   ```bash
   ./jt-ztna-wireguard-test.sh
   ```

## Configuration
Modify the script variables to customize testing parameters:
- **Domains to check:** `domains=("map.wandera.com" "jamf.com")`
- **Ports to check:** `ports=(80 443)`
- **Enable/disable specific tests:**
  ```bash
  includeDNSTests=1
  includeCurlTests=1
  includePortTests=1
  includePingTests=1
  includeIpapiTest=1
  ```
- **Output settings:** Results are saved to the Desktop with a timestamp.
- **Jamf Trust toggle delay:** Adjust `sleepWait=10` (seconds) for waiting between test states.

## Output
- Results are stored in a timestamped directory on the Desktop.
- When `zipResults=1`, results are compressed into a ZIP file for easy sharing.

## License
This script is provided as-is with no warranty. Use it at your own risk.

## Author

Craig Donovan
