#!/usr/bin/env pwsh
# Knowledge Base Integration Module - Unit Tests (PowerShell)
# Tests for KB query, validation, and compliance functions

# Import the KB integration module
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir/../powershell/knowledge-base-integration.ps1"

# Test configuration
$Script:TestResults = @()
$Script:TestsPassed = 0
$Script:TestsFailed = 0
$Script:TempDir = Join-Path $env:TEMP "kb-integration-tests-$(Get-Random)"

# =============================================================================
# TEST UTILITIES
# =============================================================================

# Setup test environment
function Initialize-Tests {
    Write-Output "=== Setting up KB Integration Tests ==="
    
    # Create temporary directory
    New-Item -ItemType Directory -Path $Script:TempDir -Force | Out-Null
    
    # Create mock KB structure
    $kbDirs = @(
        "memory/knowledge-base/shared-principles",
        "memory/knowledge-base/frontend", 
        "memory/knowledge-base/backend",
        "memory/knowledge-base/devops-sre"
    )
    
    foreach ($dir in $kbDirs) {
        New-Item -ItemType Directory -Path (Join-Path $Script:TempDir $dir) -Force | Out-Null
    }
    
    # Create mock KB content
    $cleanCodeContent = @"
# Clean Code Principles

## Naming Conventions
- Use descriptive names for variables and functions
- Avoid single letter variables except for loop counters
- Use consistent naming patterns

## Functions
- Keep functions small and focused
- Functions should do one thing well
- Use descriptive function names
"@
    
    Set-Content -Path (Join-Path $Script:TempDir "memory/knowledge-base/shared-principles/clean-code.md") -Value $cleanCodeContent
    
    $componentContent = @"
# Component Design Patterns

## React Components
- Keep components small and focused
- Use composition over inheritance
- Implement proper prop validation

## State Management
- Use local state when possible
- Lift state up when needed by multiple components
"@
    
    Set-Content -Path (Join-Path $Script:TempDir "memory/knowledge-base/frontend/component-design.md") -Value $componentContent
    
    # Create test artifacts
    $testComponent = @"
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
"@
    
    Set-Content -Path (Join-Path $Script:TempDir "test-component.tsx") -Value $testComponent
    
    # Create large file for testing
    $largeFileContent = (1..600 | ForEach-Object { "console.log('Line $_');" }) -join "`n"
    Set-Content -Path (Join-Path $Script:TempDir "test-large-file.js") -Value $largeFileContent
    
    Write-Output "✅ Test environment setup complete"
}

# Cleanup test environment
function Remove-Tests {
    Write-Output "=== Cleaning up KB Integration Tests ==="
    if (Test-Path $Script:TempDir) {
        Remove-Item $Script:TempDir -Recurse -Force
    }
    Write-Output "✅ Test cleanup complete"
}

# Test assertion functions
function Assert-Equals {
    param(
        [string]$Expected,
        [string]$Actual,
        [string]$TestName
    )
    
    if ($Expected -eq $Actual) {
        Write-Output "✅ PASS: $TestName"
        $Script:TestResults += "PASS: $TestName"
        $Script:TestsPassed++
        return $true
    }
    else {
        Write-Output "❌ FAIL: $TestName"
        Write-Output "   Expected: $Expected"
        Write-Output "   Actual: $Actual"
        $Script:TestResults += "FAIL: $TestName"
        $Script:TestsFailed++
        return $false
    }
}

function Assert-Contains {
    param(
        [string]$Expected,
        [string]$Actual,
        [string]$TestName
    )
    
    if ($Actual -match $Expected) {
        Write-Output "✅ PASS: $TestName"
        $Script:TestResults += "PASS: $TestName"
        $Script:TestsPassed++
        return $true
    }
    else {
        Write-Output "❌ FAIL: $TestName"
        Write-Output "   Expected to contain: $Expected"
        Write-Output "   Actual: $Actual"
        $Script:TestResults += "FAIL: $TestName"
        $Script:TestsFailed++
        return $false
    }
}

function Assert-NotEmpty {
    param(
        [string]$Actual,
        [string]$TestName
    )
    
    if (-not [string]::IsNullOrEmpty($Actual)) {
        Write-Output "✅ PASS: $TestName"
        $Script:TestResults += "PASS: $TestName"
        $Script:TestsPassed++
        return $true
    }
    else {
        Write-Output "❌ FAIL: $TestName"
        Write-Output "   Expected non-empty result"
        $Script:TestResults += "FAIL: $TestName"
        $Script:TestsFailed++
        return $false
    }
}

function Assert-True {
    param(
        [bool]$Condition,
        [string]$TestName
    )
    
    if ($Condition) {
        Write-Output "✅ PASS: $TestName"
        $Script:TestResults += "PASS: $TestName"
        $Script:TestsPassed++
        return $true
    }
    else {
        Write-Output "❌ FAIL: $TestName"
        $Script:TestResults += "FAIL: $TestName"
        $Script:TestsFailed++
        return $false
    }
}

# =============================================================================
# UNIT TESTS
# =============================================================================

# Test KB context validation
function Test-KBContextValidation {
    Write-Output "--- Testing KB Context Validation ---"
    
    # Test valid contexts
    Assert-True (Test-KBContext -Context "shared-principles") "Valid context: shared-principles"
    Assert-True (Test-KBContext -Context "frontend") "Valid context: frontend"
    Assert-True (Test-KBContext -Context "backend") "Valid context: backend"
    Assert-True (Test-KBContext -Context "devops-sre") "Valid context: devops-sre"
    
    # Test invalid context
    Assert-True (-not (Test-KBContext -Context "invalid-context")) "Invalid context should fail"
}

# Test cache key generation
function Test-CacheKeyGeneration {
    Write-Output "--- Testing Cache Key Generation ---"
    
    $key1 = New-CacheKey -Context "shared-principles" -Query "clean code"
    $key2 = New-CacheKey -Context "shared-principles" -Query "clean code"
    $key3 = New-CacheKey -Context "frontend" -Query "clean code"
    
    Assert-Equals $key1 $key2 "Same input should generate same key"
    Assert-True ($key1 -ne $key3) "Different input generates different key"
    
    # Test key format (should be 64 character hex)
    Assert-True (($key1.Length -eq 64) -and ($key1 -match '^[a-f0-9]+$')) "Cache key format is correct"
}

# Test project context detection
function Test-ProjectContextDetection {
    Write-Output "--- Testing Project Context Detection ---"
    
    # Mock Get-RepoRoot for testing
    $originalGetRepoRoot = Get-Command Get-RepoRoot -ErrorAction SilentlyContinue
    function Get-RepoRoot { return $Script:TempDir }
    
    # Create test files for context detection
    New-Item -ItemType File -Path (Join-Path $Script:TempDir "package.json") -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $Script:TempDir "component.tsx") -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $Script:TempDir "Dockerfile") -Force | Out-Null
    
    $contexts = Get-ProjectContexts
    
    Assert-Contains "frontend" ($contexts -join " ") "Frontend context detected"
    Assert-Contains "devops-sre" ($contexts -join " ") "DevOps context detected"
    
    # Restore original function if it existed
    if ($originalGetRepoRoot) {
        Set-Item -Path "function:Get-RepoRoot" -Value $originalGetRepoRoot.Definition
    }
}

# Test KB query execution
function Test-KBQueryExecution {
    Write-Output "--- Testing KB Query Execution ---"
    
    # Mock Get-RepoRoot for testing
    function Get-RepoRoot { return $Script:TempDir }
    
    # Test successful query
    $result = Invoke-KBQuery -KBContextDir (Join-Path $Script:TempDir "memory/knowledge-base/shared-principles") -Query "naming"
    Assert-Contains "naming" $result "KB query returns relevant content"
    
    # Test query with no results
    $emptyResult = Invoke-KBQuery -KBContextDir (Join-Path $Script:TempDir "memory/knowledge-base/shared-principles") -Query "nonexistent"
    Assert-Contains "No specific guidance found" $emptyResult "KB query handles no results"
    
    # Test invalid directory
    $invalidResult = Invoke-KBQuery -KBContextDir "/nonexistent/path" -Query "test"
    Assert-True ([string]::IsNullOrEmpty($invalidResult)) "KB query handles invalid directory"
}

# Test fallback guidance
function Test-FallbackGuidance {
    Write-Output "--- Testing Fallback Guidance ---"
    
    $sharedFallback = Get-FallbackGuidance -Context "shared-principles"
    Assert-Contains "SOLID principles" $sharedFallback "Shared principles fallback"
    
    $frontendFallback = Get-FallbackGuidance -Context "frontend"
    Assert-Contains "component reusability" $frontendFallback "Frontend fallback"
    
    $backendFallback = Get-FallbackGuidance -Context "backend"
    Assert-Contains "domain-driven design" $backendFallback "Backend fallback"
    
    $devopsFallback = Get-FallbackGuidance -Context "devops-sre"
    Assert-Contains "Infrastructure as Code" $devopsFallback "DevOps fallback"
    
    $defaultFallback = Get-FallbackGuidance -Context "unknown"
    Assert-NotEmpty $defaultFallback "Default fallback"
}

