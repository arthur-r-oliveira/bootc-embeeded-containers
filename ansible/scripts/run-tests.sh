#!/bin/bash

# Test runner for Ansible Bootc implementation
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
            echo -e "${BLUE}ℹ${NC} $message"
            ;;
        "RUN")
            echo -e "${YELLOW}▶${NC} $message"
            ;;
    esac
}

# Function to run a test and capture results
run_test() {
    local test_name=$1
    local test_file=$2
    local extra_vars=$3
    
    print_status "RUN" "Running $test_name..."
    
    if ansible-playbook "$test_file" $extra_vars; then
        print_status "PASS" "$test_name completed successfully"
        return 0
    else
        print_status "FAIL" "$test_name failed"
        return 1
    fi
}

# Function to cleanup test artifacts
cleanup_tests() {
    print_status "INFO" "Cleaning up test artifacts..."
    
    # Remove test images
    podman rmi -f $(podman images --format "table {{.Repository}}:{{.Tag}}" | grep -E "(test-|microshift.*test)" | awk '{print $1}') 2>/dev/null || true
    
    # Remove test containers
    podman rm -f $(podman ps -a --format "table {{.Names}}" | grep test) 2>/dev/null || true
    
    # Remove test files
    rm -rf /tmp/test-* 2>/dev/null || true
    rm -rf /var/ostree/updates/test-* 2>/dev/null || true
    
    print_status "PASS" "Cleanup completed"
}

# Function to show test results summary
show_summary() {
    local passed=$1
    local failed=$2
    local total=$((passed + failed))
    
    echo
    echo "Test Results Summary"
    echo "==================="
    print_status "INFO" "Total tests: $total"
    print_status "PASS" "Passed: $passed"
    if [ $failed -gt 0 ]; then
        print_status "FAIL" "Failed: $failed"
    else
        print_status "PASS" "Failed: $failed"
    fi
    
    if [ $failed -eq 0 ]; then
        print_status "PASS" "All tests passed!"
        return 0
    else
        print_status "FAIL" "Some tests failed!"
        return 1
    fi
}

# Main test runner
main() {
    local test_suite=${1:-"all"}
    local cleanup=${2:-"true"}
    local verbose=${3:-"false"}
    
    echo "Ansible Bootc Test Runner"
    echo "========================"
    echo
    
    # Set verbose flag
    local ansible_flags=""
    if [ "$verbose" = "true" ]; then
        ansible_flags="-vvv"
    fi
    
    local passed=0
    local failed=0
    
    # Run validation first
    print_status "INFO" "Running setup validation..."
    if ./scripts/validate-setup.sh; then
        print_status "PASS" "Setup validation passed"
        ((passed++))
    else
        print_status "FAIL" "Setup validation failed"
        ((failed++))
        echo "Please fix setup issues before running tests"
        exit 1
    fi
    echo
    
    # Test suite selection
    case $test_suite in
        "all")
            tests=("build" "registry" "delta")
            ;;
        "build")
            tests=("build")
            ;;
        "registry")
            tests=("registry")
            ;;
        "delta")
            tests=("delta")
            ;;
        "quick")
            tests=("build")
            ;;
        *)
            echo "Unknown test suite: $test_suite"
            echo "Available suites: all, build, registry, delta, quick"
            exit 1
            ;;
    esac
    
    # Run selected tests
    for test in "${tests[@]}"; do
        case $test in
            "build")
                if run_test "Build Test" "tests/test-build.yml" "$ansible_flags"; then
                    ((passed++))
                else
                    ((failed++))
                fi
                ;;
            "registry")
                if run_test "Registry Test" "tests/test-registry.yml" "$ansible_flags"; then
                    ((passed++))
                else
                    ((failed++))
                fi
                ;;
            "delta")
                if run_test "Delta Update Test" "tests/test-delta.yml" "$ansible_flags"; then
                    ((passed++))
                else
                    ((failed++))
                fi
                ;;
        esac
        echo
    done
    
    # Cleanup if requested
    if [ "$cleanup" = "true" ]; then
        cleanup_tests
    fi
    
    # Show summary
    show_summary $passed $failed
}

# Show usage
usage() {
    echo "Usage: $0 [test_suite] [cleanup] [verbose]"
    echo
    echo "Arguments:"
    echo "  test_suite  Test suite to run (all, build, registry, delta, quick)"
    echo "  cleanup     Clean up test artifacts (true, false)"
    echo "  verbose     Enable verbose output (true, false)"
    echo
    echo "Examples:"
    echo "  $0                    # Run all tests with cleanup"
    echo "  $0 build              # Run only build tests"
    echo "  $0 all false true     # Run all tests without cleanup, verbose output"
    echo "  $0 quick              # Run quick test suite"
}

# Check if help is requested
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi

# Run main function
main "${1:-all}" "${2:-true}" "${3:-false}"