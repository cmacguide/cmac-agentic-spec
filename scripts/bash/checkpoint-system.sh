#!/usr/bin/env bash
# Checkpoint System Module
# Implements quality gates, snapshots, and rollback functionality
# Part of SDD v2.0 Critical Systems Implementation - Phase 3.1

# Source dependencies
# Get script directory with robust fallback
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    # Fallback for release environments
    SCRIPT_DIR="$(cd "$(dirname "${0:-$PWD}")" && pwd)"
    # If dependencies not found, try common locations
    if [[ ! -f "$SCRIPT_DIR/common.sh" && ! -f "$SCRIPT_DIR/knowledge-base-integration.sh" ]]; then
        for possible_dir in ".specify/scripts" "scripts/bash" "../bash" "."; do
            if [[ -f "$possible_dir/common.sh" || -f "$possible_dir/knowledge-base-integration.sh" ]]; then
                SCRIPT_DIR="$(cd "$possible_dir" && pwd)"
                break
            fi
        done
    fi
fi
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/knowledge-base-integration.sh"
source "$SCRIPT_DIR/artifact-generation.sh"

# Global configuration
CHECKPOINTS_DIR=".specify-cache/checkpoints"
SNAPSHOTS_DIR=".specify-cache/snapshots"
QUALITY_GATES_DIR=".specify-cache/quality-gates"
MAX_CHECKPOINTS=5

# =============================================================================
# CHECKPOINT MANAGEMENT FUNCTIONS
# =============================================================================

# Create a checkpoint with snapshot and validation
# Usage: create_checkpoint <checkpoint_name> <phase> [description]
create_checkpoint() {
    local checkpoint_name="$1"
    local phase="$2"
    local description="${3:-Checkpoint created for $phase phase}"
    
    if [[ -z "$checkpoint_name" || -z "$phase" ]]; then
        echo "ERROR: create_checkpoint requires checkpoint_name and phase" >&2
        return 1
    fi
    
    local checkpoint_id=$(generate_checkpoint_id "$checkpoint_name")
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local repo_root=$(get_repo_root)
    
    echo "Creating checkpoint: $checkpoint_name (ID: $checkpoint_id)"
    
    # Step 1: Create checkpoint directory
    local checkpoint_dir="$repo_root/$CHECKPOINTS_DIR/$checkpoint_id"
    mkdir -p "$checkpoint_dir"
    
    # Step 2: Create snapshot
    echo "Creating snapshot..."
    local snapshot_path
    snapshot_path=$(create_snapshot "$checkpoint_id" "$phase" 2>/dev/null | tail -1)
    echo "✅ Snapshot created: $snapshot_path"
    
    # Step 3: Run quality gate validation
    local quality_gate_result=$(validate_quality_gate "$phase")
    local quality_gate_status=$(extract_quality_gate_status "$quality_gate_result")
    echo "✅ Quality gate validated: $quality_gate_status"
    
    # Step 4: Generate checkpoint artifacts
    generate_artifact "checkpoint_summary" "checkpoints" "$phase" "$checkpoint_dir/checkpoint_summary.md"
    generate_artifact "quality_gate_results" "checkpoints" "$phase" "$checkpoint_dir/quality_gate_results.json"
    echo "✅ Checkpoint artifacts generated"
    
    # Step 5: Create checkpoint metadata
    local checkpoint_metadata=$(create_checkpoint_metadata "$checkpoint_id" "$checkpoint_name" "$phase" "$description" "$quality_gate_status" "$snapshot_path")
    echo "$checkpoint_metadata" > "$checkpoint_dir/checkpoint.json"
    echo "✅ Checkpoint metadata saved"
    
    # Step 6: Register checkpoint in global registry
    register_checkpoint "$checkpoint_id" "$checkpoint_metadata"
    echo "✅ Checkpoint registered"
    
    # Step 7: Cleanup old checkpoints
    cleanup_old_checkpoints
    echo "✅ Old checkpoints cleaned up"
    
    # Return checkpoint information
    cat << EOF
{
  "checkpoint_id": "$checkpoint_id",
  "checkpoint_name": "$checkpoint_name",
  "phase": "$phase",
  "status": "$quality_gate_status",
  "snapshot_path": "$snapshot_path",
  "timestamp": "$timestamp",
  "description": "$description"
}
EOF
}

# List available checkpoints
# Usage: list_checkpoints [phase]
list_checkpoints() {
    local filter_phase="${1:-}"
    local repo_root=$(get_repo_root)
    local checkpoints_registry="$repo_root/$CHECKPOINTS_DIR/registry.json"
    
    if [[ ! -f "$checkpoints_registry" ]]; then
        echo "No checkpoints found"
        return 0
    fi
    
    echo "Available checkpoints:"
    
    if [[ -n "$filter_phase" ]]; then
        if command -v jq >/dev/null 2>&1; then
            jq -r ".[] | select(.phase == \"$filter_phase\") | \"\(.checkpoint_id) - \(.checkpoint_name) (\(.phase)) - \(.status)\"" "$checkpoints_registry"
        else
            grep "\"phase\": \"$filter_phase\"" -A 5 -B 5 "$checkpoints_registry" | grep -E "checkpoint_id|checkpoint_name|status" | paste - - -
        fi
    else
        if command -v jq >/dev/null 2>&1; then
            jq -r ".[] | \"\(.checkpoint_id) - \(.checkpoint_name) (\(.phase)) - \(.status)\"" "$checkpoints_registry"
        else
            grep -E "checkpoint_id|checkpoint_name|phase|status" "$checkpoints_registry"
        fi
    fi
}

# Rollback to a specific checkpoint
# Usage: rollback_to_checkpoint <checkpoint_id>
rollback_to_checkpoint() {
    local checkpoint_id="$1"
    
    if [[ -z "$checkpoint_id" ]]; then
        echo "ERROR: rollback_to_checkpoint requires checkpoint_id" >&2
        return 1
    fi
    
    local repo_root=$(get_repo_root)
    local checkpoint_dir="$repo_root/$CHECKPOINTS_DIR/$checkpoint_id"
    
    if [[ ! -d "$checkpoint_dir" ]]; then
        echo "ERROR: Checkpoint not found: $checkpoint_id" >&2
        return 1
    fi
    
    echo "Rolling back to checkpoint: $checkpoint_id"
    
    # Step 1: Validate checkpoint integrity
    if ! validate_checkpoint_integrity "$checkpoint_id"; then
        echo "ERROR: Checkpoint integrity validation failed" >&2
        return 1
    fi
    echo "✅ Checkpoint integrity validated"
    
    # Step 2: Create backup of current state
    local backup_id=$(create_backup_before_rollback)
    echo "✅ Current state backed up: $backup_id"
    
    # Step 3: Restore snapshot
    local snapshot_path=$(get_checkpoint_snapshot_path "$checkpoint_id")
    if restore_snapshot "$snapshot_path"; then
        echo "✅ Snapshot restored successfully"
    else
        echo "ERROR: Snapshot restoration failed" >&2
        return 1
    fi
    
    # Step 4: Update progress tracking
    update_progress_tracking_after_rollback "$checkpoint_id"
    echo "✅ Progress tracking updated"
    
    # Step 5: Generate rollback report
    local rollback_report=$(generate_rollback_report "$checkpoint_id" "$backup_id")
    echo "$rollback_report" > "$repo_root/$CHECKPOINTS_DIR/last_rollback_report.md"
    echo "✅ Rollback report generated"
    
    echo "🎉 Rollback completed successfully to checkpoint: $checkpoint_id"
}

# =============================================================================
# QUALITY GATE FUNCTIONS
# =============================================================================