# Test pattern validation
function Test-PatternValidation {
    Write-Output "--- Testing Pattern Validation ---"
    
    # Test naming conventions validation
    $namingResult = Test-NamingConventions -ArtifactPath (Join-Path $Script:TempDir "test-component.tsx")
    Assert-Contains "(PASS|SKIP)" $namingResult "Naming validation executes"
    
    # Test SOLID principles validation
    $solidResult = Test-SOLIDPrinciples -ArtifactPath (Join-Path $Script:TempDir "test-large-file.js")
    Assert-Contains "WARN.*Large file" $solidResult "SOLID validation detects large files"
    
    # Test component design validation
    $componentResult = Test-ComponentDesign -ArtifactPath (Join-Path $Script:TempDir "test-component.tsx")
    Assert-Contains "PASS" $componentResult "Component validation passes for small component"
}

# Test cache operations
function Test-CacheOperations {
    Write-Output "--- Testing Cache Operations ---"
    
    # Mock Get-RepoRoot for testing
    function Get-RepoRoot { return $Script:TempDir }
    
    $testKey = "test_cache_key"
    $testResult = "test cache result"
    
    # Test cache storage
    Set-CachedKBResult -CacheKey $testKey -Result $testResult
    
    # Test cache retrieval
    $cachedResult = Get-CachedKBResult -CacheKey $testKey
    Assert-Equals $testResult $cachedResult "Cache stores and retrieves correctly"
    
    # Test cache expiry (simulate old file)
    $cacheFile = Join-Path $Script:TempDir ".specify-cache/kb-queries/$testKey.json"
    if (Test-Path $cacheFile) {
        # Set file timestamp to 25 hours ago (beyond TTL)
        (Get-Item $cacheFile).LastWriteTime = (Get-Date).AddHours(-25)
        $expiredResult = Get-CachedKBResult -CacheKey $testKey
        Assert-True ([string]::IsNullOrEmpty($expiredResult)) "Expired cache returns empty"
    }
}

# Test Query-KnowledgeBase function
function Test-QueryKnowledgeBase {
    Write-Output "--- Testing Query-KnowledgeBase Function ---"
    
    # Mock Get-RepoRoot for testing
    function Get-RepoRoot { return $Script:TempDir }
    
    # Test valid query
    $result = Query-KnowledgeBase -Context "shared-principles" -Query "naming"
    Assert-NotEmpty $result "Query returns result"
    
    # Test invalid context (should write error and return null)
    $ErrorActionPreference = 'SilentlyContinue'
    $invalidResult = Query-KnowledgeBase -Context "invalid" -Query "test"
    $ErrorActionPreference = 'Continue'
    Assert-True ([string]::IsNullOrEmpty($invalidResult)) "Invalid context returns null"
}

# Test Test-AgainstPatterns function
function Test-ValidateAgainstPatterns {
    Write-Output "--- Testing Test-AgainstPatterns Function ---"
    
    # Test valid validation
    $result = Test-AgainstPatterns -ArtifactPath (Join-Path $Script:TempDir "test-component.tsx") -Context "frontend"
    Assert-Contains "VALIDATION SUMMARY" $result "Validation returns summary"
    
    # Test non-existent file
    $ErrorActionPreference = 'SilentlyContinue'
    $invalidResult = Test-AgainstPatterns -ArtifactPath "/nonexistent/file.js" -Context "frontend"
    $ErrorActionPreference = 'Continue'
    Assert-True ([string]::IsNullOrEmpty($invalidResult)) "Non-existent file returns null"
}

# Test Get-ApplicablePrinciples function
function Test-GetApplicablePrinciples {
    Write-Output "--- Testing Get-ApplicablePrinciples Function ---"
    
    # Mock Get-RepoRoot for testing
    function Get-RepoRoot { return $Script:TempDir }
    
    # Create test files for context detection
    New-Item -ItemType File -Path (Join-Path $Script:TempDir "package.json") -Force | Out-Null
    
    $result = Get-ApplicablePrinciples -Domain "analyze"
    Assert-Contains "shared-principles" $result "Always includes shared principles"
    
    $architectResult = Get-ApplicablePrinciples -Domain "architect"
    Assert-NotEmpty $architectResult "Architect phase returns principles"
    
    $implementResult = Get-ApplicablePrinciples -Domain "implement"
    Assert-NotEmpty $implementResult "Implement phase returns principles"
}

# Test New-ComplianceReport function
function Test-GenerateComplianceReport {
    Write-Output "--- Testing New-ComplianceReport Function ---"
    
    # Mock Get-RepoRoot for testing
    function Get-RepoRoot { return $Script:TempDir }
    
    $reportFile = New-ComplianceReport -Phase "analyze"
    
    # Check if report file was created
    if (Test-Path $reportFile) {
        Assert-True $true "Compliance report file created"
        
        # Check report content
        $content = Get-Content $reportFile -Raw
        Assert-Contains "Compliance Report - analyze Phase" $content "Report contains correct title"
        Assert-Contains "Generated:" $content "Report contains timestamp"
        Assert-Contains "Knowledge Base Integration Module" $content "Report contains module info"
    }
    else {
        Assert-True $false "Compliance report file not created"
    }
}

# =============================================================================
# INTEGRATION TESTS
# =============================================================================

# Test end-to-end workflow
function Test-E2EWorkflow {
    Write-Output "--- Testing End-to-End Workflow ---"
    
    # Mock Get-RepoRoot for testing
    function Get-RepoRoot { return $Script:TempDir }
    
    # Create test project structure
    New-Item -ItemType File -Path (Join-Path $Script:TempDir "package.json") -Force | Out-Null
    
    # Test complete workflow
    $principles = Get-ApplicablePrinciples -Domain "analyze"
    Assert-NotEmpty $principles "E2E: Get applicable principles"
    
    $queryResult = Query-KnowledgeBase -Context "shared-principles" -Query "clean code"
    Assert-NotEmpty $queryResult "E2E: Query knowledge base"
    
    $validationResult = Test-AgainstPatterns -ArtifactPath (Join-Path $Script:TempDir "test-component.tsx") -Context "frontend"
    Assert-Contains "VALIDATION SUMMARY" $validationResult "E2E: Validate against patterns"
    
    $reportFile = New-ComplianceReport -Phase "analyze"
    Assert-True (Test-Path $reportFile) "E2E: Generate compliance report"
}

# =============================================================================
# TEST RUNNER
# =============================================================================

# Run all tests
function Invoke-AllTests {
    Write-Output "🧪 Starting KB Integration Module Tests (PowerShell)"
    Write-Output "========================================================"
    
    Initialize-Tests
    
    try {
        # Run unit tests
        Test-KBContextValidation
        Test-CacheKeyGeneration
        Test-ProjectContextDetection
        Test-KBQueryExecution
        Test-FallbackGuidance
        Test-PatternValidation
        Test-CacheOperations
        Test-QueryKnowledgeBase
        Test-ValidateAgainstPatterns
        Test-GetApplicablePrinciples
        Test-GenerateComplianceReport
        
        # Run integration tests
        Test-E2EWorkflow
    }
    finally {
        Remove-Tests
    }
    
    # Print summary
    Write-Output ""
    Write-Output "========================================"
    Write-Output "📊 Test Results Summary"
    Write-Output "========================================"
    Write-Output "✅ Tests Passed: $Script:TestsPassed"
    Write-Output "❌ Tests Failed: $Script:TestsFailed"
    Write-Output "📈 Total Tests: $($Script:TestsPassed + $Script:TestsFailed)"
    
    if ($Script:TestsFailed -eq 0) {
        Write-Output "🎉 All tests passed!"
        return $true
    }
    else {
        Write-Output "💥 Some tests failed!"
        Write-Output ""
        Write-Output "Failed tests:"
        foreach ($result in $Script:TestResults) {
            if ($result -match '^FAIL:') {
                Write-Output "  - $result"
            }
        }
        return $false
    }
}

# Main execution function
function Main {
    param([string[]]$Arguments)
    
    if ($Arguments.Count -eq 0) {
        $Arguments = @("run")
    }
    
    switch ($Arguments[0]) {
        "run" {
            $success = Invoke-AllTests
            if (-not $success) {
                exit 1
            }
        }
        "help" {
            Write-Output "KB Integration Tests (PowerShell)"
            Write-Output "Usage: .\kb-integration-tests.ps1 [run|help]"
            Write-Output ""
            Write-Output "Commands:"
            Write-Output "  run   - Run all tests (default)"
            Write-Output "  help  - Show this help message"
        }
        default {
            Write-Output "Unknown command: $($Arguments[0])"
            Write-Output "Use '.\kb-integration-tests.ps1 help' for usage information"
            exit 1
        }
    }
}

# Execute main function if script is run directly
if ($MyInvocation.InvocationName -ne '.') {
    Main -Arguments $args
}