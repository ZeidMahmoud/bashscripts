#!/bin/bash

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${RED}Error: No target supplied.${NC}"
    echo -e "Usage:   ${GREEN}ipid <ipv4_address or domain>${NC}"
    echo -e "Example: ${GREEN}ipid 8.8.8.8${NC}"
    echo -e "Example: ${GREEN}ipid zeidmahmoud.xyz${NC}"
    exit 1
fi

INPUT=$1

# Check if input is a domain or IP
if [[ $INPUT =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    TARGET_IP=$INPUT
    TARGET_DOMAIN=""
else
    TARGET_DOMAIN=$INPUT
    # Resolve domain to IP
    TARGET_IP=$(dig +short "$INPUT" | grep -E '^[0-9]+\.' | head -n1)
    if [ -z "$TARGET_IP" ]; then
        echo -e "${RED}Error: Could not resolve '$INPUT' to an IP.${NC}"
        exit 1
    fi
    echo -e "${YELLOW}Resolved ${TARGET_DOMAIN} → ${TARGET_IP}${NC}\n"
fi

echo -e "${YELLOW}Gathering intelligence for: ${INPUT}...${NC}\n"

# 1. Reverse DNS
echo -e "${CYAN}[+] Hostname & Reverse DNS Lookup${NC}"
if command -v host &> /dev/null; then
    host "$TARGET_IP"
else
    echo -e "${RED}[!] 'host' not found. Skipping.${NC}"
fi
echo ""

# 2. Location & ISP
echo -e "${CYAN}[+] Server Location & ISP Details${NC}"
if command -v curl &> /dev/null; then
    curl -s "https://ipinfo.io/${TARGET_IP}/json" | grep -v 'readme'
else
    echo -e "${RED}[!] 'curl' not found. Skipping.${NC}"
fi
echo ""

# 3. WHOIS
echo -e "${CYAN}[+] WHOIS Organization & Domain Info (Summary)${NC}"
if command -v whois &> /dev/null; then
    WHOIS_TARGET="${TARGET_DOMAIN:-$TARGET_IP}"
    whois "$WHOIS_TARGET" | grep -iE '^(OrgName|Organization|NetName|NetRange|CIDR|Country|StateProv|City|RegDate|Updated|ASName|Registrar|Domain Name|Name Server)' | sort -u | head -n 20
else
    echo -e "${RED}[!] 'whois' not found.${NC}"
fi
echo ""

# 4. Domain Names Associated with IP
echo -e "${CYAN}[+] Domain Names Associated with IP${NC}"
if command -v curl &> /dev/null; then
    curl -s "https://api.hackertarget.com/reverseiplookup/?q=${TARGET_IP}"
else
    echo -e "${RED}[!] 'curl' not found. Skipping.${NC}"
fi
echo ""

echo -e "${YELLOW}Scan complete.${NC}"
