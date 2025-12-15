#!/bin/bash

# Pre-flight checks script
# Verifies system prerequisites before running installations

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track overall status
ALL_CHECKS_PASSED=true
WARNINGS=()

echo "=========================================="
echo "Running Pre-flight Checks..."
echo "=========================================="
echo ""

# Check 1: Verify sudo access
echo -n "Checking sudo access... "
if sudo -n true 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
elif sudo -v 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "  ERROR: sudo access required. Please ensure you have sudo privileges."
    ALL_CHECKS_PASSED=false
fi

# Check 2: Verify internet connectivity
echo -n "Checking internet connectivity... "
if ping -c 1 -W 2 8.8.8.8 &> /dev/null || ping -c 1 -W 2 1.1.1.1 &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "  ERROR: No internet connection detected. Please check your network."
    ALL_CHECKS_PASSED=false
fi

# Check 3: Verify DNS resolution
echo -n "Checking DNS resolution... "
if host github.com &> /dev/null || nslookup github.com &> /dev/null || ping -c 1 -W 2 github.com &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "  WARNING: DNS resolution may not be working properly."
    WARNINGS+=("DNS resolution issues detected")
fi

# Check 4: Verify available disk space
echo -n "Checking available disk space... "
AVAILABLE_SPACE=$(df -BG / 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//')
REQUIRED_SPACE=10

if [ -z "$AVAILABLE_SPACE" ] || ! [[ "$AVAILABLE_SPACE" =~ ^[0-9]+$ ]]; then
    echo -e "${YELLOW}⚠${NC}"
    echo "  WARNING: Could not determine available disk space."
    WARNINGS+=("Unable to check disk space")
elif [ "$AVAILABLE_SPACE" -ge "$REQUIRED_SPACE" ]; then
    echo -e "${GREEN}✓${NC} (${AVAILABLE_SPACE}GB available)"
else
    echo -e "${YELLOW}⚠${NC} (${AVAILABLE_SPACE}GB available)"
    echo "  WARNING: Low disk space. At least ${REQUIRED_SPACE}GB recommended."
    WARNINGS+=("Low disk space: ${AVAILABLE_SPACE}GB available")
fi

# Check 5: Verify apt is not locked
echo -n "Checking if apt is available... "
if command -v fuser &> /dev/null; then
    if sudo fuser /var/lib/dpkg/lock-frontend &> /dev/null || \
       sudo fuser /var/lib/apt/lists/lock &> /dev/null || \
       sudo fuser /var/cache/apt/archives/lock &> /dev/null; then
        echo -e "${YELLOW}⚠${NC}"
        echo "  WARNING: apt appears to be locked by another process."
        echo "  This may be another package manager or unattended-upgrades."
        WARNINGS+=("apt is locked by another process")
    else
        echo -e "${GREEN}✓${NC}"
    fi
else
    # Fallback: check if lock files exist
    if [ -f /var/lib/dpkg/lock-frontend ] || [ -f /var/lib/apt/lists/lock ]; then
        echo -e "${YELLOW}⚠${NC}"
        echo "  WARNING: apt lock files exist (fuser not available to verify)."
        WARNINGS+=("apt lock files detected")
    else
        echo -e "${GREEN}✓${NC}"
    fi
fi

# Check 6: Verify system is Debian-based
echo -n "Checking system compatibility... "
# Extract distro info
DISTRO=$(lsb_release -is 2>/dev/null || grep "^ID=" /etc/os-release 2>/dev/null | cut -d'=' -f2 | tr -d '"')
VERSION=$(lsb_release -rs 2>/dev/null || grep "VERSION_ID=" /etc/os-release 2>/dev/null | cut -d'=' -f2 | tr -d '"')
ID_LIKE=$(grep "^ID_LIKE=" /etc/os-release 2>/dev/null | cut -d'=' -f2 | tr -d '"')

# Check if it's Debian-based by multiple methods
IS_DEBIAN_BASED=false

# Method 1: Check for debian_version file (most reliable for Debian/Ubuntu)
if [ -f /etc/debian_version ]; then
    IS_DEBIAN_BASED=true
# Method 2: Check if ID or ID_LIKE contains debian or ubuntu
elif echo "$DISTRO" | grep -qiE "debian|ubuntu"; then
    IS_DEBIAN_BASED=true
elif echo "$ID_LIKE" | grep -qiE "debian|ubuntu"; then
    IS_DEBIAN_BASED=true
# Method 3: Check if apt-get exists (Debian-based systems use apt)
elif command -v apt-get &> /dev/null && [ -d /etc/apt ]; then
    IS_DEBIAN_BASED=true
fi

if [ "$IS_DEBIAN_BASED" = true ]; then
    echo -e "${GREEN}✓${NC} ($DISTRO $VERSION)"
else
    echo -e "${RED}✗${NC}"
    echo "  ERROR: This script is designed for Debian-based distributions."
    echo "  Detected: $DISTRO $VERSION"
    ALL_CHECKS_PASSED=false
fi

# Check 7: Verify required base commands
echo -n "Checking base commands... "
MISSING_COMMANDS=()
for cmd in curl wget apt-get dpkg; do
    if ! command -v "$cmd" &> /dev/null; then
        MISSING_COMMANDS+=("$cmd")
    fi
done

if [ ${#MISSING_COMMANDS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "  ERROR: Missing required commands: ${MISSING_COMMANDS[*]}"
    ALL_CHECKS_PASSED=false
fi

# Check 8: Verify write permissions in working directory
echo -n "Checking write permissions... "
if [ -w "$PWD" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "  ERROR: No write permissions in current directory: $PWD"
    ALL_CHECKS_PASSED=false
fi

# Check 9: Check if running as root (not recommended)
echo -n "Checking user privileges... "
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}⚠${NC}"
    echo "  WARNING: Running as root is not recommended."
    echo "  Please run as a regular user with sudo access."
    WARNINGS+=("Running as root user")
else
    echo -e "${GREEN}✓${NC}"
fi

# Check 10: Verify /tmp is writable and has space
echo -n "Checking /tmp directory... "
if [ -w /tmp ] && [ -d /tmp ]; then
    TMP_SPACE=$(df -BG /tmp 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ -z "$TMP_SPACE" ] || ! [[ "$TMP_SPACE" =~ ^[0-9]+$ ]]; then
        echo -e "${YELLOW}⚠${NC}"
        echo "  WARNING: Could not determine /tmp space."
        WARNINGS+=("Unable to check /tmp space")
    elif [ "$TMP_SPACE" -ge 1 ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠${NC}"
        echo "  WARNING: Low space in /tmp (${TMP_SPACE}GB available)"
        WARNINGS+=("Low /tmp space: ${TMP_SPACE}GB")
    fi
else
    echo -e "${RED}✗${NC}"
    echo "  ERROR: /tmp directory is not writable"
    ALL_CHECKS_PASSED=false
fi

# Summary
echo ""
echo "=========================================="
if [ "$ALL_CHECKS_PASSED" = true ]; then
    if [ ${#WARNINGS[@]} -eq 0 ]; then
        echo -e "${GREEN}✓ All pre-flight checks passed!${NC}"
        echo ""
        echo "System is ready for installation."
        exit 0
    else
        echo -e "${YELLOW}⚠ Pre-flight checks completed with warnings:${NC}"
        for warning in "${WARNINGS[@]}"; do
            echo "  • $warning"
        done
        echo ""
        echo "You can proceed, but some installations may fail."
        exit 0
    fi
else
    echo -e "${RED}✗ Pre-flight checks failed!${NC}"
    echo ""
    echo "Please resolve the errors above before proceeding."
    if [ ${#WARNINGS[@]} -gt 0 ]; then
        echo ""
        echo "Additional warnings:"
        for warning in "${WARNINGS[@]}"; do
            echo "  • $warning"
        done
    fi
    exit 1
fi