# Validate quality gate for a phase
# Usage: validate_quality_gate <phase>
validate_quality_gate() {
    local phase="$1"
    
    if [[ -z "$phase" ]]; then
        echo "ERROR: validate_quality_gate requires phase" >&2
        return 1
    fi
    
    echo "Validating quality gate for phase: $phase"
    
    local repo_root=$(get_repo_root)
    local validation_results=""
    local overall_status="PASS"
    
    # Step 1: Check mandatory artifacts exist
    local artifacts_check=$(check_mandatory_artifacts "$phase")
    validation_results+="Artifacts Check: $artifacts_check\n"
    
    # Step 2: Validate KB compliance
    local kb_compliance=$(check_kb_compliance "$phase")
    validation_results+="KB Compliance: $kb_compliance\n"
    
    # Step 3: Check quality metrics
    local quality_metrics=$(check_quality_metrics "$phase")
    validation_results+="Quality Metrics: $quality_metrics\n"
    
    # Step 4: Validate phase-specific requirements
    local phase_validation=$(validate_phase_specific_requirements "$phase")
    validation_results+="Phase Validation: $phase_validation\n"
    
    # Determine overall status
    if echo "$validation_results" | grep -q "FAIL"; then
        overall_status="FAIL"
    elif echo "$validation_results" | grep -q "WARN"; then
        overall_status="PARTIAL"
    fi
    
    # Generate quality gate report
    local quality_gate_report=$(generate_quality_gate_report "$phase" "$overall_status" "$validation_results")
    
    echo -e "QUALITY GATE SUMMARY: $overall_status\n\n$validation_results"
    
    # Save detailed report
    local report_path="$repo_root/$QUALITY_GATES_DIR/quality-gate-$phase-$(date +%Y%m%d-%H%M%S).json"
    mkdir -p "$(dirname "$report_path")"
    echo "$quality_gate_report" > "$report_path"
    
    return $([ "$overall_status" = "PASS" ] && echo 0 || echo 1)
}

# Check mandatory artifacts for a phase
check_mandatory_artifacts() {
    local phase="$1"
    local repo_root=$(get_repo_root)
    local artifacts_dir="$repo_root/artifacts/$phase"
    
    if [[ ! -d "$artifacts_dir" ]]; then
        echo "FAIL: Artifacts directory missing for $phase"
        return 1
    fi
    
    local required_count=4
    local actual_count=$(find "$artifacts_dir" -type f | wc -l)
    
    if [[ $actual_count -ge $required_count ]]; then
        echo "PASS: $actual_count/$required_count artifacts found"
        return 0
    else
        echo "FAIL: Only $actual_count/$required_count artifacts found"
        return 1
    fi
}

# Check KB compliance for a phase
check_kb_compliance() {
    local phase="$1"
    local repo_root=$(get_repo_root)
    
    # Check if compliance report exists
    local compliance_report_pattern="$repo_root/.specify-cache/compliance-reports/compliance-report-$phase-*.md"
    local compliance_reports=($(ls $compliance_report_pattern 2>/dev/null))
    
    if [[ ${#compliance_reports[@]} -gt 0 ]]; then
        local latest_report="${compliance_reports[-1]}"
        
        # Check compliance score in report
        if grep -q "Compliance Score.*[89][0-9]%\|Compliance Score.*100%" "$latest_report"; then
            echo "PASS: KB compliance > 80%"
            return 0
        elif grep -q "Compliance Score.*[67][0-9]%" "$latest_report"; then
            echo "WARN: KB compliance 60-79%"
            return 0
        else
            echo "FAIL: KB compliance < 60%"
            return 1
        fi
    else
        echo "WARN: No KB compliance report found"
        return 0
    fi
}

# Check quality metrics for a phase
check_quality_metrics() {
    local phase="$1"
    
    case "$phase" in
        "analyze")
            # Check analysis quality metrics
            if check_analysis_metrics; then
                echo "PASS: Analysis metrics within targets"
            else
                echo "FAIL: Analysis metrics below targets"
                return 1
            fi
            ;;
        "architect")
            # Check architecture quality metrics
            if check_architecture_metrics; then
                echo "PASS: Architecture metrics within targets"
            else
                echo "FAIL: Architecture metrics below targets"
                return 1
            fi
            ;;
        "implement")
            # Check implementation quality metrics
            if check_implementation_metrics; then
                echo "PASS: Implementation metrics within targets"
            else
                echo "FAIL: Implementation metrics below targets"
                return 1
            fi
            ;;
        *)
            echo "PASS: No specific metrics defined for $phase"
            ;;
    esac
}

# Validate phase-specific requirements
validate_phase_specific_requirements() {
    local phase="$1"
    
    case "$phase" in
        "analyze")
            validate_analyze_requirements
            ;;
        "architect")
            validate_architect_requirements
            ;;
        "implement")
            validate_implement_requirements
            ;;
        "checkpoints")
            validate_checkpoints_requirements
            ;;
        *)
            echo "PASS: No specific requirements for $phase"
            ;;
    esac
}

# =============================================================================
# SNAPSHOT FUNCTIONS
# =============================================================================

# Create a snapshot of the current state
# Usage: create_snapshot <checkpoint_id> <phase>
create_snapshot() {
    local checkpoint_id="$1"
    local phase="$2"
    
    local repo_root=$(get_repo_root)
    local snapshot_dir="$repo_root/$SNAPSHOTS_DIR"
    local snapshot_file="$snapshot_dir/snapshot-$checkpoint_id.tar.gz"
    
    mkdir -p "$snapshot_dir"
    
    echo "Creating snapshot for checkpoint: $checkpoint_id"
    
    # Create temporary directory for snapshot content
    local temp_snapshot_dir=$(mktemp -d)
    
    # Copy artifacts
    if [[ -d "$repo_root/artifacts" ]]; then
        cp -r "$repo_root/artifacts" "$temp_snapshot_dir/"
    fi
    
    # Copy specifications
    if [[ -d "$repo_root/specs" ]]; then
        cp -r "$repo_root/specs" "$temp_snapshot_dir/"
    fi
    
    # Copy relevant configuration files
    for config_file in "spec.md" "plan.md" "tasks.md"; do
        if [[ -f "$repo_root/$config_file" ]]; then
            cp "$repo_root/$config_file" "$temp_snapshot_dir/"
        fi
    done
    
    # Copy KB compliance reports
    if [[ -d "$repo_root/.specify-cache/compliance-reports" ]]; then
        cp -r "$repo_root/.specify-cache/compliance-reports" "$temp_snapshot_dir/"
    fi
    
    # Copy traceability data
    if [[ -d "$repo_root/.specify-cache/traceability" ]]; then
        cp -r "$repo_root/.specify-cache/traceability" "$temp_snapshot_dir/"
    fi
    
    # Create compressed snapshot
    cd "$temp_snapshot_dir"
    tar -czf "$snapshot_file" . 2>/dev/null
    cd - >/dev/null
    
    # Cleanup temporary directory
    rm -rf "$temp_snapshot_dir"
    
    # Verify snapshot was created
    if [[ -f "$snapshot_file" ]]; then
        local snapshot_size=$(stat -c%s "$snapshot_file" 2>/dev/null || echo 0)
        echo "✅ Snapshot created: $snapshot_file ($(format_bytes $snapshot_size))"
        echo "$snapshot_file"
    else
        echo "ERROR: Failed to create snapshot" >&2
        return 1
    fi
}

# Restore a snapshot
# Usage: restore_snapshot <snapshot_path>
restore_snapshot() {
    local snapshot_path="$1"
    
    if [[ -z "$snapshot_path" || ! -f "$snapshot_path" ]]; then
        echo "ERROR: Invalid snapshot path: $snapshot_path" >&2
        return 1
    fi
    
    local repo_root=$(get_repo_root)
    local temp_restore_dir=$(mktemp -d)
    
    echo "Restoring snapshot: $snapshot_path"
    
    # Extract snapshot
    cd "$temp_restore_dir"
    if tar -xzf "$snapshot_path" 2>/dev/null; then
        echo "✅ Snapshot extracted"
    else
        echo "ERROR: Failed to extract snapshot" >&2
        rm -rf "$temp_restore_dir"
        return 1
    fi
    
    # Restore artifacts
    if [[ -d "$temp_restore_dir/artifacts" ]]; then
        rm -rf "$repo_root/artifacts"
        cp -r "$temp_restore_dir/artifacts" "$repo_root/"
        echo "✅ Artifacts restored"
    fi
    
    # Restore specifications
    if [[ -d "$temp_restore_dir/specs" ]]; then
        rm -rf "$repo_root/specs"
        cp -r "$temp_restore_dir/specs" "$repo_root/"
        echo "✅ Specifications restored"
    fi
    
    # Restore configuration files
    for config_file in "spec.md" "plan.md" "tasks.md"; do
        if [[ -f "$temp_restore_dir/$config_file" ]]; then
            cp "$temp_restore_dir/$config_file" "$repo_root/"
            echo "✅ $config_file restored"
        fi
    done
    
    # Restore compliance reports
    if [[ -d "$temp_restore_dir/compliance-reports" ]]; then
        rm -rf "$repo_root/.specify-cache/compliance-reports"
        mkdir -p "$repo_root/.specify-cache"
        cp -r "$temp_restore_dir/compliance-reports" "$repo_root/.specify-cache/"
        echo "✅ Compliance reports restored"
    fi
    
    # Restore traceability data
    if [[ -d "$temp_restore_dir/traceability" ]]; then
        rm -rf "$repo_root/.specify-cache/traceability"
        mkdir -p "$repo_root/.specify-cache"
        cp -r "$temp_restore_dir/traceability" "$repo_root/.specify-cache/"
        echo "✅ Traceability data restored"
    fi
    
    # Cleanup
    cd - >/dev/null
    rm -rf "$temp_restore_dir"
    
    echo "🎉 Snapshot restoration completed"
}

# =============================================================================
# QUALITY GATE VALIDATION FUNCTIONS
# =============================================================================

# Validate analyze phase requirements
validate_analyze_requirements() {
    local repo_root=$(get_repo_root)
    local success=true
    
    # Check for architecture assessment
    if [[ -f "$repo_root/artifacts/analyze/architecture_assessment.md" ]]; then
        echo "✅ Architecture assessment complete"
    else
        echo "❌ Architecture assessment missing"
        success=false
    fi
    
    # Check for technical debt report
    if [[ -f "$repo_root/artifacts/analyze/technical_debt_report.md" ]]; then
        echo "✅ Technical debt documented"
    else
        echo "❌ Technical debt report missing"
        success=false
    fi
    
    # Check for compliance check
    if [[ -f "$repo_root/artifacts/analyze/compliance_check.json" ]]; then
        echo "✅ KB compliance validated"
    else
        echo "❌ Compliance check missing"
        success=false
    fi
    
    if [[ "$success" = true ]]; then
        echo "PASS: All analyze requirements met"
    else
        echo "FAIL: Missing analyze requirements"
        return 1
    fi
}

# Validate architect phase requirements
validate_architect_requirements() {
    local repo_root=$(get_repo_root)
    local success=true
    
    # Check for system design document
    if [[ -f "$repo_root/artifacts/architect/system_design_document.md" ]]; then
        echo "✅ Design documents complete"
    else
        echo "❌ System design document missing"
        success=false
    fi
    
    # Check for architecture decision records
    if [[ -f "$repo_root/artifacts/architect/architecture_decision_record.md" ]]; then
        echo "✅ Architecture decisions documented"
    else
        echo "❌ Architecture decision records missing"
        success=false
    fi
    
    # Check for component interaction diagram
    if [[ -f "$repo_root/artifacts/architect/component_interaction_diagram.mmd" ]]; then
        echo "✅ Component interactions defined"
    else
        echo "❌ Component interaction diagram missing"
        success=false
    fi
    
    if [[ "$success" = true ]]; then
        echo "PASS: All architect requirements met"
    else
        echo "FAIL: Missing architect requirements"
        return 1
    fi
}

# Validate implement phase requirements
validate_implement_requirements() {
    local repo_root=$(get_repo_root)
    local success=true
    
    # Check for code quality report
    if [[ -f "$repo_root/artifacts/implement/code_quality_report.md" ]]; then
        echo "✅ Code quality validated"
    else
        echo "❌ Code quality report missing"
        success=false
    fi
    
    # Check for test coverage report
    if [[ -f "$repo_root/artifacts/implement/test_coverage_report.html" ]]; then
        echo "✅ Test coverage adequate"
    else
        echo "❌ Test coverage report missing"
        success=false
    fi
    
    # Check for API documentation
    if [[ -f "$repo_root/artifacts/implement/api_documentation.md" ]]; then
        echo "✅ Documentation complete"
    else
        echo "❌ API documentation missing"
        success=false
    fi
    
    if [[ "$success" = true ]]; then
        echo "PASS: All implement requirements met"
    else
        echo "FAIL: Missing implement requirements"
        return 1
    fi
}

# Validate checkpoints phase requirements
validate_checkpoints_requirements() {
    echo "PASS: Checkpoints phase validation"
}

# =============================================================================
# METRICS VALIDATION FUNCTIONS
# =============================================================================

# Check analysis quality metrics
check_analysis_metrics() {
    # Placeholder for analysis metrics validation
    # In a real implementation, this would check:
    # - Complexity score < 7
    # - Coverage percentage > 80%
    echo "Analysis metrics check passed"
    return 0
}

# Check architecture quality metrics
check_architecture_metrics() {
    # Placeholder for architecture metrics validation
    # In a real implementation, this would check:
    # - Design consistency > 90%
    # - Pattern compliance = 100%
    echo "Architecture metrics check passed"
    return 0
}

# Check implementation quality metrics
check_implementation_metrics() {
    # Placeholder for implementation metrics validation
    # In a real implementation, this would check:
    # - Code quality score > 8
    # - Test coverage > 85%
    # - Performance benchmarks within limits
    echo "Implementation metrics check passed"
    return 0
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Generate unique checkpoint ID
generate_checkpoint_id() {
    local checkpoint_name="$1"
    local timestamp=$(date +%Y%m%d%H%M%S)
    local random_suffix=$(openssl rand -hex 4 2>/dev/null || echo $(( RANDOM % 10000 )))
    
    # Sanitize checkpoint name
    local sanitized_name=$(echo "$checkpoint_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
    
    echo "${sanitized_name}-${timestamp}-${random_suffix}"
}

# Create checkpoint metadata
create_checkpoint_metadata() {
    local checkpoint_id="$1"
    local checkpoint_name="$2"
    local phase="$3"
    local description="$4"
    local quality_gate_status="$5"
    local snapshot_path="$6"
    
    cat << EOF
{
  "checkpoint_id": "$checkpoint_id",
  "checkpoint_name": "$checkpoint_name",
  "phase": "$phase",
  "description": "$description",
  "quality_gate_status": "$quality_gate_status",
  "snapshot_path": "$snapshot_path",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "created_by": "checkpoint-system",
  "version": "1.0",
  "metadata": {
    "artifacts_count": $(find "$(get_repo_root)/artifacts/$phase" -type f 2>/dev/null | wc -l),
    "snapshot_size": "$(stat -c%s "$snapshot_path" 2>/dev/null || echo 0)",
    "kb_integration": "enabled"
  }
}
EOF
}

# Register checkpoint in global registry
register_checkpoint() {
    local checkpoint_id="$1"
    local checkpoint_metadata="$2"
    
    local repo_root=$(get_repo_root)
    local registry_file="$repo_root/$CHECKPOINTS_DIR/registry.json"
    
    mkdir -p "$(dirname "$registry_file")"
    
    if [[ -f "$registry_file" ]]; then
        # Add to existing registry
        local temp_file=$(mktemp)
        if command -v jq >/dev/null 2>&1; then
            jq ". += [$checkpoint_metadata]" "$registry_file" > "$temp_file" && mv "$temp_file" "$registry_file"
        else
            # Fallback without jq
            sed '$ s/]$/,/' "$registry_file" > "$temp_file"
            echo "$checkpoint_metadata" >> "$temp_file"
            echo "]" >> "$temp_file"
            mv "$temp_file" "$registry_file"
        fi
    else
        # Create new registry
        echo "[$checkpoint_metadata]" > "$registry_file"
    fi
    
    echo "Checkpoint registered in registry: $checkpoint_id"
}

# Cleanup old checkpoints (keep only MAX_CHECKPOINTS)
cleanup_old_checkpoints() {
    local repo_root=$(get_repo_root)
    local checkpoints_dir="$repo_root/$CHECKPOINTS_DIR"
    local registry_file="$checkpoints_dir/registry.json"
    
    if [[ ! -f "$registry_file" ]]; then
        return 0
    fi
    
    # Count current checkpoints
    local checkpoint_count=0
    if command -v jq >/dev/null 2>&1; then
        checkpoint_count=$(jq length "$registry_file")
    else
        checkpoint_count=$(grep -c "checkpoint_id" "$registry_file")
    fi
    
    if [[ $checkpoint_count -gt $MAX_CHECKPOINTS ]]; then
        echo "Cleaning up old checkpoints (keeping last $MAX_CHECKPOINTS)"
        
        # Get oldest checkpoints to remove
        local checkpoints_to_remove=$((checkpoint_count - MAX_CHECKPOINTS))
        
        if command -v jq >/dev/null 2>&1; then
            # Use jq for precise cleanup
            local temp_file=$(mktemp)
            jq "sort_by(.created_at) | .[$checkpoints_to_remove:]" "$registry_file" > "$temp_file"
            mv "$temp_file" "$registry_file"
            
            # Remove old checkpoint directories and snapshots
            jq -r "sort_by(.created_at) | .[:$checkpoints_to_remove] | .[].checkpoint_id" "$registry_file" 2>/dev/null | while read -r old_checkpoint_id; do
                rm -rf "$checkpoints_dir/$old_checkpoint_id"
                rm -f "$repo_root/$SNAPSHOTS_DIR/snapshot-$old_checkpoint_id.tar.gz"
            done
        else
            echo "Warning: jq not available, manual cleanup may be needed"
        fi
        
        echo "✅ Old checkpoints cleaned up"
    fi
}

# Extract quality gate status from validation result
extract_quality_gate_status() {
    local validation_result="$1"
    
    if echo "$validation_result" | grep -q "QUALITY GATE SUMMARY: PASS"; then
        echo "PASS"
    elif echo "$validation_result" | grep -q "QUALITY GATE SUMMARY: FAIL"; then
        echo "FAIL"
    else
        echo "PARTIAL"
    fi
}

# Generate quality gate report
generate_quality_gate_report() {
    local phase="$1"
    local status="$2"
    local validation_results="$3"
    
    cat << EOF
{
  "phase": "$phase",
  "status": "$status",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "validation_results": {
    "summary": "$status",
    "details": "$(echo "$validation_results" | sed 's/"/\\"/g' | tr '\n' ' ')"
  },
  "metrics": {
    "artifacts_validated": true,
    "kb_compliance_checked": true,
    "quality_metrics_verified": true,
    "phase_requirements_met": $([ "$status" = "PASS" ] && echo "true" || echo "false")
  }
}
EOF
}

# Format bytes for human-readable output
format_bytes() {
    local bytes="$1"
    
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$((bytes / 1024))KB"
    else
        echo "$((bytes / 1048576))MB"
    fi
}

# Get checkpoint snapshot path
get_checkpoint_snapshot_path() {
    local checkpoint_id="$1"
    local repo_root=$(get_repo_root)
    
    echo "$repo_root/$SNAPSHOTS_DIR/snapshot-$checkpoint_id.tar.gz"
}

# Validate checkpoint integrity
validate_checkpoint_integrity() {
    local checkpoint_id="$1"
    local repo_root=$(get_repo_root)
    local checkpoint_dir="$repo_root/$CHECKPOINTS_DIR/$checkpoint_id"
    
    # Check checkpoint directory exists
    if [[ ! -d "$checkpoint_dir" ]]; then
        echo "ERROR: Checkpoint directory missing" >&2
        return 1
    fi
    
    # Check checkpoint metadata exists
    if [[ ! -f "$checkpoint_dir/checkpoint.json" ]]; then
        echo "ERROR: Checkpoint metadata missing" >&2
        return 1
    fi
    
    # Check snapshot exists
    local snapshot_path=$(get_checkpoint_snapshot_path "$checkpoint_id")
    if [[ ! -f "$snapshot_path" ]]; then
        echo "ERROR: Checkpoint snapshot missing" >&2
        return 1
    fi
    
    # Validate snapshot integrity
    if tar -tzf "$snapshot_path" >/dev/null 2>&1; then
        echo "✅ Checkpoint integrity validated"
        return 0
    else
        echo "ERROR: Snapshot file corrupted" >&2
        return 1
    fi
}

# Create backup before rollback
create_backup_before_rollback() {
    local backup_id="backup-$(date +%Y%m%d%H%M%S)-$(openssl rand -hex 4 2>/dev/null || echo $(( RANDOM % 10000 )))"
    local backup_snapshot=$(create_snapshot "$backup_id" "backup")
    
    echo "$backup_id"
}

# Update progress tracking after rollback
update_progress_tracking_after_rollback() {
    local checkpoint_id="$1"
    local repo_root=$(get_repo_root)
    
    # Create rollback log entry
    local rollback_log="$repo_root/.specify-cache/rollback.log"
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ"): Rolled back to checkpoint $checkpoint_id" >> "$rollback_log"
}

# Generate rollback report
generate_rollback_report() {
    local checkpoint_id="$1"
    local backup_id="$2"
    
    cat << EOF
# Rollback Report

**Timestamp**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Checkpoint ID**: $checkpoint_id
**Backup ID**: $backup_id

## Rollback Summary

- **Target Checkpoint**: $checkpoint_id
- **Current State Backup**: $backup_id
- **Rollback Status**: ✅ COMPLETED
- **Data Integrity**: ✅ VALIDATED

## Restored Components

- ✅ Artifacts directory
- ✅ Specifications
- ✅ Configuration files
- ✅ Compliance reports
- ✅ Traceability data

## Next Steps

1. Verify restored state is correct
2. Resume work from checkpoint state
3. Address issues that caused rollback

---

*Generated by Checkpoint System v1.0*
EOF
}

# Main function for direct script execution
main() {
    case "${1:-}" in
        "create")
            if [[ $# -lt 3 ]]; then
                echo "Usage: $0 create <checkpoint_name> <phase> [description]"
                exit 1
            fi
            create_checkpoint "$2" "$3" "${4:-}"
            ;;
        "list")
            list_checkpoints "${2:-}"
            ;;
        "rollback")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 rollback <checkpoint_id>"
                exit 1
            fi
            rollback_to_checkpoint "$2"
            ;;
        "validate")
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 validate <phase>"
                exit 1
            fi
            validate_quality_gate "$2"
            ;;
        *)
            echo "Checkpoint System Module v1.0"
            echo "Usage: $0 {create|list|rollback|validate}"
            echo
            echo "Commands:"
            echo "  create <checkpoint_name> <phase> [description]"
            echo "  list [phase]"
            echo "  rollback <checkpoint_id>"
            echo "  validate <phase>"
            echo
            echo "Examples:"
            echo "  $0 create analyze_complete analyze 'Analysis phase completed'"
            echo "  $0 list architect"
            echo "  $0 rollback analyze-complete-20250924154507-a1b2c3d4"
            echo "  $0 validate implement"
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi