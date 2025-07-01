#!/usr/bin/env bash

# VPN Connectivity Test Script
echo "Testing WireGuard VPN connectivity..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Show local IP information
echo -e "${BLUE}=== Local IP Information ===${NC}"
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - get primary interface IP
    local_ip=$(route get default | grep interface | awk '{print $2}' | head -n1 | xargs ifconfig | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -n1)
    interface=$(route get default | grep interface | awk '{print $2}' | head -n1)
    echo "Local IP: $local_ip (interface: $interface)"
    
    # Show VPN interface if exists
    if ifconfig utun 2>/dev/null | grep -q "inet"; then
        vpn_ip=$(ifconfig | grep -A 1 "utun" | grep "inet 10.0.0" | awk '{print $2}' | head -n1)
        if [[ -n "$vpn_ip" ]]; then
            echo "VPN IP: $vpn_ip"
        fi
    fi
else
    # Linux
    local_ip=$(ip route get 8.8.8.8 | grep -oP 'src \K[^\s]+')
    echo "Local IP: $local_ip"
    
    # Show VPN interface if exists
    vpn_ip=$(ip addr show wg0 2>/dev/null | grep "inet 10.0.0" | awk '{print $2}' | cut -d'/' -f1)
    if [[ -n "$vpn_ip" ]]; then
        echo "VPN IP: $vpn_ip"
    fi
fi
echo

# Test function
test_connectivity() {
    local host=$1
    local description=$2
    local count=${3:-3}
    
    echo -n "Testing $description ($host)... "
    
    if ping -c $count -W 3000 $host &> /dev/null; then
        echo -e "${GREEN}✓ Success${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed${NC}"
        return 1
    fi
}

# Check if WireGuard is running
echo -e "${BLUE}=== WireGuard Status ===${NC}"
if command -v wg &> /dev/null; then
    if sudo wg show &> /dev/null; then
        echo -e "${GREEN}✓ WireGuard is running${NC}"
        sudo wg show
    else
        echo -e "${RED}✗ WireGuard is not running${NC}"
        echo "Run: sudo wg-quick up wg0"
        exit 1
    fi
else
    echo -e "${RED}✗ WireGuard tools not found${NC}"
    exit 1
fi

echo
echo -e "${BLUE}=== VPN Network Tests ===${NC}"

# Test VPN hosts
test_connectivity "10.0.0.1" "Shannon (VPN Server)"
test_connectivity "10.0.0.2" "Einstein (Gateway)"

echo
echo -e "${BLUE}=== Home Network Tests (via Einstein) ===${NC}"

# Test home network through Einstein
test_connectivity "192.168.50.141" "Einstein local IP"

# Try to reach other common home network IPs
echo
echo -e "${YELLOW}Testing common home network ranges...${NC}"
test_connectivity "192.168.50.1" "Home router" 1

echo
echo -e "${BLUE}=== Internet Connectivity Tests ===${NC}"

# Test internet connectivity (should go through Shannon)
test_connectivity "8.8.8.8" "Google DNS" 2
test_connectivity "1.1.1.1" "Cloudflare DNS" 2

echo
echo -e "${BLUE}=== Route Information ===${NC}"

# Show routing table for VPN networks
echo "Routes for VPN networks:"
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    netstat -rn | grep -E "(10\.0\.0|192\.168\.50)" || echo "No VPN routes found"
else
    # Linux
    ip route | grep -E "(10\.0\.0|192\.168\.50)" || echo "No VPN routes found"
fi

