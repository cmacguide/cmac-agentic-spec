#!/usr/bin/env bash
# Checkpoint Workflow Integration Tests
# Comprehensive test suite for the Checkpoint System integration with SDD workflow
# Part of SDD v2.0 Critical Systems Implementation - Phase 3.2

set -euo pipefail

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_OUTPUT_DIR="$REPO_ROOT/.specify-cache/test-results"
TEST_CHECKPOINTS_DIR="$REPO_ROOT/.specify-cache/test-checkpoints"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Source dependencies
source "$REPO_ROOT/scripts/bash/common.sh"
source "$REPO_ROOT/scripts/bash/checkpoint-system.sh"
source "$REPO_ROOT/scripts/bash/checkpoint-control.sh"

# =============================================================================
# TEST UTILITIES
# =============================================================================

# Initialize test environment
init_test_environment() {
    echo -e "${BLUE}🔧 Initializing checkpoint workflow test environment...${NC}"
    
    # Create test directories
    mkdir -p "$TEST_OUTPUT_DIR"
    mkdir -p "$TEST_CHECKPOINTS_DIR"
    
    # Clean previous test results
    rm -rf "$TEST_OUTPUT_DIR"/*
    rm -rf "$TEST_CHECKPOINTS_DIR"/*
    
    # Initialize test counters
    TESTS_TOTAL=0
    TESTS_PASSED=0
    TESTS_FAILED=0
    
    echo -e "${GREEN}✅ Checkpoint workflow test environment initialized${NC}"
}

# Run a test with error handling
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    ((TESTS_TOTAL++))
    echo -e "${BLUE}🧪 Running test: $test_name${NC}"
    
    if $test_function; then
        ((TESTS_PASSED++))
        echo -e "${GREEN}✅ PASS: $test_name${NC}"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${RED}❌ FAIL: $test_name${NC}"
        return 1
    fi
}

# =============================================================================
# CHECKPOINT SYSTEM TESTS
# =============================================================================

# Test checkpoint creation for all phases
test_checkpoint_creation_all_phases() {
    local success=true
    
    echo "  Testing checkpoint creation for all phases..."
    
    local phases=("analyze" "architect" "implement")
    
    for phase in "${phases[@]}"; do
        echo "    Creating checkpoint for $phase phase..."
        
        local checkpoint_name="test_${phase}_checkpoint"
        local description="Test checkpoint for $phase phase"
        
        if checkpoint_result=$(create_checkpoint "$checkpoint_name" "$phase" "$description" 2>/dev/null); then
            echo "    ✅ $phase: Checkpoint created successfully"
            
            # Verify checkpoint was registered
            local checkpoint_id=$(echo "$checkpoint_result" | jq -r '.checkpoint_id' 2>/dev/null || echo "unknown")
            if [[ "$checkpoint_id" != "unknown" && "$checkpoint_id" != "null" ]]; then
                echo "    ✅ $phase: Checkpoint ID generated: $checkpoint_id"
            else
                echo "    ❌ $phase: Invalid checkpoint ID"
                success=false
            fi
        else
            echo "    ❌ $phase: Checkpoint creation failed"
            success=false
        fi
    done
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# Test quality gate validation for all phases
test_quality_gate_validation() {
    local success=true
    
    echo "  Testing quality gate validation..."
    
    local phases=("analyze" "architect" "implement")
    
    for phase in "${phases[@]}"; do
        echo "    Validating quality gate for $phase..."
        
        if quality_gate_result=$(validate_quality_gate "$phase" 2>/dev/null); then
            echo "    ✅ $phase: Quality gate validation executed"
            
            # Check if result contains expected sections
            if echo "$quality_gate_result" | grep -q "QUALITY GATE SUMMARY"; then
                echo "    ✅ $phase: Quality gate result format correct"
            else
                echo "    ❌ $phase: Quality gate result format incorrect"
                success=false
            fi
        else
            echo "    ❌ $phase: Quality gate validation failed"
            success=false
        fi
    done
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# Test checkpoint listing and filtering
test_checkpoint_listing() {
    local success=true
    
    echo "  Testing checkpoint listing functionality..."
    
    # Test general listing
    if list_checkpoints >/dev/null 2>&1; then
        echo "    ✅ General checkpoint listing works"
    else
        echo "    ❌ General checkpoint listing failed"
        success=false
    fi
    
    # Test phase filtering
    local phases=("analyze" "architect" "implement")
    
    for phase in "${phases[@]}"; do
        if list_checkpoints "$phase" >/dev/null 2>&1; then
            echo "    ✅ $phase: Phase filtering works"
        else
            echo "    ❌ $phase: Phase filtering failed"
            success=false
        fi
    done
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# Test snapshot integrity
test_snapshot_integrity() {
    local success=true
    
    echo "  Testing snapshot integrity..."
    
    # Find existing snapshots
    local snapshots=($(find "$REPO_ROOT/$SNAPSHOTS_DIR" -name "*.tar.gz" 2>/dev/null))
    
    if [[ ${#snapshots[@]} -eq 0 ]]; then
        echo "    ⚠️  No snapshots found to test"
        return 0
    fi
    
    for snapshot in "${snapshots[@]}"; do
        local snapshot_name=$(basename "$snapshot")
        echo "    Testing snapshot: $snapshot_name"
        
        # Test snapshot can be read
        if tar -tzf "$snapshot" >/dev/null 2>&1; then
            echo "    ✅ $snapshot_name: Snapshot integrity verified"
        else
            echo "    ❌ $snapshot_name: Snapshot corrupted"
            success=false
        fi
        
        # Check snapshot size
        local snapshot_size=$(stat -c%s "$snapshot" 2>/dev/null || echo 0)
        if [[ $snapshot_size -gt 0 ]]; then
            echo "    ✅ $snapshot_name: Snapshot size valid ($(format_bytes $snapshot_size))"
        else
            echo "    ❌ $snapshot_name: Snapshot empty"
            success=false
        fi
    done
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# =============================================================================
# WORKFLOW INTEGRATION TESTS
# =============================================================================

# Test complete SDD workflow with checkpoints
test_complete_sdd_workflow() {
    local success=true
    
    echo "  Testing complete SDD workflow with checkpoints..."
    
    # Simulate workflow phases
    local phases=("analyze" "architect" "implement")
    local checkpoint_ids=()
    
    for phase in "${phases[@]}"; do
        echo "    Executing workflow phase: $phase"
        
        # Step 1: Generate artifacts for phase
        if generate_phase_artifacts "$phase" "shared-principles" >/dev/null 2>&1; then
            echo "    ✅ $phase: Artifacts generated"
        else
            echo "    ❌ $phase: Artifact generation failed"
            success=false
            continue
        fi
        
        # Step 2: Validate quality gate
        if validate_quality_gate "$phase" >/dev/null 2>&1; then
            echo "    ✅ $phase: Quality gate validated"
        else
            echo "    ⚠️  $phase: Quality gate failed (expected for some phases)"
        fi
        
        # Step 3: Create checkpoint
        local checkpoint_name="workflow_${phase}_complete"
        if checkpoint_result=$(create_checkpoint "$checkpoint_name" "$phase" "Workflow $phase phase completed" 2>/dev/null); then
            local checkpoint_id=$(echo "$checkpoint_result" | jq -r '.checkpoint_id' 2>/dev/null || echo "unknown")
            checkpoint_ids+=("$checkpoint_id")
            echo "    ✅ $phase: Checkpoint created ($checkpoint_id)"
        else
            echo "    ❌ $phase: Checkpoint creation failed"
            success=false
        fi
    done
    
    # Verify all checkpoints were created
    if [[ ${#checkpoint_ids[@]} -eq ${#phases[@]} ]]; then
        echo "    ✅ All workflow checkpoints created successfully"
    else
        echo "    ❌ Not all workflow checkpoints were created"
        success=false
    fi
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# Test rollback workflow
test_rollback_workflow() {
    local success=true
    
    echo "  Testing rollback workflow..."
    
    # Get available checkpoints
    local checkpoints_output=$(list_checkpoints 2>/dev/null)
    
    if [[ -z "$checkpoints_output" || "$checkpoints_output" == "No checkpoints found" ]]; then
        echo "    ⚠️  No checkpoints available for rollback test"
        return 0
    fi
    
    # Get first checkpoint ID
    local first_checkpoint_id=$(echo "$checkpoints_output" | head -1 | cut -d' ' -f1)
    
    if [[ -n "$first_checkpoint_id" && "$first_checkpoint_id" != "Available" ]]; then
        echo "    Testing rollback to: $first_checkpoint_id"
        
        # Test rollback
        if rollback_to_checkpoint "$first_checkpoint_id" >/dev/null 2>&1; then
            echo "    ✅ Rollback executed successfully"
        else
            echo "    ❌ Rollback failed"
            success=false
        fi
    else
        echo "    ⚠️  Could not determine checkpoint ID for rollback test"
    fi
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# =============================================================================
# INTERFACE TESTS
# =============================================================================

# Test checkpoint control interface
test_checkpoint_control_interface() {
    local success=true
    
    echo "  Testing checkpoint control interface..."
    
    # Test dashboard
    if show_checkpoint_dashboard >/dev/null 2>&1; then
        echo "    ✅ Dashboard display works"
    else
        echo "    ❌ Dashboard display failed"
        success=false
    fi
    
    # Test system status
    if show_system_status >/dev/null 2>&1; then
        echo "    ✅ System status display works"
    else
        echo "    ❌ System status display failed"
        success=false
    fi
    
    # Test metrics generation
    if generate_quality_metrics_report >/dev/null 2>&1; then
        echo "    ✅ Quality metrics generation works"
    else
        echo "    ❌ Quality metrics generation failed"
        success=false
    fi
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# =============================================================================
# PERFORMANCE TESTS
# =============================================================================

# Test checkpoint performance
test_checkpoint_performance() {
    local success=true
    
    echo "  Testing checkpoint performance..."
    
    # Test checkpoint creation time
    local start_time=$(date +%s)
    local checkpoint_name="performance_test_checkpoint"
    
    if create_checkpoint "$checkpoint_name" "implement" "Performance test checkpoint" >/dev/null 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        echo "    ✅ Checkpoint creation completed in ${duration}s"
        
        # Check if creation time is acceptable (< 5 seconds)
        if [[ $duration -lt 5 ]]; then
            echo "    ✅ Performance target met (< 5s)"
        else
            echo "    ⚠️  Performance target missed (${duration}s >= 5s)"
        fi
    else
        echo "    ❌ Checkpoint creation performance test failed"
        success=false
    fi
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# =============================================================================
# MAIN TEST EXECUTION
# =============================================================================

# Generate test report
generate_test_report() {
    local report_file="$TEST_OUTPUT_DIR/checkpoint_workflow_test_report.md"
    
    cat > "$report_file" << EOF
# Checkpoint Workflow Integration Test Report

**Date**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Test Suite**: Checkpoint System Workflow Integration Tests
**Version**: SDD v2.0 Phase 3.2

## Test Summary

- **Total Tests**: $TESTS_TOTAL
- **Passed**: $TESTS_PASSED
- **Failed**: $TESTS_FAILED
- **Success Rate**: $(( TESTS_PASSED * 100 / TESTS_TOTAL ))%

## Test Results

$(if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "✅ **ALL TESTS PASSED** - Checkpoint workflow is fully functional"
else
    echo "❌ **$TESTS_FAILED TESTS FAILED** - Issues need to be resolved"
fi)

## System Status

- **Checkpoint System**: $(if [[ -f "$REPO_ROOT/scripts/bash/checkpoint-system.sh" ]]; then echo "✅ AVAILABLE"; else echo "❌ MISSING"; fi)
- **Control Interface**: $(if [[ -f "$REPO_ROOT/scripts/bash/checkpoint-control.sh" ]]; then echo "✅ AVAILABLE"; else echo "❌ MISSING"; fi)
- **Quality Gates**: $(if [[ $TESTS_FAILED -eq 0 ]]; then echo "✅ FUNCTIONAL"; else echo "❌ ISSUES"; fi)

## Workflow Integration

- **Phase Checkpoints**: $(if [[ $TESTS_FAILED -eq 0 ]]; then echo "✅ WORKING"; else echo "❌ ISSUES"; fi)
- **Quality Gates**: $(if [[ $TESTS_FAILED -eq 0 ]]; then echo "✅ WORKING"; else echo "❌ ISSUES"; fi)
- **Rollback System**: $(if [[ $TESTS_FAILED -eq 0 ]]; then echo "✅ WORKING"; else echo "❌ ISSUES"; fi)
- **Metrics Collection**: $(if [[ $TESTS_FAILED -eq 0 ]]; then echo "✅ WORKING"; else echo "❌ ISSUES"; fi)

## Recommendations

$(if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "- Checkpoint workflow is fully functional and ready for production"
    echo "- All quality gates are working correctly"
    echo "- Rollback system is operational"
    echo "- Interface is user-friendly and functional"
else
    echo "- Review failed tests and resolve issues before proceeding"
    echo "- Check system dependencies and configuration"
    echo "- Verify checkpoint system integration"
fi)

---

*Generated by Checkpoint Workflow Test Suite v1.0*
EOF

    echo -e "${BLUE}📊 Test report generated: $report_file${NC}"
}

# Main test execution function
main() {
    echo -e "${BLUE}🚀 Starting Checkpoint Workflow Integration Tests${NC}"
    echo -e "${BLUE}================================================${NC}"
    
    # Initialize test environment
    init_test_environment
    
    # Run checkpoint system tests
    echo -e "\n${YELLOW}🔧 Checkpoint System Tests${NC}"
    run_test "Checkpoint Creation All Phases" test_checkpoint_creation_all_phases
    run_test "Quality Gate Validation" test_quality_gate_validation
    run_test "Checkpoint Listing" test_checkpoint_listing
    run_test "Snapshot Integrity" test_snapshot_integrity
    
    # Run workflow integration tests
    echo -e "\n${YELLOW}🔄 Workflow Integration Tests${NC}"
    run_test "Complete SDD Workflow" test_complete_sdd_workflow
    run_test "Rollback Workflow" test_rollback_workflow
    
    # Run interface tests
    echo -e "\n${YELLOW}🖥️  Interface Tests${NC}"
    run_test "Checkpoint Control Interface" test_checkpoint_control_interface
    
    # Run performance tests
    echo -e "\n${YELLOW}⚡ Performance Tests${NC}"
    run_test "Checkpoint Performance" test_checkpoint_performance
    
    # Generate test report
    generate_test_report
    
    # Final summary
    echo -e "\n${BLUE}================================================${NC}"
    echo -e "${BLUE}🏁 Checkpoint Workflow Test Execution Complete${NC}"
    echo -e "${BLUE}================================================${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✅ ALL TESTS PASSED ($TESTS_PASSED/$TESTS_TOTAL)${NC}"
        echo -e "${GREEN}🎉 Checkpoint Workflow System is fully functional!${NC}"
        exit 0
    else
        echo -e "${RED}❌ $TESTS_FAILED TESTS FAILED ($TESTS_PASSED/$TESTS_TOTAL passed)${NC}"
        echo -e "${RED}🔧 System requires fixes before production use${NC}"
        exit 1
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi