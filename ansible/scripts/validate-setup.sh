#!/bin/bash

# Validation script for Ansible Bootc setup
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "PASS")
            echo -e "${GREEN}✓${NC} $message"
            ;;
        "FAIL")
            echo -e "${RED}✗${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠${NC} $message"
            ;;
        "INFO")
            echo -e "${YELLOW}ℹ${NC} $message"
            ;;
    esac
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Ansible version
check_ansible_version() {
    if command_exists ansible; then
        local version=$(ansible --version | head -n1 | awk '{print $3}' | sed 's/]//')
        local major=$(echo $version | cut -d. -f1)
        local minor=$(echo $version | cut -d. -f2)
        
        if [ "$major" -gt 2 ] || ([ "$major" -eq 2 ] && [ "$minor" -ge 15 ]); then
            print_status "PASS" "Ansible version $version (>= 2.15)"
        else
            print_status "FAIL" "Ansible version $version (< 2.15 required)"
            return 1
        fi
    else
        print_status "FAIL" "Ansible not installed"
        return 1
    fi
}

# Function to check required commands
check_commands() {
    local commands=("podman" "git" "make" "gcc")
    local missing=()
    
    for cmd in "${commands[@]}"; do
        if command_exists "$cmd"; then
            print_status "PASS" "$cmd is installed"
        else
            print_status "FAIL" "$cmd is not installed"
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_status "WARN" "Missing commands: ${missing[*]}"
        return 1
    fi
}

# Function to check Ansible collections
check_collections() {
    local collections=("community.general" "community.libvirt" "containers.podman")
    local missing=()
    
    for collection in "${collections[@]}"; do
        if ansible-galaxy collection list | grep -q "$collection"; then
            print_status "PASS" "Collection $collection is installed"
        else
            print_status "FAIL" "Collection $collection is not installed"
            missing+=("$collection")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_status "WARN" "Missing collections: ${missing[*]}"
        print_status "INFO" "Run: ansible-galaxy collection install -r requirements.yml"
        return 1
    fi
}

# Function to check pull secret
check_pull_secret() {
    local pull_secret="../.pull-secret.json"
    
    if [ -f "$pull_secret" ]; then
        if jq empty "$pull_secret" 2>/dev/null; then
            print_status "PASS" "Pull secret file is valid JSON"
        else
            print_status "FAIL" "Pull secret file is not valid JSON"
            return 1
        fi
    else
        print_status "FAIL" "Pull secret file not found at $pull_secret"
        print_status "INFO" "Download from: https://console.redhat.com/openshift/downloads#tool-pull-secret"
        return 1
    fi
}

# Function to check inventory files
check_inventory() {
    local inventory_files=("inventory/local.yml" "inventory/production.yml")
    
    for inv in "${inventory_files[@]}"; do
        if [ -f "$inv" ]; then
            if ansible-inventory -i "$inv" --list >/dev/null 2>&1; then
                print_status "PASS" "Inventory $inv is valid"
            else
                print_status "FAIL" "Inventory $inv is not valid"
                return 1
            fi
        else
            print_status "FAIL" "Inventory $inv not found"
            return 1
        fi
    done
}

# Function to check playbook syntax
check_playbooks() {
    local playbooks=("playbooks/build-bootc-images.yml" "playbooks/setup-registry.yml" "playbooks/delta-updates.yml")
    
    for playbook in "${playbooks[@]}"; do
        if [ -f "$playbook" ]; then
            if ansible-playbook --syntax-check "$playbook" >/dev/null 2>&1; then
                print_status "PASS" "Playbook $playbook syntax is valid"
            else
                print_status "FAIL" "Playbook $playbook syntax is invalid"
                return 1
            fi
        else
            print_status "FAIL" "Playbook $playbook not found"
            return 1
        fi
    done
}

# Function to check system requirements
check_system() {
    # Check if running on supported OS
    if [ -f /etc/redhat-release ]; then
        local version=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+' | head -n1)
        if [ -n "$version" ]; then
            local major=$(echo $version | cut -d. -f1)
            
            if [ "$major" -ge 9 ]; then
                print_status "PASS" "RHEL/CentOS $version is supported"
            else
                print_status "WARN" "RHEL/CentOS $version may not be fully supported (9+ recommended)"
            fi
        else
            print_status "WARN" "Unable to determine RHEL/CentOS version"
        fi
    elif [ -f /etc/fedora-release ]; then
        local version=$(cat /etc/fedora-release | grep -oE '[0-9]+' | head -n1)
        if [ "$version" -ge 38 ]; then
            print_status "PASS" "Fedora $version is supported"
        else
            print_status "WARN" "Fedora $version may not be fully supported (38+ recommended)"
        fi
    else
        print_status "WARN" "Unknown OS, compatibility not guaranteed"
    fi
    
    # Check available disk space
    local available_space=$(df . | tail -n1 | awk '{print $4}')
    local required_space=10485760  # 10GB in KB
    
    if [ "$available_space" -gt "$required_space" ]; then
        print_status "PASS" "Sufficient disk space available ($(($available_space / 1024 / 1024))GB)"
    else
        print_status "WARN" "Low disk space ($(($available_space / 1024 / 1024))GB), 10GB+ recommended"
    fi
}

# Main validation function
main() {
    echo "Ansible Bootc Setup Validation"
    echo "=============================="
    echo
    
    local exit_code=0
    
    print_status "INFO" "Checking system requirements..."
    check_system || exit_code=1
    echo
    
    print_status "INFO" "Checking Ansible installation..."
    check_ansible_version || exit_code=1
    echo
    
    print_status "INFO" "Checking required commands..."
    check_commands || exit_code=1
    echo
    
    print_status "INFO" "Checking Ansible collections..."
    check_collections || exit_code=1
    echo
    
    print_status "INFO" "Checking pull secret..."
    check_pull_secret || exit_code=1
    echo
    
    print_status "INFO" "Checking inventory files..."
    check_inventory || exit_code=1
    echo
    
    print_status "INFO" "Checking playbook syntax..."
    check_playbooks || exit_code=1
    echo
    
    if [ $exit_code -eq 0 ]; then
        print_status "PASS" "All validations passed! Setup is ready."
        echo
        print_status "INFO" "Next steps:"
        echo "  1. Run: make install"
        echo "  2. Run: make build"
        echo "  3. Run: make complete"
    else
        print_status "FAIL" "Some validations failed. Please fix the issues above."
    fi
    
    exit $exit_code
}

# Run main function
main "$@"