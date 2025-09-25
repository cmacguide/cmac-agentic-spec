#!/usr/bin/env bash
# Script Path Detection Module
# Provides robust script directory detection for both development and release environments

# Get script directory with robust fallback mechanism
# Usage: get_script_dir
get_script_dir() {
    local script_dir=""
    
    # Method 1: Try BASH_SOURCE (works in most development environments)
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        if [[ -d "$script_dir" ]]; then
            echo "$script_dir"
            return 0
        fi
    fi
    
    # Method 2: Try $0 (works when script is executed directly)
    if [[ -n "${0:-}" && "$0" != "bash" && "$0" != "-bash" ]]; then
        script_dir="$(cd "$(dirname "$0")" && pwd)"
        if [[ -d "$script_dir" ]]; then
            echo "$script_dir"
            return 0
        fi
    fi
    
    # Method 3: Try PWD if it looks like a scripts directory
    if [[ "$PWD" == *"/scripts"* || "$PWD" == *"/scripts/"* ]]; then
        echo "$PWD"
        return 0
    fi
    
    # Method 4: Look for .specify/scripts from current directory upward
    local current_dir="$PWD"
    while [[ "$current_dir" != "/" ]]; do
        if [[ -d "$current_dir/.specify/scripts" ]]; then
            echo "$current_dir/.specify/scripts"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    # Method 5: Look for scripts directory from current directory upward
    current_dir="$PWD"
    while [[ "$current_dir" != "/" ]]; do
        if [[ -d "$current_dir/scripts/bash" ]]; then
            echo "$current_dir/scripts/bash"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    # Method 6: Final fallback - assume we're in a release environment
    # and scripts are in .specify/scripts relative to repo root
    local repo_root=""
    if command -v git >/dev/null 2>&1 && git rev-parse --show-toplevel >/dev/null 2>&1; then
        repo_root="$(git rev-parse --show-toplevel)"
    else
        # Try to find repo root by looking for common files
        current_dir="$PWD"
        while [[ "$current_dir" != "/" ]]; do
            if [[ -f "$current_dir/pyproject.toml" || -f "$current_dir/.gitignore" || -f "$current_dir/README.md" ]]; then
                repo_root="$current_dir"
                break
            fi
            current_dir="$(dirname "$current_dir")"
        done
    fi
    
    if [[ -n "$repo_root" ]]; then
        # Try .specify/scripts first (release environment)
        if [[ -d "$repo_root/.specify/scripts" ]]; then
            echo "$repo_root/.specify/scripts"
            return 0
        fi
        # Fallback to scripts/bash (development environment)
        if [[ -d "$repo_root/scripts/bash" ]]; then
            echo "$repo_root/scripts/bash"
            return 0
        fi
    fi
    
    # Ultimate fallback - return current directory
    echo "$PWD"
}

# Get repository root with robust detection
# Usage: get_robust_repo_root
get_robust_repo_root() {
    # Try git first
    if command -v git >/dev/null 2>&1 && git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
        return 0
    fi
    
    # Try to find repo root by looking for common files
    local current_dir="$PWD"
    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/pyproject.toml" || -f "$current_dir/.gitignore" || -f "$current_dir/README.md" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    # Try relative to script directory
    local script_dir="$(get_script_dir)"
    if [[ -n "$script_dir" ]]; then
        # If we're in .specify/scripts, go up 2 levels
        if [[ "$script_dir" == *"/.specify/scripts"* ]]; then
            echo "$(cd "$script_dir/../.." && pwd)"
            return 0
        fi
        # If we're in scripts/bash, go up 2 levels
        if [[ "$script_dir" == *"/scripts/bash"* ]]; then
            echo "$(cd "$script_dir/../.." && pwd)"
            return 0
        fi
        # If we're in scripts, go up 1 level
        if [[ "$script_dir" == *"/scripts"* ]]; then
            echo "$(cd "$script_dir/.." && pwd)"
            return 0
        fi
    fi
    
    # Final fallback
    echo "$PWD"
}

# Test function to verify script path detection
test_script_path_detection() {
    echo "=== Script Path Detection Test ==="
    echo "Script Directory: $(get_script_dir)"
    echo "Repository Root: $(get_robust_repo_root)"
    echo "BASH_SOURCE[0]: ${BASH_SOURCE[0]:-'NOT_SET'}"
    echo "Script Name (\$0): ${0:-'NOT_SET'}"
    echo "Current PWD: $PWD"
    echo "=================================="
}

# Main function for direct script execution
main() {
    case "${1:-}" in
        "test")
            test_script_path_detection
            ;;
        "script-dir")
            get_script_dir
            ;;
        "repo-root")
            get_robust_repo_root
            ;;
        *)
            echo "Script Path Detection Module v1.0"
            echo "Usage: $0 {test|script-dir|repo-root}"
            echo
            echo "Commands:"
            echo "  test        - Run detection tests"
            echo "  script-dir  - Get script directory"
            echo "  repo-root   - Get repository root"
            echo
            echo "Functions available for sourcing:"
            echo "  get_script_dir        - Get current script directory"
            echo "  get_robust_repo_root  - Get repository root"
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi