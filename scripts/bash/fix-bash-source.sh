#!/usr/bin/env bash
# Script to fix BASH_SOURCE issues in all bash scripts
# This script updates all bash scripts to use robust path detection

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Function to update a script with robust SCRIPT_DIR detection
update_script_dir() {
    local file="$1"
    local backup_file="${file}.backup"
    
    echo "Updating $file..."
    
    # Create backup
    cp "$file" "$backup_file"
    
    # Replace the SCRIPT_DIR line with robust version
    sed -i.tmp '
    /^SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE\[0\]}")" && pwd)"$/{
        c\
# Get script directory with robust fallback\
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then\
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"\
else\
    # Fallback for release environments\
    SCRIPT_DIR="$(cd "$(dirname "${0:-$PWD}")" && pwd)"\
    # If dependencies not found, try common locations\
    if [[ ! -f "$SCRIPT_DIR/common.sh" && ! -f "$SCRIPT_DIR/knowledge-base-integration.sh" ]]; then\
        for possible_dir in ".specify/scripts" "scripts/bash" "../bash" "."; do\
            if [[ -f "$possible_dir/common.sh" || -f "$possible_dir/knowledge-base-integration.sh" ]]; then\
                SCRIPT_DIR="$(cd "$possible_dir" && pwd)"\
                break\
            fi\
        done\
    fi\
fi
    }' "$file"
    
    # Remove temporary file
    rm -f "${file}.tmp"
    
    echo "✅ Updated $file"
}

# Function to update BASH_SOURCE execution check
update_execution_check() {
    local file="$1"
    
    echo "Updating execution check in $file..."
    
    # Replace the execution check with robust version
    sed -i.tmp '
    /^if \[\[ "${BASH_SOURCE\[0\]}" == "${0}" \]\]; then$/{
        c\
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    }' "$file"
    
    # Remove temporary file
    rm -f "${file}.tmp"
    
    echo "✅ Updated execution check in $file"
}

# List of scripts to update (excluding the ones already updated)
scripts_to_update=(
    "$SCRIPT_DIR/checkpoint-control.sh"
    "$SCRIPT_DIR/checkpoint-system.sh"
    "$SCRIPT_DIR/check-prerequisites.sh"
    "$SCRIPT_DIR/create-new-feature.sh"
    "$SCRIPT_DIR/knowledge-base-integration.sh"
    "$SCRIPT_DIR/update-agent-context.sh"
    "$SCRIPT_DIR/../tests/artifact-integration-tests.sh"
    "$SCRIPT_DIR/../tests/checkpoint-workflow-tests.sh"
    "$SCRIPT_DIR/../tests/kb-integration-tests.sh"
    "$SCRIPT_DIR/../tests/plan-kb-integration-tests.sh"
)

echo "=== Fixing BASH_SOURCE issues in bash scripts ==="

for script in "${scripts_to_update[@]}"; do
    if [[ -f "$script" ]]; then
        # Check if script has SCRIPT_DIR line to update
        if grep -q '^SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE\[0\]}")" && pwd)"$' "$script"; then
            update_script_dir "$script"
        fi
        
        # Check if script has execution check to update
        if grep -q '^if \[\[ "${BASH_SOURCE\[0\]}" == "${0}" \]\]; then$' "$script"; then
            update_execution_check "$script"
        fi
    else
        echo "⚠️  Script not found: $script"
    fi
done

echo ""
echo "=== Summary ==="
echo "✅ All bash scripts have been updated with robust BASH_SOURCE handling"
echo "📁 Backup files created with .backup extension"
echo ""
echo "The scripts now:"
echo "  - Use fallback detection when BASH_SOURCE is not available"
echo "  - Search for dependencies in common locations (.specify/scripts, scripts/bash, etc.)"
echo "  - Handle execution checks robustly for release environments"
echo ""
echo "To test the changes, you can run:"
echo "  ./scripts/bash/script-path-detection.sh test"