#!/usr/bin/env bash
# Artifact Integration Tests
# Comprehensive test suite for the Artifact Generation System
# Part of SDD v2.0 Critical Systems Implementation - Phase 2.3

set -euo pipefail

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_OUTPUT_DIR="$REPO_ROOT/.specify-cache/test-results"
TEST_ARTIFACTS_DIR="$REPO_ROOT/.specify-cache/test-artifacts"

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
source "$REPO_ROOT/scripts/bash/artifact-generation.sh"

# =============================================================================
# TEST UTILITIES
# =============================================================================

# Initialize test environment
init_test_environment() {
    echo -e "${BLUE}🔧 Initializing test environment...${NC}"
    
    # Create test directories
    mkdir -p "$TEST_OUTPUT_DIR"
    mkdir -p "$TEST_ARTIFACTS_DIR"
    
    # Clean previous test results
    rm -rf "$TEST_OUTPUT_DIR"/*
    rm -rf "$TEST_ARTIFACTS_DIR"/*
    
    # Initialize test counters
    TESTS_TOTAL=0
    TESTS_PASSED=0
    TESTS_FAILED=0
    
    echo -e "${GREEN}✅ Test environment initialized${NC}"
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

# Assert file exists
assert_file_exists() {
    local file_path="$1"
    local description="${2:-File}"
    
    if [[ -f "$file_path" ]]; then
        echo "  ✅ $description exists: $file_path"
        return 0
    else
        echo "  ❌ $description missing: $file_path"
        return 1
    fi
}

# Assert directory exists
assert_directory_exists() {
    local dir_path="$1"
    local description="${2:-Directory}"
    
    if [[ -d "$dir_path" ]]; then
        echo "  ✅ $description exists: $dir_path"
        return 0
    else
        echo "  ❌ $description missing: $dir_path"
        return 1
    fi
}

# Assert content contains string
assert_content_contains() {
    local file_path="$1"
    local expected_content="$2"
    local description="${3:-Content check}"
    
    if [[ -f "$file_path" ]] && grep -q "$expected_content" "$file_path"; then
        echo "  ✅ $description: Found '$expected_content'"
        return 0
    else
        echo "  ❌ $description: Missing '$expected_content' in $file_path"
        return 1
    fi
}

# Assert JSON is valid
assert_valid_json() {
    local file_path="$1"
    local description="${2:-JSON validation}"
    
    if [[ -f "$file_path" ]] && command -v jq >/dev/null 2>&1 && jq empty "$file_path" 2>/dev/null; then
        echo "  ✅ $description: Valid JSON"
        return 0
    elif [[ -f "$file_path" ]] && python3 -m json.tool "$file_path" >/dev/null 2>&1; then
        echo "  ✅ $description: Valid JSON (via Python)"
        return 0
    else
        echo "  ❌ $description: Invalid JSON in $file_path"
        return 1
    fi
}

# =============================================================================
# INDIVIDUAL ARTIFACT GENERATION TESTS
# =============================================================================

# Test individual artifact generation for analyze phase
test_analyze_individual_artifacts() {
    local test_context="shared-principles"
    local phase="analyze"
    local success=true
    
    echo "  Testing individual artifact generation for $phase phase..."
    
    # Test each analyze template
    local templates=("architecture_assessment" "technical_debt_report" "compliance_check" "knowledge_base_references")
    
    for template_id in "${templates[@]}"; do
        echo "    Generating $template_id..."
        
        if generate_artifact "$template_id" "$phase" "$test_context" "$TEST_ARTIFACTS_DIR/$phase/${template_id}.test" >/dev/null 2>&1; then
            local output_file="$TEST_ARTIFACTS_DIR/$phase/${template_id}.test"
            
            # Verify file was created
            if ! assert_file_exists "$output_file" "$template_id artifact"; then
                success=false
            fi
            
            # Verify content is not empty
            if [[ -f "$output_file" ]] && [[ $(wc -c < "$output_file") -lt 100 ]]; then
                echo "    ❌ $template_id: Content too short"
                success=false
            else
                echo "    ✅ $template_id: Generated successfully"
            fi
            
            # Verify JSON files are valid JSON
            if [[ "$template_id" == *"compliance_check"* ]]; then
                if ! assert_valid_json "$output_file" "$template_id JSON"; then
                    success=false
                fi
            fi
        else
            echo "    ❌ $template_id: Generation failed"
            success=false
        fi
    done
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# Test individual artifact generation for architect phase
test_architect_individual_artifacts() {
    local test_context="shared-principles"
    local phase="architect"
    local success=true
    
    echo "  Testing individual artifact generation for $phase phase..."
    
    # Test each architect template
    local templates=("architecture_decision_record" "system_design_document" "component_interaction_diagram" "validation_report")
    
    for template_id in "${templates[@]}"; do
        echo "    Generating $template_id..."
        
        if generate_artifact "$template_id" "$phase" "$test_context" "$TEST_ARTIFACTS_DIR/$phase/${template_id}.test" >/dev/null 2>&1; then
            local output_file="$TEST_ARTIFACTS_DIR/$phase/${template_id}.test"
            
            # Verify file was created
            if ! assert_file_exists "$output_file" "$template_id artifact"; then
                success=false
            fi
            
            # Verify content is not empty
            if [[ -f "$output_file" ]] && [[ $(wc -c < "$output_file") -lt 100 ]]; then
                echo "    ❌ $template_id: Content too short"
                success=false
            else
                echo "    ✅ $template_id: Generated successfully"
            fi
            
            # Verify Mermaid files have proper format
            if [[ "$template_id" == *"component_interaction_diagram"* ]]; then
                if ! assert_content_contains "$output_file" "graph\|flowchart\|sequenceDiagram" "Mermaid diagram"; then
                    success=false
                fi
            fi
        else
            echo "    ❌ $template_id: Generation failed"
            success=false
        fi
    done
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# Test individual artifact generation for implement phase
test_implement_individual_artifacts() {
    local test_context="shared-principles"
    local phase="implement"
    local success=true
    
    echo "  Testing individual artifact generation for $phase phase..."
    
    # Test each implement template
    local templates=("code_quality_report" "test_coverage_report" "performance_benchmarks" "api_documentation")
    
    for template_id in "${templates[@]}"; do
        echo "    Generating $template_id..."
        
        if generate_artifact "$template_id" "$phase" "$test_context" "$TEST_ARTIFACTS_DIR/$phase/${template_id}.test" >/dev/null 2>&1; then
            local output_file="$TEST_ARTIFACTS_DIR/$phase/${template_id}.test"
            
            # Verify file was created
            if ! assert_file_exists "$output_file" "$template_id artifact"; then
                success=false
            fi
            
            # Verify content is not empty
            if [[ -f "$output_file" ]] && [[ $(wc -c < "$output_file") -lt 100 ]]; then
                echo "    ❌ $template_id: Content too short"
                success=false
            else
                echo "    ✅ $template_id: Generated successfully"
            fi
            
            # Verify JSON files are valid JSON
            if [[ "$template_id" == *"code_quality_report"* ]]; then
                if ! assert_valid_json "$output_file" "$template_id JSON"; then
                    success=false
                fi
            fi
            
            # Verify HTML files have basic HTML structure
            if [[ "$template_id" == *"test_coverage_report"* ]]; then
                if ! assert_content_contains "$output_file" "<html>\|<HTML>" "HTML structure"; then
                    success=false
                fi
            fi
        else
            echo "    ❌ $template_id: Generation failed"
            success=false
        fi
    done
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# Test individual artifact generation for checkpoints phase
test_checkpoints_individual_artifacts() {
    local test_context="shared-principles"
    local phase="checkpoints"
    local success=true
    
    echo "  Testing individual artifact generation for $phase phase..."
    
    # Test each checkpoints template
    local templates=("quality_gate_results" "compliance_audit" "rollback_snapshot" "checkpoint_summary")
    
    for template_id in "${templates[@]}"; do
        echo "    Generating $template_id..."
        
        if generate_artifact "$template_id" "$phase" "$test_context" "$TEST_ARTIFACTS_DIR/$phase/${template_id}.test" >/dev/null 2>&1; then
            local output_file="$TEST_ARTIFACTS_DIR/$phase/${template_id}.test"
            
            # Verify file was created
            if ! assert_file_exists "$output_file" "$template_id artifact"; then
                success=false
            fi
            
            # Verify content is not empty
            if [[ -f "$output_file" ]] && [[ $(wc -c < "$output_file") -lt 100 ]]; then
                echo "    ❌ $template_id: Content too short"
                success=false
            else
                echo "    ✅ $template_id: Generated successfully"
            fi
            
            # Verify JSON files are valid JSON
            if [[ "$template_id" == *"quality_gate_results"* ]] || [[ "$template_id" == *"rollback_snapshot"* ]]; then
                if ! assert_valid_json "$output_file" "$template_id JSON"; then
                    success=false
                fi
            fi
        else
            echo "    ❌ $template_id: Generation failed"
            success=false
        fi
    done
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# =============================================================================
# PHASE GENERATION TESTS
# =============================================================================

# Test complete phase artifact generation
test_phase_generation() {
    local test_context="shared-principles"
    local success=true
    
    echo "  Testing complete phase artifact generation..."
    
    # Test each phase
    local phases=("analyze" "architect" "implement" "checkpoints")
    
    for phase in "${phases[@]}"; do
        echo "    Generating all artifacts for $phase phase..."
        
        if generate_phase_artifacts "$phase" "$test_context" >/dev/null 2>&1; then
            echo "    ✅ $phase: Phase generation completed"
            
            # Verify artifacts directory was created
            if ! assert_directory_exists "$REPO_ROOT/artifacts/$phase" "$phase artifacts directory"; then
                success=false
            fi
            
            # Count generated artifacts
            local artifact_count=$(find "$REPO_ROOT/artifacts/$phase" -type f 2>/dev/null | wc -l)
            if [[ $artifact_count -ge 4 ]]; then
                echo "    ✅ $phase: Generated $artifact_count artifacts"
            else
                echo "    ❌ $phase: Only $artifact_count artifacts generated (expected 4+)"
                success=false
            fi
        else
            echo "    ❌ $phase: Phase generation failed"
            success=false
        fi
    done
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# =============================================================================
# KNOWLEDGE BASE INTEGRATION TESTS
# =============================================================================

# Test KB integration in artifacts
test_kb_integration() {
    local test_context="shared-principles"
    local phase="analyze"
    local template_id="architecture_assessment"
    local success=true
    
    echo "  Testing Knowledge Base integration..."
    
    # Generate artifact with KB integration
    local output_file="$TEST_ARTIFACTS_DIR/kb_test_${template_id}.md"
    
    if generate_artifact "$template_id" "$phase" "$test_context" "$output_file" >/dev/null 2>&1; then
        echo "    ✅ Artifact generated with KB integration"
        
        # Check for KB-related content
        if assert_content_contains "$output_file" "KB Context\|KB Reference\|Knowledge Base" "KB integration content"; then
            echo "    ✅ KB content found in artifact"
        else
            success=false
        fi
        
        # Check that KB placeholders were processed
        if grep -q "{KB_CONTEXT}\|{KB_REFERENCE}\|{VALIDATION_RESULT}" "$output_file"; then
            echo "    ❌ Unprocessed KB placeholders found"
            success=false
        else
            echo "    ✅ KB placeholders properly processed"
        fi
    else
        echo "    ❌ Artifact generation with KB integration failed"
        success=false
    fi
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# =============================================================================
# TRACEABILITY TESTS
# =============================================================================

# Test artifact traceability system
test_traceability_system() {
    local test_context="shared-principles"
    local phase="analyze"
    local template_id="architecture_assessment"
    local success=true
    
    echo "  Testing artifact traceability system..."
    
    # Generate artifact to create traceability entry
    local output_file="$TEST_ARTIFACTS_DIR/traceability_test_${template_id}.md"
    
    if generate_artifact "$template_id" "$phase" "$test_context" "$output_file" >/dev/null 2>&1; then
        echo "    ✅ Artifact generated for traceability test"
        
        # Check traceability file exists
        local traceability_file="$REPO_ROOT/.specify-cache/traceability/artifacts.json"
        if assert_file_exists "$traceability_file" "Traceability file"; then
            echo "    ✅ Traceability file exists"
            
            # Validate JSON structure
            if assert_valid_json "$traceability_file" "Traceability JSON"; then
                echo "    ✅ Traceability file is valid JSON"
                
                # Check for required fields
                if assert_content_contains "$traceability_file" "generation_id" "Generation ID field" &&
                   assert_content_contains "$traceability_file" "template_id" "Template ID field" &&
                   assert_content_contains "$traceability_file" "phase" "Phase field" &&
                   assert_content_contains "$traceability_file" "version" "Version field"; then
                    echo "    ✅ All required traceability fields present"
                else
                    success=false
                fi
            else
                success=false
            fi
        else
            success=false
        fi
    else
        echo "    ❌ Artifact generation for traceability test failed"
        success=false
    fi
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# =============================================================================
# VERSIONING TESTS
# =============================================================================

# Test artifact versioning system
test_versioning_system() {
    local test_context="shared-principles"
    local phase="analyze"
    local template_id="architecture_assessment"
    local success=true
    
    echo "  Testing artifact versioning system..."
    
    # Generate multiple versions of the same artifact
    local output_file1="$TEST_ARTIFACTS_DIR/version_test1_${template_id}.md"
    local output_file2="$TEST_ARTIFACTS_DIR/version_test2_${template_id}.md"
    
    # Generate first version
    if generate_artifact "$template_id" "$phase" "$test_context" "$output_file1" >/dev/null 2>&1; then
        echo "    ✅ First version generated"
        
        # Wait a moment to ensure different timestamps
        sleep 1
        
        # Generate second version
        if generate_artifact "$template_id" "$phase" "$test_context" "$output_file2" >/dev/null 2>&1; then
            echo "    ✅ Second version generated"
            
            # Check that both files exist and have different content (due to timestamps)
            if [[ -f "$output_file1" ]] && [[ -f "$output_file2" ]]; then
                local hash1=$(sha256sum "$output_file1" | cut -d' ' -f1)
                local hash2=$(sha256sum "$output_file2" | cut -d' ' -f1)
                
                if [[ "$hash1" != "$hash2" ]]; then
                    echo "    ✅ Versions have different content (proper versioning)"
                else
                    echo "    ⚠️  Versions have identical content (may be expected)"
                fi
                
                # Check for version information in content
                if assert_content_contains "$output_file1" "v1.0\|version" "Version information"; then
                    echo "    ✅ Version information found in artifacts"
                else
                    success=false
                fi
            else
                echo "    ❌ Version files not created properly"
                success=false
            fi
        else
            echo "    ❌ Second version generation failed"
            success=false
        fi
    else
        echo "    ❌ First version generation failed"
        success=false
    fi
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# =============================================================================
# TEMPLATE VALIDATION TESTS
# =============================================================================

# Test template listing functionality
test_template_listing() {
    local success=true
    
    echo "  Testing template listing functionality..."
    
    # Test each phase
    local phases=("analyze" "architect" "implement" "checkpoints")
    
    for phase in "${phases[@]}"; do
        echo "    Testing template listing for $phase..."
        
        if templates=$(get_phase_templates "$phase" 2>/dev/null); then
            local template_count=$(echo "$templates" | wc -l)
            
            if [[ $template_count -ge 4 ]]; then
                echo "    ✅ $phase: Found $template_count templates"
            else
                echo "    ❌ $phase: Only found $template_count templates (expected 4+)"
                success=false
            fi
        else
            echo "    ❌ $phase: Template listing failed"
            success=false
        fi
    done
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# Test template resolution
test_template_resolution() {
    local success=true
    
    echo "  Testing template resolution..."
    
    # Test template resolution for each phase
    local test_cases=(
        "analyze:architecture_assessment"
        "architect:system_design_document"
        "implement:code_quality_report"
        "checkpoints:quality_gate_results"
    )
    
    for test_case in "${test_cases[@]}"; do
        local phase=$(echo "$test_case" | cut -d':' -f1)
        local template_id=$(echo "$test_case" | cut -d':' -f2)
        
        echo "    Testing resolution: $phase/$template_id"
        
        if template_path=$(resolve_template_path "$template_id" "$phase" 2>/dev/null); then
            if assert_file_exists "$template_path" "Template file"; then
                echo "    ✅ $phase/$template_id: Resolved to $template_path"
            else
                success=false
            fi
        else
            echo "    ❌ $phase/$template_id: Resolution failed"
            success=false
        fi
    done
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# =============================================================================
# VALIDATION TESTS
# =============================================================================

# Test artifact validation system
test_artifact_validation() {
    local test_context="shared-principles"
    local phase="analyze"
    local success=true
    
    echo "  Testing artifact validation system..."
    
    # Create test content for validation
    local test_content="# Test Architecture Assessment

## Architecture Overview
This is a test architecture assessment with KB integration.

## KB Context
KB Context: Available

## Technical Debt Analysis
Technical debt has been analyzed according to KB patterns.

## Compliance Check
Compliance validated against shared principles."
    
    # Test validation function
    if validation_result=$(validate_artifact_content "$test_content" "$test_context" "$phase" 2>/dev/null); then
        echo "    ✅ Validation function executed successfully"
        
        # Check validation result format
        if echo "$validation_result" | grep -q "VALIDATION SUMMARY"; then
            echo "    ✅ Validation result has proper format"
            
            # Check for validation status
            if echo "$validation_result" | grep -q "PASS\|FAIL\|PARTIAL"; then
                echo "    ✅ Validation status determined"
            else
                echo "    ❌ Validation status not found"
                success=false
            fi
        else
            echo "    ❌ Validation result format incorrect"
            success=false
        fi
    else
        echo "    ❌ Validation function failed"
        success=false
    fi
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# =============================================================================
# PERFORMANCE TESTS
# =============================================================================

# Test generation performance
test_generation_performance() {
    local test_context="shared-principles"
    local phase="analyze"
    local template_id="architecture_assessment"
    local success=true
    
    echo "  Testing generation performance..."
    
    # Measure single artifact generation time
    local start_time=$(date +%s)
    local output_file="$TEST_ARTIFACTS_DIR/performance_test_${template_id}.md"
    
    if generate_artifact "$template_id" "$phase" "$test_context" "$output_file" >/dev/null 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        echo "    ✅ Single artifact generation completed in ${duration}s"
        
        # Check if generation time is acceptable (< 10 seconds)
        if [[ $duration -lt 10 ]]; then
            echo "    ✅ Performance target met (< 10s)"
        else
            echo "    ⚠️  Performance target missed (${duration}s >= 10s)"
        fi
        
        # Measure phase generation time
        start_time=$(date +%s)
        
        if generate_phase_artifacts "$phase" "$test_context" >/dev/null 2>&1; then
            end_time=$(date +%s)
            duration=$((end_time - start_time))
            
            echo "    ✅ Phase generation completed in ${duration}s"
            
            # Check if phase generation time is acceptable (< 30 seconds)
            if [[ $duration -lt 30 ]]; then
                echo "    ✅ Phase performance target met (< 30s)"
            else
                echo "    ⚠️  Phase performance target missed (${duration}s >= 30s)"
            fi
        else
            echo "    ❌ Phase generation performance test failed"
            success=false
        fi
    else
        echo "    ❌ Single artifact generation performance test failed"
        success=false
    fi
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# =============================================================================
# INTEGRATION WORKFLOW TESTS
# =============================================================================

# Test complete workflow integration
test_complete_workflow() {
    local test_context="shared-principles"
    local success=true
    
    echo "  Testing complete workflow integration..."
    
    # Test complete workflow: all phases in sequence
    local phases=("analyze" "architect" "implement" "checkpoints")
    
    for phase in "${phases[@]}"; do
        echo "    Executing workflow step: $phase"
        
        if generate_phase_artifacts "$phase" "$test_context" >/dev/null 2>&1; then
            echo "    ✅ $phase: Workflow step completed"
            
            # Verify artifacts were created
            local artifact_count=$(find "$REPO_ROOT/artifacts/$phase" -type f 2>/dev/null | wc -l)
            if [[ $artifact_count -ge 4 ]]; then
                echo "    ✅ $phase: $artifact_count artifacts generated"
            else
                echo "    ❌ $phase: Insufficient artifacts ($artifact_count < 4)"
                success=false
            fi
        else
            echo "    ❌ $phase: Workflow step failed"
            success=false
        fi
    done
    
    # Verify complete artifact structure
    if assert_directory_exists "$REPO_ROOT/artifacts" "Main artifacts directory" &&
       assert_directory_exists "$REPO_ROOT/artifacts/analyze" "Analyze artifacts" &&
       assert_directory_exists "$REPO_ROOT/artifacts/architect" "Architect artifacts" &&
       assert_directory_exists "$REPO_ROOT/artifacts/implement" "Implement artifacts" &&
       assert_directory_exists "$REPO_ROOT/artifacts/checkpoints" "Checkpoint artifacts"; then
        echo "    ✅ Complete artifact structure verified"
    else
        success=false
    fi
    
    return $([ "$success" = true ] && echo 0 || echo 1)
}

# =============================================================================
# MAIN TEST EXECUTION
# =============================================================================

# Generate test report
generate_test_report() {
    local report_file="$TEST_OUTPUT_DIR/integration_test_report.md"
    
    cat > "$report_file" << EOF
# Artifact Integration Test Report

**Date**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Test Suite**: Artifact Generation System Integration Tests
**Version**: SDD v2.0 Phase 2.3

## Test Summary

- **Total Tests**: $TESTS_TOTAL
- **Passed**: $TESTS_PASSED
- **Failed**: $TESTS_FAILED
- **Success Rate**: $(( TESTS_PASSED * 100 / TESTS_TOTAL ))%

## Test Results

$(if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "✅ **ALL TESTS PASSED** - System is ready for production"
else
    echo "❌ **$TESTS_FAILED TESTS FAILED** - Issues need to be resolved"
fi)

## Test Environment

- **Repository Root**: $REPO_ROOT
- **Test Output**: $TEST_OUTPUT_DIR
- **Test Artifacts**: $TEST_ARTIFACTS_DIR

## Artifacts Generated During Testing

$(find "$TEST_ARTIFACTS_DIR" -type f 2>/dev/null | wc -l) test artifacts generated

## Recommendations

$(if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "- System is fully functional and ready for Phase 2.3 completion"
    echo "- All artifact generation workflows are operational"
    echo "- KB integration is working correctly"
    echo "- Traceability system is functional"
else
    echo "- Review failed tests and resolve issues before proceeding"
    echo "- Check system dependencies and configuration"
    echo "- Verify template files and KB integration"
fi)

---

*Generated by Artifact Integration Test Suite v1.0*
EOF

    echo -e "${BLUE}📊 Test report generated: $report_file${NC}"
}

# Main test execution function
main() {
    echo -e "${BLUE}🚀 Starting Artifact Integration Tests${NC}"
    echo -e "${BLUE}======================================${NC}"
    
    # Initialize test environment
    init_test_environment
    
    # Run individual artifact generation tests
    echo -e "\n${YELLOW}📋 Individual Artifact Generation Tests${NC}"
    run_test "Analyze Individual Artifacts" test_analyze_individual_artifacts
    run_test "Architect Individual Artifacts" test_architect_individual_artifacts
    run_test "Implement Individual Artifacts" test_implement_individual_artifacts
    run_test "Checkpoints Individual Artifacts" test_checkpoints_individual_artifacts
    
    # Run phase generation tests
    echo -e "\n${YELLOW}🔄 Phase Generation Tests${NC}"
    run_test "Complete Phase Generation" test_phase_generation
    
    # Run KB integration tests
    echo -e "\n${YELLOW}🧠 Knowledge Base Integration Tests${NC}"
    run_test "KB Integration" test_kb_integration
    
    # Run traceability tests
    echo -e "\n${YELLOW}📊 Traceability Tests${NC}"
    run_test "Traceability System" test_traceability_system
    
    # Run versioning tests
    echo -e "\n${YELLOW}🏷️  Versioning Tests${NC}"
    run_test "Versioning System" test_versioning_system
    
    # Run template validation tests
    echo -e "\n${YELLOW}📝 Template Validation Tests${NC}"
    run_test "Template Listing" test_template_listing
    run_test "Template Resolution" test_template_resolution
    
    # Run validation tests
    echo -e "\n${YELLOW}✅ Validation Tests${NC}"
    run_test "Artifact Validation" test_artifact_validation
    
    # Run performance tests
    echo -e "\n${YELLOW}⚡ Performance Tests${NC}"
    run_test "Generation Performance" test_generation_performance
    
    # Run complete workflow tests
    echo -e "\n${YELLOW}🔗 Workflow Integration Tests${NC}"
    run_test "Complete Workflow" test_complete_workflow
    
    # Generate test report
    generate_test_report
    
    # Final summary
    echo -e "\n${BLUE}======================================${NC}"
    echo -e "${BLUE}🏁 Test Execution Complete${NC}"
    echo -e "${BLUE}======================================${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✅ ALL TESTS PASSED ($TESTS_PASSED/$TESTS_TOTAL)${NC}"
        echo -e "${GREEN}🎉 Artifact Generation System is fully functional!${NC}"
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