#!/usr/bin/env bash
# Test script for plan.md Knowledge Base integration
# Tests dynamic directory structure generation and KB integration

set -e

# Get script directory and source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source the KB integration module
source "$PROJECT_ROOT/scripts/bash/knowledge-base-integration.sh"

# Test colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    echo -e "${BLUE}Running test: $test_name${NC}"
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if $test_function; then
        echo -e "${GREEN}✅ PASS: $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL: $test_name${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo
}

assert_contains() {
    local output="$1"
    local expected="$2"
    local test_description="$3"
    
    if echo "$output" | grep -q "$expected"; then
        return 0
    else
        echo -e "${RED}Expected '$expected' in output for: $test_description${NC}"
        echo -e "${YELLOW}Actual output:${NC}"
        echo "$output"
        return 1
    fi
}

assert_not_empty() {
    local output="$1"
    local test_description="$2"
    
    if [[ -n "$output" ]]; then
        return 0
    else
        echo -e "${RED}Expected non-empty output for: $test_description${NC}"
        return 1
    fi
}

# =============================================================================
# TEST FUNCTIONS
# =============================================================================

test_kb_status() {
    local output
    output=$(kb_status 2>&1)
    
    assert_contains "$output" "Knowledge Base Integration Status" "KB status header" &&
    assert_contains "$output" "KB Root:" "KB root path" &&
    assert_contains "$output" "Available Contexts:" "Available contexts section"
}

test_directory_structure_nextjs() {
    local output
    output=$(get_directory_structure "next.js" "clean-architecture")
    
    assert_contains "$output" "Next.js + Clean Architecture Structure" "Next.js structure header" &&
    assert_contains "$output" "app/" "Next.js app directory" &&
    assert_contains "$output" "src/" "Source directory" &&
    assert_contains "$output" "components/" "Components directory"
}

test_directory_structure_nextjs_ddd() {
    local output
    output=$(get_directory_structure "next.js" "ddd")
    
    assert_contains "$output" "Next.js + Clean Architecture + DDD Structure" "Next.js DDD structure header" &&
    assert_contains "$output" "application/" "Application layer" &&
    assert_contains "$output" "domain/" "Domain layer" &&
    assert_contains "$output" "infrastructure/" "Infrastructure layer"
}

test_directory_structure_react() {
    local output
    output=$(get_directory_structure "react" "clean-architecture")
    
    assert_contains "$output" "React + Clean Architecture Structure" "React structure header" &&
    assert_contains "$output" "src/" "Source directory" &&
    assert_contains "$output" "components/" "Components directory" &&
    assert_contains "$output" "services/" "Services directory"
}

test_directory_structure_backend() {
    local output
    output=$(get_directory_structure "backend" "clean-architecture")
    
    assert_contains "$output" "Backend + Clean Architecture Structure" "Backend structure header" &&
    assert_contains "$output" "src/" "Source directory" &&
    assert_contains "$output" "controllers/" "Controllers directory" &&
    assert_contains "$output" "services/" "Services directory"
}

test_directory_structure_backend_ddd() {
    local output
    output=$(get_directory_structure "backend" "ddd")
    
    assert_contains "$output" "Backend + Clean Architecture + DDD Structure" "Backend DDD structure header" &&
    assert_contains "$output" "application/" "Application layer" &&
    assert_contains "$output" "domain/" "Domain layer" &&
    assert_contains "$output" "entities/" "Domain entities"
}

test_directory_structure_fullstack() {
    local output
    output=$(get_directory_structure "web fullstack" "clean-architecture")
    
    assert_contains "$output" "Fullstack + Clean Architecture Structure" "Fullstack structure header" &&
    assert_contains "$output" "backend/" "Backend directory" &&
    assert_contains "$output" "frontend/" "Frontend directory" &&
    assert_contains "$output" "shared/" "Shared directory"
}

test_directory_structure_mobile() {
    local output
    output=$(get_directory_structure "mobile" "clean-architecture")
    
    assert_contains "$output" "Mobile + API Structure" "Mobile structure header" &&
    assert_contains "$output" "api/" "API directory" &&
    assert_contains "$output" "mobile/" "Mobile directory" &&
    assert_contains "$output" "screens/" "Screens directory"
}

test_detect_architecture_pattern_ddd() {
    local output
    output=$(detect_architecture_pattern "domain driven design with bounded contexts")
    
    assert_contains "$output" "ddd" "DDD pattern detection"
}

test_detect_architecture_pattern_clean() {
    local output
    output=$(detect_architecture_pattern "clean architecture with layers")
    
    assert_contains "$output" "clean-architecture" "Clean architecture pattern detection"
}

test_structure_decision_nextjs() {
    local output
    output=$(generate_structure_decision "Next.js frontend with TypeScript")
    
    assert_contains "$output" "Structure Decision" "Structure decision header" &&
    assert_contains "$output" "KB Justification" "KB justification section" &&
    assert_contains "$output" "Applied KB Patterns" "Applied patterns section" &&
    assert_contains "$output" "Next.js detected" "Next.js detection"
}

test_structure_decision_fullstack() {
    local output
    output=$(generate_structure_decision "web application with frontend and backend")
    
    assert_contains "$output" "Option 2 - web application" "Web application detection" &&
    assert_contains "$output" "frontend/ui-architecture" "Frontend patterns" &&
    assert_contains "$output" "backend/domain-modeling" "Backend patterns"
}

test_get_applicable_principles_plan() {
    local output
    output=$(get_applicable_principles "plan")
    
    assert_not_empty "$output" "Plan principles output" &&
    assert_contains "$output" "shared-principles" "Shared principles included"
}

test_kb_placeholders_initialization() {
    init_kb_placeholders "plan"
    
    [[ -n "$KB_CONTEXT" ]] && [[ -n "$KB_REFERENCE" ]] && [[ -n "$VALIDATION_RESULT" ]]
}

test_fallback_guidance() {
    local output
    output=$(fallback_to_basic_guidance "shared-principles")
    
    assert_contains "$output" "Basic Software Engineering Principles" "Fallback guidance header" &&
    assert_contains "$output" "SOLID principles" "SOLID principles mentioned"
}

# =============================================================================
# INTEGRATION TESTS
# =============================================================================

test_plan_template_placeholders() {
    local template_file="$PROJECT_ROOT/templates/plan-template.md"
    
    [[ -f "$template_file" ]] &&
    grep -q "{DYNAMIC_STRUCTURE}" "$template_file" &&
    grep -q "{STRUCTURE_DECISION}" "$template_file" &&
    grep -q "KB-Enhanced Structure Generation" "$template_file"
}

test_plan_command_kb_integration() {
    local command_file="$PROJECT_ROOT/templates/commands/plan.md"
    
    [[ -f "$command_file" ]] &&
    grep -q "Knowledge Base Integration for Planning" "$command_file" &&
    grep -q "source scripts/bash/knowledge-base-integration.sh" "$command_file" &&
    grep -q "get_applicable_principles" "$command_file"
}

# =============================================================================
# RUN ALL TESTS
# =============================================================================

main() {
    echo -e "${BLUE}=== Plan KB Integration Test Suite ===${NC}"
    echo -e "${BLUE}Testing dynamic directory structure generation and KB integration${NC}"
    echo

    # Basic KB functionality tests
    run_test "KB Status Check" test_kb_status
    run_test "KB Placeholders Initialization" test_kb_placeholders_initialization
    run_test "Fallback Guidance" test_fallback_guidance

    # Directory structure generation tests
    run_test "Next.js Structure Generation" test_directory_structure_nextjs
    run_test "Next.js + DDD Structure Generation" test_directory_structure_nextjs_ddd
    run_test "React Structure Generation" test_directory_structure_react
    run_test "Backend Structure Generation" test_directory_structure_backend
    run_test "Backend + DDD Structure Generation" test_directory_structure_backend_ddd
    run_test "Fullstack Structure Generation" test_directory_structure_fullstack
    run_test "Mobile Structure Generation" test_directory_structure_mobile

    # Architecture pattern detection tests
    run_test "DDD Pattern Detection" test_detect_architecture_pattern_ddd
    run_test "Clean Architecture Pattern Detection" test_detect_architecture_pattern_clean

    # Structure decision generation tests
    run_test "Next.js Structure Decision" test_structure_decision_nextjs
    run_test "Fullstack Structure Decision" test_structure_decision_fullstack

    # KB integration tests
    run_test "Plan Applicable Principles" test_get_applicable_principles_plan

    # Template integration tests
    run_test "Plan Template Placeholders" test_plan_template_placeholders
    run_test "Plan Command KB Integration" test_plan_command_kb_integration

    # Summary
    echo -e "${BLUE}=== Test Results ===${NC}"
    echo -e "Tests Run: $TESTS_RUN"
    echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
        echo -e "${RED}❌ Some tests failed${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ All tests passed!${NC}"
        echo -e "${GREEN}Plan KB integration is working correctly${NC}"
        exit 0
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi