#!/usr/bin/env bash
# Checkpoint Control Interface
# User-friendly interface for checkpoint management
# Part of SDD v2.0 Critical Systems Implementation - Phase 3.2

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
source "$SCRIPT_DIR/checkpoint-system.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =============================================================================
# INTERACTIVE INTERFACE FUNCTIONS
# =============================================================================

# Display checkpoint dashboard
show_checkpoint_dashboard() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    CHECKPOINT DASHBOARD                     ║${NC}"
    echo -e "${BLUE}║                     SDD v2.0 System                         ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Show system status
    show_system_status
    echo
    
    # Show recent checkpoints
    echo -e "${CYAN}📋 Recent Checkpoints:${NC}"
    list_checkpoints | head -5
    echo
    
    # Show available actions
    show_available_actions
}

# Show system status
show_system_status() {
    local repo_root=$(get_repo_root)
    
    echo -e "${CYAN}🔧 System Status:${NC}"
    
    # Check if checkpoint system is available
    if [[ -f "$SCRIPT_DIR/checkpoint-system.sh" ]]; then
        echo -e "  ✅ Checkpoint System: ${GREEN}AVAILABLE${NC}"
    else
        echo -e "  ❌ Checkpoint System: ${RED}MISSING${NC}"
    fi
    
    # Check if artifact system is available
    if [[ -f "$SCRIPT_DIR/artifact-generation.sh" ]]; then
        echo -e "  ✅ Artifact System: ${GREEN}AVAILABLE${NC}"
    else
        echo -e "  ❌ Artifact System: ${RED}MISSING${NC}"
    fi
    
    # Check if KB system is available
    if [[ -f "$SCRIPT_DIR/knowledge-base-integration.sh" ]]; then
        echo -e "  ✅ Knowledge Base: ${GREEN}AVAILABLE${NC}"
    else
        echo -e "  ❌ Knowledge Base: ${RED}MISSING${NC}"
    fi
    
    # Show checkpoint count
    local checkpoint_count=0
    if [[ -f "$repo_root/$CHECKPOINTS_DIR/registry.json" ]]; then
        if command -v jq >/dev/null 2>&1; then
            checkpoint_count=$(jq length "$repo_root/$CHECKPOINTS_DIR/registry.json" 2>/dev/null || echo 0)
        else
            checkpoint_count=$(grep -c "checkpoint_id" "$repo_root/$CHECKPOINTS_DIR/registry.json" 2>/dev/null || echo 0)
        fi
    fi
    echo -e "  📊 Total Checkpoints: ${YELLOW}$checkpoint_count${NC}"
    
    # Show snapshot storage
    local snapshots_size=0
    if [[ -d "$repo_root/$SNAPSHOTS_DIR" ]]; then
        snapshots_size=$(du -sh "$repo_root/$SNAPSHOTS_DIR" 2>/dev/null | cut -f1 || echo "0")
    fi
    echo -e "  💾 Snapshots Storage: ${YELLOW}$snapshots_size${NC}"
}

# Show available actions
show_available_actions() {
    echo -e "${CYAN}🎯 Available Actions:${NC}"
    echo -e "  ${GREEN}1.${NC} Create checkpoint for current phase"
    echo -e "  ${GREEN}2.${NC} List all checkpoints"
    echo -e "  ${GREEN}3.${NC} List checkpoints by phase"
    echo -e "  ${GREEN}4.${NC} Validate quality gate for phase"
    echo -e "  ${GREEN}5.${NC} Rollback to checkpoint"
    echo -e "  ${GREEN}6.${NC} Show checkpoint details"
    echo -e "  ${GREEN}7.${NC} Cleanup old checkpoints"
    echo -e "  ${GREEN}8.${NC} System diagnostics"
    echo -e "  ${GREEN}q.${NC} Quit"
    echo
}

# Interactive checkpoint creation
interactive_create_checkpoint() {
    echo -e "${BLUE}📝 Create New Checkpoint${NC}"
    echo
    
    # Get checkpoint name
    read -p "Enter checkpoint name: " checkpoint_name
    if [[ -z "$checkpoint_name" ]]; then
        echo -e "${RED}❌ Checkpoint name cannot be empty${NC}"
        return 1
    fi
    
    # Get phase
    echo "Available phases: analyze, architect, implement, checkpoints"
    read -p "Enter phase: " phase
    if [[ ! "$phase" =~ ^(analyze|architect|implement|checkpoints)$ ]]; then
        echo -e "${RED}❌ Invalid phase. Must be: analyze, architect, implement, or checkpoints${NC}"
        return 1
    fi
    
    # Get description
    read -p "Enter description (optional): " description
    
    # Create checkpoint
    echo
    echo -e "${YELLOW}Creating checkpoint...${NC}"
    
    if checkpoint_result=$(create_checkpoint "$checkpoint_name" "$phase" "$description"); then
        echo -e "${GREEN}✅ Checkpoint created successfully!${NC}"
        echo
        echo "$checkpoint_result" | jq . 2>/dev/null || echo "$checkpoint_result"
    else
        echo -e "${RED}❌ Failed to create checkpoint${NC}"
        return 1
    fi
}

# Interactive checkpoint listing
interactive_list_checkpoints() {
    echo -e "${BLUE}📋 Checkpoint Listing${NC}"
    echo
    
    read -p "Filter by phase (leave empty for all): " filter_phase
    
    echo
    if [[ -n "$filter_phase" ]]; then
        echo -e "${CYAN}Checkpoints for phase: $filter_phase${NC}"
        list_checkpoints "$filter_phase"
    else
        echo -e "${CYAN}All checkpoints:${NC}"
        list_checkpoints
    fi
}

# Interactive quality gate validation
interactive_validate_quality_gate() {
    echo -e "${BLUE}✅ Quality Gate Validation${NC}"
    echo
    
    echo "Available phases: analyze, architect, implement"
    read -p "Enter phase to validate: " phase
    
    if [[ ! "$phase" =~ ^(analyze|architect|implement)$ ]]; then
        echo -e "${RED}❌ Invalid phase. Must be: analyze, architect, or implement${NC}"
        return 1
    fi
    
    echo
    echo -e "${YELLOW}Validating quality gate for $phase...${NC}"
    
    if quality_gate_result=$(validate_quality_gate "$phase"); then
        echo -e "${GREEN}✅ Quality gate validation completed${NC}"
        echo
        echo "$quality_gate_result"
    else
        echo -e "${RED}❌ Quality gate validation failed${NC}"
        echo
        echo "$quality_gate_result"
    fi
}

# Interactive rollback
interactive_rollback() {
    echo -e "${BLUE}🔄 Checkpoint Rollback${NC}"
    echo
    
    # Show available checkpoints
    echo -e "${CYAN}Available checkpoints:${NC}"
    list_checkpoints
    echo
    
    read -p "Enter checkpoint ID to rollback to: " checkpoint_id
    
    if [[ -z "$checkpoint_id" ]]; then
        echo -e "${RED}❌ Checkpoint ID cannot be empty${NC}"
        return 1
    fi
    
    # Confirm rollback
    echo
    echo -e "${YELLOW}⚠️  WARNING: This will restore the system to the selected checkpoint state.${NC}"
    echo -e "${YELLOW}   Current state will be backed up automatically.${NC}"
    read -p "Are you sure you want to proceed? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo
        echo -e "${YELLOW}Rolling back to checkpoint: $checkpoint_id${NC}"
        
        if rollback_to_checkpoint "$checkpoint_id"; then
            echo -e "${GREEN}✅ Rollback completed successfully!${NC}"
        else
            echo -e "${RED}❌ Rollback failed${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}Rollback cancelled${NC}"
    fi
}

