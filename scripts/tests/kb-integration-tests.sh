#!/usr/bin/env bash
# Knowledge Base Integration Module - Unit Tests
# Tests for KB query, validation, and compliance functions

# Source the KB integration module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bash/knowledge-base-integration.sh"

# Test configuration
TEST_RESULTS=()
TESTS_PASSED=0
TESTS_FAILED=0
TEMP_DIR="/tmp/kb-integration-tests-$$"

# =============================================================================
# TEST UTILITIES
# =============================================================================

# Setup test environment
setup_tests() {
    echo "=== Setting up KB Integration Tests ==="
    
    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    
    # Create mock KB structure
    mkdir -p "$TEMP_DIR/memory/knowledge-base/shared-principles"
    mkdir -p "$TEMP_DIR/memory/knowledge-base/frontend"
    mkdir -p "$TEMP_DIR/memory/knowledge-base/backend"
    mkdir -p "$TEMP_DIR/memory/knowledge-base/devops-sre"
    
    # Create mock KB content
    cat > "$TEMP_DIR/memory/knowledge-base/shared-principles/clean-code.md" << 'EOF'
# Clean Code Principles

## Naming Conventions
- Use descriptive names for variables and functions
- Avoid single letter variables except for loop counters
- Use consistent naming patterns

## Functions
- Keep functions small and focused
- Functions should do one thing well
- Use descriptive function names
EOF
    
    cat > "$TEMP_DIR/memory/knowledge-base/frontend/component-design.md" << 'EOF'
# Component Design Patterns

## React Components
- Keep components small and focused
- Use composition over inheritance
- Implement proper prop validation

## State Management
- Use local state when possible
- Lift state up when needed by multiple components
EOF
    
    # Create test artifacts
    cat > "$TEMP_DIR/test-component.tsx" << 'EOF'
import React from 'react';

const TestComponent = () => {
  const [count, setCount] = useState(0);
  
  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(count + 1)}>Increment</button>
    </div>
  );
};

export default TestComponent;
EOF
    
    cat > "$TEMP_DIR/test-large-file.js" << 'EOF'
// This is a mock large file for testing
$(for i in {1..600}; do echo "console.log('Line $i');"; done)
EOF
    
    echo "✅ Test environment setup complete"
}

# Cleanup test environment
cleanup_tests() {
    echo "=== Cleaning up KB Integration Tests ==="
    rm -rf "$TEMP_DIR"
    echo "✅ Test cleanup complete"
}

# Test assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    if [[ "$expected" == "$actual" ]]; then
        echo "✅ PASS: $test_name"
        TEST_RESULTS+=("PASS: $test_name")
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ FAIL: $test_name"
        echo "   Expected: $expected"
        echo "   Actual: $actual"
        TEST_RESULTS+=("FAIL: $test_name")
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_contains() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    if echo "$actual" | grep -q "$expected"; then
        echo "✅ PASS: $test_name"
        TEST_RESULTS+=("PASS: $test_name")
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ FAIL: $test_name"
        echo "   Expected to contain: $expected"
        echo "   Actual: $actual"
        TEST_RESULTS+=("FAIL: $test_name")
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_not_empty() {
    local actual="$1"
    local test_name="$2"
    
    if [[ -n "$actual" ]]; then
        echo "✅ PASS: $test_name"
        TEST_RESULTS+=("PASS: $test_name")
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ FAIL: $test_name"
        echo "   Expected non-empty result"
        TEST_RESULTS+=("FAIL: $test_name")
        ((TESTS_FAILED++))
        return 1
    fi
}

# =============================================================================
# UNIT TESTS
# =============================================================================

# Test KB context validation
test_validate_kb_context() {
    echo "--- Testing KB Context Validation ---"
    
    # Test valid contexts
    validate_kb_context "shared-principles"
    assert_equals "0" "$?" "Valid context: shared-principles"
    
    validate_kb_context "frontend"
    assert_equals "0" "$?" "Valid context: frontend"
    
    validate_kb_context "backend"
    assert_equals "0" "$?" "Valid context: backend"
    
    validate_kb_context "devops-sre"
    assert_equals "0" "$?" "Valid context: devops-sre"
    
    # Test invalid context
    validate_kb_context "invalid-context"
    assert_equals "1" "$?" "Invalid context should fail"
}