# Show checkpoint details
show_checkpoint_details() {
    echo -e "${BLUE}🔍 Checkpoint Details${NC}"
    echo
    
    read -p "Enter checkpoint ID: " checkpoint_id
    
    if [[ -z "$checkpoint_id" ]]; then
        echo -e "${RED}❌ Checkpoint ID cannot be empty${NC}"
        return 1
    fi
    
    local repo_root=$(get_repo_root)
    local checkpoint_dir="$repo_root/$CHECKPOINTS_DIR/$checkpoint_id"
    
    if [[ ! -d "$checkpoint_dir" ]]; then
        echo -e "${RED}❌ Checkpoint not found: $checkpoint_id${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Checkpoint Information:${NC}"
    
    # Show checkpoint metadata
    if [[ -f "$checkpoint_dir/checkpoint.json" ]]; then
        echo
        cat "$checkpoint_dir/checkpoint.json" | jq . 2>/dev/null || cat "$checkpoint_dir/checkpoint.json"
    fi
    
    # Show checkpoint files
    echo
    echo -e "${CYAN}Checkpoint Files:${NC}"
    ls -la "$checkpoint_dir"
    
    # Show snapshot information
    local snapshot_path=$(get_checkpoint_snapshot_path "$checkpoint_id")
    if [[ -f "$snapshot_path" ]]; then
        local snapshot_size=$(stat -c%s "$snapshot_path" 2>/dev/null || echo 0)
        echo
        echo -e "${CYAN}Snapshot Information:${NC}"
        echo -e "  Path: $snapshot_path"
        echo -e "  Size: $(format_bytes $snapshot_size)"
    fi
}

# System diagnostics
run_system_diagnostics() {
    echo -e "${BLUE}🔧 System Diagnostics${NC}"
    echo
    
    local repo_root=$(get_repo_root)
    local issues_found=false
    
    echo -e "${CYAN}Checking system components...${NC}"
    
    # Check required scripts
    local required_scripts=("checkpoint-system.sh" "artifact-generation.sh" "knowledge-base-integration.sh" "common.sh")
    
    for script in "${required_scripts[@]}"; do
        if [[ -f "$SCRIPT_DIR/$script" ]]; then
            echo -e "  ✅ $script: ${GREEN}FOUND${NC}"
        else
            echo -e "  ❌ $script: ${RED}MISSING${NC}"
            issues_found=true
        fi
    done
    
    # Check required directories
    local required_dirs=("$CHECKPOINTS_DIR" "$SNAPSHOTS_DIR" "$QUALITY_GATES_DIR" "artifacts" "templates/artifacts")
    
    echo
    echo -e "${CYAN}Checking directories...${NC}"
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$repo_root/$dir" ]]; then
            echo -e "  ✅ $dir: ${GREEN}EXISTS${NC}"
        else
            echo -e "  ⚠️  $dir: ${YELLOW}MISSING (will be created)${NC}"
            mkdir -p "$repo_root/$dir"
        fi
    done
    
    # Check templates
    echo
    echo -e "${CYAN}Checking artifact templates...${NC}"
    
    local phases=("analyze" "architect" "implement" "checkpoints")
    for phase in "${phases[@]}"; do
        local template_count=$(find "$repo_root/templates/artifacts/$phase" -name "*.template.*" 2>/dev/null | wc -l)
        if [[ $template_count -ge 4 ]]; then
            echo -e "  ✅ $phase templates: ${GREEN}$template_count FOUND${NC}"
        else
            echo -e "  ⚠️  $phase templates: ${YELLOW}$template_count FOUND (expected 4+)${NC}"
        fi
    done
    
    # Check permissions
    echo
    echo -e "${CYAN}Checking script permissions...${NC}"
    
    for script in "${required_scripts[@]}"; do
        if [[ -x "$SCRIPT_DIR/$script" ]]; then
            echo -e "  ✅ $script: ${GREEN}EXECUTABLE${NC}"
        else
            echo -e "  ⚠️  $script: ${YELLOW}NOT EXECUTABLE${NC}"
            chmod +x "$SCRIPT_DIR/$script" 2>/dev/null
        fi
    done
    
    # Summary
    echo
    if [[ "$issues_found" = false ]]; then
        echo -e "${GREEN}🎉 System diagnostics completed - No critical issues found${NC}"
    else
        echo -e "${YELLOW}⚠️  System diagnostics completed - Some issues found and fixed${NC}"
    fi
}

# Cleanup old checkpoints with confirmation
interactive_cleanup() {
    echo -e "${BLUE}🧹 Checkpoint Cleanup${NC}"
    echo
    
    local repo_root=$(get_repo_root)
    local registry_file="$repo_root/$CHECKPOINTS_DIR/registry.json"
    
    if [[ ! -f "$registry_file" ]]; then
        echo -e "${YELLOW}No checkpoints found to cleanup${NC}"
        return 0
    fi
    
    local checkpoint_count=0
    if command -v jq >/dev/null 2>&1; then
        checkpoint_count=$(jq length "$registry_file" 2>/dev/null || echo 0)
    else
        checkpoint_count=$(grep -c "checkpoint_id" "$registry_file" 2>/dev/null || echo 0)
    fi
    
    echo -e "Current checkpoints: ${YELLOW}$checkpoint_count${NC}"
    echo -e "Maximum allowed: ${YELLOW}$MAX_CHECKPOINTS${NC}"
    
    if [[ $checkpoint_count -le $MAX_CHECKPOINTS ]]; then
        echo -e "${GREEN}✅ No cleanup needed${NC}"
        return 0
    fi
    
    local checkpoints_to_remove=$((checkpoint_count - MAX_CHECKPOINTS))
    echo -e "${YELLOW}⚠️  Will remove $checkpoints_to_remove oldest checkpoints${NC}"
    
    read -p "Proceed with cleanup? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        cleanup_old_checkpoints
        echo -e "${GREEN}✅ Cleanup completed${NC}"
    else
        echo -e "${YELLOW}Cleanup cancelled${NC}"
    fi
}

# =============================================================================
# AUTOMATED QUALITY METRICS
# =============================================================================

# Generate quality metrics report
generate_quality_metrics_report() {
    local repo_root=$(get_repo_root)
    local report_file="$repo_root/.specify-cache/quality-metrics/quality_metrics_$(date +%Y%m%d_%H%M%S).json"
    
    mkdir -p "$(dirname "$report_file")"
    
    echo -e "${BLUE}📊 Generating Quality Metrics Report${NC}"
    
    # Collect metrics from all phases
    local analyze_metrics=$(collect_phase_metrics "analyze")
    local architect_metrics=$(collect_phase_metrics "architect")
    local implement_metrics=$(collect_phase_metrics "implement")
    
    # Generate comprehensive report
    cat > "$report_file" << EOF
{
  "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "report_version": "1.0",
  "system_version": "SDD v2.0",
  "phases": {
    "analyze": $analyze_metrics,
    "architect": $architect_metrics,
    "implement": $implement_metrics
  },
  "overall_metrics": {
    "total_artifacts": $(find "$repo_root/artifacts" -type f 2>/dev/null | wc -l),
    "total_checkpoints": $(grep -c "checkpoint_id" "$repo_root/$CHECKPOINTS_DIR/registry.json" 2>/dev/null || echo 0),
    "system_health": "$(check_overall_system_health)"
  }
}
EOF
    
    echo -e "${GREEN}✅ Quality metrics report generated: $report_file${NC}"
    
    # Display summary
    echo
    echo -e "${CYAN}📈 Quality Metrics Summary:${NC}"
    if command -v jq >/dev/null 2>&1; then
        jq -r '.overall_metrics | to_entries[] | "  \(.key): \(.value)"' "$report_file"
    else
        grep -E "total_artifacts|total_checkpoints|system_health" "$report_file"
    fi
}

# Collect metrics for a specific phase
collect_phase_metrics() {
    local phase="$1"
    local repo_root=$(get_repo_root)
    
    local artifacts_count=$(find "$repo_root/artifacts/$phase" -type f 2>/dev/null | wc -l)
    local kb_compliance="unknown"
    local quality_status="unknown"
    
    # Check latest compliance report
    local compliance_reports=($(ls "$repo_root/.specify-cache/compliance-reports/compliance-report-$phase-"*.md 2>/dev/null))
    if [[ ${#compliance_reports[@]} -gt 0 ]]; then
        local latest_report="${compliance_reports[-1]}"
        if grep -q "Compliance Score.*[89][0-9]%\|Compliance Score.*100%" "$latest_report"; then
            kb_compliance="high"
        elif grep -q "Compliance Score.*[67][0-9]%" "$latest_report"; then
            kb_compliance="medium"
        else
            kb_compliance="low"
        fi
    fi
    
    # Check quality gate status
    local quality_gates=($(ls "$repo_root/$QUALITY_GATES_DIR/quality-gate-$phase-"*.json 2>/dev/null))
    if [[ ${#quality_gates[@]} -gt 0 ]]; then
        local latest_gate="${quality_gates[-1]}"
        if grep -q '"status": "PASS"' "$latest_gate"; then
            quality_status="pass"
        elif grep -q '"status": "FAIL"' "$latest_gate"; then
            quality_status="fail"
        else
            quality_status="partial"
        fi
    fi
    
    cat << EOF
{
  "artifacts_count": $artifacts_count,
  "kb_compliance": "$kb_compliance",
  "quality_gate_status": "$quality_status",
  "last_updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
}

# Check overall system health
check_overall_system_health() {
    local repo_root=$(get_repo_root)
    
    # Check if all required components are present
    local required_components=("artifacts" "templates/artifacts" "$CHECKPOINTS_DIR" "$SNAPSHOTS_DIR")
    local missing_components=0
    
    for component in "${required_components[@]}"; do
        if [[ ! -d "$repo_root/$component" ]]; then
            ((missing_components++))
        fi
    done
    
    if [[ $missing_components -eq 0 ]]; then
        echo "healthy"
    elif [[ $missing_components -le 2 ]]; then
        echo "degraded"
    else
        echo "unhealthy"
    fi
}

# =============================================================================
# MAIN INTERACTIVE LOOP
# =============================================================================

# Main interactive function
interactive_mode() {
    while true; do
        clear
        show_checkpoint_dashboard
        
        read -p "Select an action (1-8, q): " choice
        
        case "$choice" in
            "1")
                clear
                interactive_create_checkpoint
                read -p "Press Enter to continue..."
                ;;
            "2")
                clear
                interactive_list_checkpoints
                read -p "Press Enter to continue..."
                ;;
            "3")
                clear
                interactive_list_checkpoints
                read -p "Press Enter to continue..."
                ;;
            "4")
                clear
                interactive_validate_quality_gate
                read -p "Press Enter to continue..."
                ;;
            "5")
                clear
                interactive_rollback
                read -p "Press Enter to continue..."
                ;;
            "6")
                clear
                show_checkpoint_details
                read -p "Press Enter to continue..."
                ;;
            "7")
                clear
                interactive_cleanup
                read -p "Press Enter to continue..."
                ;;
            "8")
                clear
                run_system_diagnostics
                read -p "Press Enter to continue..."
                ;;
            "q"|"Q")
                echo -e "${GREEN}👋 Goodbye!${NC}"
                break
                ;;
            *)
                echo -e "${RED}❌ Invalid choice. Please select 1-8 or q.${NC}"
                sleep 2
                ;;
        esac
    done
}

# =============================================================================
# COMMAND LINE INTERFACE
# =============================================================================

# Main function for command line usage
main() {
    case "${1:-}" in
        "dashboard")
            show_checkpoint_dashboard
            ;;
        "status")
            show_system_status
            ;;
        "metrics")
            generate_quality_metrics_report
            ;;
        "interactive"|"")
            interactive_mode
            ;;
        *)
            echo "Checkpoint Control Interface v1.0"
            echo "Usage: $0 {dashboard|status|metrics|interactive}"
            echo
            echo "Commands:"
            echo "  dashboard    - Show checkpoint dashboard"
            echo "  status       - Show system status"
            echo "  metrics      - Generate quality metrics report"
            echo "  interactive  - Start interactive mode (default)"
            echo
            echo "Examples:"
            echo "  $0 dashboard"
            echo "  $0 status"
            echo "  $0 metrics"
            echo "  $0 interactive"
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]] || [[ -z "${BASH_SOURCE[0]:-}" ]]; then
    main "$@"
fi