# Test cache key generation
test_cache_key_generation() {
    echo "--- Testing Cache Key Generation ---"
    
    local key1=$(generate_cache_key "shared-principles" "clean code")
    local key2=$(generate_cache_key "shared-principles" "clean code")
    local key3=$(generate_cache_key "frontend" "clean code")
    
    assert_equals "$key1" "$key2" "Same input should generate same key"
    
    if [[ "$key1" != "$key3" ]]; then
        echo "✅ PASS: Different input generates different key"
        TEST_RESULTS+=("PASS: Different input generates different key")
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL: Different input should generate different key"
        TEST_RESULTS+=("FAIL: Different input should generate different key")
        ((TESTS_FAILED++))
    fi
    
    # Test key format (should be 64 character hex)
    if [[ ${#key1} -eq 64 && "$key1" =~ ^[a-f0-9]+$ ]]; then
        echo "✅ PASS: Cache key format is correct"
        TEST_RESULTS+=("PASS: Cache key format is correct")
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL: Cache key format is incorrect"
        TEST_RESULTS+=("FAIL: Cache key format is incorrect")
        ((TESTS_FAILED++))
    fi
}

# Test project context detection
test_project_context_detection() {
    echo "--- Testing Project Context Detection ---"
    
    # Mock repo root for testing
    local original_get_repo_root=$(declare -f get_repo_root)
    get_repo_root() { echo "$TEMP_DIR"; }
    
    # Create test files for context detection
    touch "$TEMP_DIR/package.json"
    touch "$TEMP_DIR/component.tsx"
    touch "$TEMP_DIR/Dockerfile"
    
    local contexts=$(detect_project_contexts)
    
    assert_contains "frontend" "$contexts" "Frontend context detected"
    assert_contains "devops-sre" "$contexts" "DevOps context detected"
    
    # Restore original function
    eval "$original_get_repo_root"
}

# Test KB query execution
test_kb_query_execution() {
    echo "--- Testing KB Query Execution ---"
    
    # Mock repo root for testing
    local original_get_repo_root=$(declare -f get_repo_root)
    get_repo_root() { echo "$TEMP_DIR"; }
    
    # Test successful query
    local result=$(execute_kb_query "$TEMP_DIR/memory/knowledge-base/shared-principles" "naming")
    assert_contains "naming" "$result" "KB query returns relevant content"
    
    # Test query with no results
    local empty_result=$(execute_kb_query "$TEMP_DIR/memory/knowledge-base/shared-principles" "nonexistent")
    assert_contains "No specific guidance found" "$empty_result" "KB query handles no results"
    
    # Test invalid directory
    local invalid_result=$(execute_kb_query "/nonexistent/path" "test")
    assert_equals "" "$invalid_result" "KB query handles invalid directory"
    
    # Restore original function
    eval "$original_get_repo_root"
}

# Test fallback guidance
test_fallback_guidance() {
    echo "--- Testing Fallback Guidance ---"
    
    local shared_fallback=$(fallback_to_basic_guidance "shared-principles")
    assert_contains "SOLID principles" "$shared_fallback" "Shared principles fallback"
    
    local frontend_fallback=$(fallback_to_basic_guidance "frontend")
    assert_contains "component reusability" "$frontend_fallback" "Frontend fallback"
    
    local backend_fallback=$(fallback_to_basic_guidance "backend")
    assert_contains "domain-driven design" "$backend_fallback" "Backend fallback"
    
    local devops_fallback=$(fallback_to_basic_guidance "devops-sre")
    assert_contains "Infrastructure as Code" "$devops_fallback" "DevOps fallback"
    
    local default_fallback=$(fallback_to_basic_guidance "unknown")
    assert_not_empty "$default_fallback" "Default fallback"
}

# Test pattern validation
test_pattern_validation() {
    echo "--- Testing Pattern Validation ---"
    
    # Test naming conventions validation
    local naming_result=$(validate_naming_conventions "$TEMP_DIR/test-component.tsx")
    assert_contains "PASS\|SKIP" "$naming_result" "Naming validation executes"
    
    # Test SOLID principles validation
    local solid_result=$(validate_solid_principles "$TEMP_DIR/test-large-file.js")
    assert_contains "WARN.*Large file" "$solid_result" "SOLID validation detects large files"
    
    # Test component design validation
    local component_result=$(validate_component_design "$TEMP_DIR/test-component.tsx")
    assert_contains "PASS" "$component_result" "Component validation passes for small component"
}

# Test cache operations
test_cache_operations() {
    echo "--- Testing Cache Operations ---"
    
    # Mock repo root for testing
    local original_get_repo_root=$(declare -f get_repo_root)
    get_repo_root() { echo "$TEMP_DIR"; }
    
    local test_key="test_cache_key"
    local test_result="test cache result"
    
    # Test cache storage
    cache_kb_result "$test_key" "$test_result"
    
    # Test cache retrieval
    local cached_result=$(get_cached_kb_result "$test_key")
    assert_equals "$test_result" "$cached_result" "Cache stores and retrieves correctly"
    
    # Test cache expiry (simulate old file)
    local cache_file="$TEMP_DIR/.specify-cache/kb-queries/$test_key.json"
    if [[ -f "$cache_file" ]]; then
        # Set file timestamp to 25 hours ago (beyond TTL)
        touch -d "25 hours ago" "$cache_file"
        local expired_result=$(get_cached_kb_result "$test_key")
        assert_equals "" "$expired_result" "Expired cache returns empty"
    fi
    
    # Restore original function
    eval "$original_get_repo_root"
}

# Test query_knowledge_base function
test_query_knowledge_base() {
    echo "--- Testing query_knowledge_base Function ---"
    
    # Mock repo root for testing
    local original_get_repo_root=$(declare -f get_repo_root)
    get_repo_root() { echo "$TEMP_DIR"; }
    
    # Test valid query
    local result=$(query_knowledge_base "shared-principles" "naming")
    assert_not_empty "$result" "Query returns result"
    
    # Test invalid context
    local invalid_result=$(query_knowledge_base "invalid" "test" 2>/dev/null)
    assert_equals "" "$invalid_result" "Invalid context returns empty"
    
    # Test missing parameters
    local missing_result=$(query_knowledge_base "" "" 2>/dev/null)
    assert_equals "" "$missing_result" "Missing parameters return empty"
    
    # Restore original function
    eval "$original_get_repo_root"
}

# Test validate_against_patterns function
test_validate_against_patterns() {
    echo "--- Testing validate_against_patterns Function ---"
    
    # Test valid validation
    local result=$(validate_against_patterns "$TEMP_DIR/test-component.tsx" "frontend")
    assert_contains "VALIDATION SUMMARY" "$result" "Validation returns summary"
    
    # Test non-existent file
    local invalid_result=$(validate_against_patterns "/nonexistent/file.js" "frontend" 2>/dev/null)
    assert_equals "" "$invalid_result" "Non-existent file returns empty"
    
    # Test invalid context
    local context_result=$(validate_against_patterns "$TEMP_DIR/test-component.tsx" "invalid" 2>/dev/null)
    assert_equals "" "$context_result" "Invalid context returns empty"
}

# Test get_applicable_principles function
test_get_applicable_principles() {
    echo "--- Testing get_applicable_principles Function ---"
    
    # Mock repo root for testing
    local original_get_repo_root=$(declare -f get_repo_root)
    get_repo_root() { echo "$TEMP_DIR"; }
    
    # Create test files for context detection
    touch "$TEMP_DIR/package.json"
    
    local result=$(get_applicable_principles "analyze")
    assert_contains "shared-principles" "$result" "Always includes shared principles"
    
    local architect_result=$(get_applicable_principles "architect")
    assert_not_empty "$architect_result" "Architect phase returns principles"
    
    local implement_result=$(get_applicable_principles "implement")
    assert_not_empty "$implement_result" "Implement phase returns principles"
    
    # Restore original function
    eval "$original_get_repo_root"
}

# Test generate_compliance_report function
test_generate_compliance_report() {
    echo "--- Testing generate_compliance_report Function ---"
    
    # Mock repo root for testing
    local original_get_repo_root=$(declare -f get_repo_root)
    get_repo_root() { echo "$TEMP_DIR"; }
    
    local report_file=$(generate_compliance_report "analyze")
    
    # Check if report file was created
    if [[ -f "$report_file" ]]; then
        echo "✅ PASS: Compliance report file created"
        TEST_RESULTS+=("PASS: Compliance report file created")
        ((TESTS_PASSED++))
        
        # Check report content
        local content=$(cat "$report_file")
        assert_contains "Compliance Report - analyze Phase" "$content" "Report contains correct title"
        assert_contains "Generated:" "$content" "Report contains timestamp"
        assert_contains "Knowledge Base Integration Module" "$content" "Report contains module info"
    else
        echo "❌ FAIL: Compliance report file not created"
        TEST_RESULTS+=("FAIL: Compliance report file not created")
        ((TESTS_FAILED++))
    fi
    
    # Restore original function
    eval "$original_get_repo_root"
}

# =============================================================================
# INTEGRATION TESTS
# =============================================================================

# Test end-to-end workflow
test_e2e_workflow() {
    echo "--- Testing End-to-End Workflow ---"
    
    # Mock repo root for testing
    local original_get_repo_root=$(declare -f get_repo_root)
    get_repo_root() { echo "$TEMP_DIR"; }
    
    # Create test project structure
    touch "$TEMP_DIR/package.json"
    
    # Test complete workflow
    local principles=$(get_applicable_principles "analyze")
    assert_not_empty "$principles" "E2E: Get applicable principles"
    
    local query_result=$(query_knowledge_base "shared-principles" "clean code")
    assert_not_empty "$query_result" "E2E: Query knowledge base"
    
    local validation_result=$(validate_against_patterns "$TEMP_DIR/test-component.tsx" "frontend")
    assert_contains "VALIDATION SUMMARY" "$validation_result" "E2E: Validate against patterns"
    
    local report_file=$(generate_compliance_report "analyze")
    if [[ -f "$report_file" ]]; then
        echo "✅ PASS: E2E: Generate compliance report"
        TEST_RESULTS+=("PASS: E2E: Generate compliance report")
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL: E2E: Generate compliance report"
        TEST_RESULTS+=("FAIL: E2E: Generate compliance report")
        ((TESTS_FAILED++))
    fi
    
    # Restore original function
    eval "$original_get_repo_root"
}

# =============================================================================
# TEST RUNNER
# =============================================================================

# Run all tests
run_all_tests() {
    echo "🧪 Starting KB Integration Module Tests"
    echo "========================================"
    
    setup_tests
    
    # Run unit tests
    test_validate_kb_context
    test_cache_key_generation
    test_project_context_detection
    test_kb_query_execution
    test_fallback_guidance
    test_pattern_validation
    test_cache_operations
    test_query_knowledge_base
    test_validate_against_patterns
    test_get_applicable_principles
    test_generate_compliance_report
    
    # Run integration tests
    test_e2e_workflow
    
    cleanup_tests
    
    # Print summary
    echo
    echo "========================================"
    echo "📊 Test Results Summary"
    echo "========================================"
    echo "✅ Tests Passed: $TESTS_PASSED"
    echo "❌ Tests Failed: $TESTS_FAILED"
    echo "📈 Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "🎉 All tests passed!"
        return 0
    else
        echo "💥 Some tests failed!"
        echo
        echo "Failed tests:"
        for result in "${TEST_RESULTS[@]}"; do
            if [[ "$result" =~ ^FAIL: ]]; then
                echo "  - $result"
            fi
        done
        return 1
    fi
}

# Main execution
main() {
    case "${1:-run}" in
        "run"|"")
            run_all_tests
            ;;
        "help")
            echo "KB Integration Tests"
            echo "Usage: $0 [run|help]"
            echo
            echo "Commands:"
            echo "  run   - Run all tests (default)"
            echo "  help  - Show this help message"
            ;;
        *)
            echo "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi