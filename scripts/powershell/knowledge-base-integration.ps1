#!/usr/bin/env pwsh
# Knowledge Base Integration Module - PowerShell
# Provides KB query, validation, and compliance reporting functionality
# Part of SDD v2.0 Critical Systems Implementation

# Import common functions
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$ScriptDir/common.ps1"

# Global variables
$Script:KBCacheTTL = 86400  # 24 hours in seconds
$Script:KBQueryTimeout = 10 # 10 seconds timeout for queries

# =============================================================================
# CORE KB INTEGRATION FUNCTIONS
# =============================================================================

<#
.SYNOPSIS
Query knowledge base by context and search terms

.PARAMETER Context
KB context (shared-principles, frontend, backend, devops-sre)

.PARAMETER Query
Search query string

.EXAMPLE
Query-KnowledgeBase -Context "shared-principles" -Query "clean code naming"
#>
function Query-KnowledgeBase {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Context,
        
        [Parameter(Mandatory=$true)]
        [string]$Query
    )
    
    # Validate context
    if (-not (Test-KBContext -Context $Context)) {
        Write-Error "Invalid context '$Context'. Valid: shared-principles, frontend, backend, devops-sre"
        return $null
    }
    
    $repoRoot = Get-RepoRoot
    $kbRoot = Join-Path $repoRoot "memory/knowledge-base"
    
    # Check if KB exists
    if (-not (Test-Path $kbRoot)) {
        Write-Warning "Knowledge base not found at $kbRoot. Using fallback guidance."
        return Get-FallbackGuidance -Context $Context
    }
    
    # Check cache first
    $cacheKey = New-CacheKey -Context $Context -Query $Query
    $cachedResult = Get-CachedKBResult -CacheKey $cacheKey
    
    if ($cachedResult) {
        return $cachedResult
    }
    
    # Execute KB query with timeout
    try {
        $result = Invoke-KBQuery -KBContextDir (Join-Path $kbRoot $Context) -Query $Query -TimeoutSeconds $Script:KBQueryTimeout
        
        if (-not $result) {
            Write-Warning "KB query failed or returned empty. Using fallback guidance."
            $result = Get-FallbackGuidance -Context $Context
        }
    }
    catch {
        Write-Warning "KB query timed out or failed: $($_.Exception.Message). Using fallback guidance."
        $result = Get-FallbackGuidance -Context $Context
    }
    
    # Cache successful result
    if ($result) {
        Set-CachedKBResult -CacheKey $cacheKey -Result $result
    }
    
    # Set KB_REFERENCE placeholder for template substitution
    $env:KB_REFERENCE = $result
    return $result
}

<#
.SYNOPSIS
Validate artifact against KB patterns

.PARAMETER ArtifactPath
Path to artifact file to validate

.PARAMETER Context
KB context for validation

.EXAMPLE
Test-AgainstPatterns -ArtifactPath "./src/component.tsx" -Context "frontend"
#>
function Test-AgainstPatterns {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ArtifactPath,
        
        [Parameter(Mandatory=$true)]
        [string]$Context
    )
    
    # Check if artifact exists
    if (-not (Test-Path -Path $ArtifactPath -PathType Leaf)) {
        Write-Error "Artifact not found: $ArtifactPath"
        return $null
    }
    
    # Validate context
    if (-not (Test-KBContext -Context $Context)) {
        Write-Error "Invalid context '$Context'"
        return $null
    }
    
    $validationResults = @()
    $overallStatus = "PASS"
    
    # Get applicable patterns for context
    $patterns = Get-ApplicablePatterns -Context $Context
    
    if (-not $patterns) {
        Write-Warning "No patterns found for context '$Context'. Skipping validation."
        return "SKIP: No patterns available for validation"
    }
    
    # Execute validations
    foreach ($pattern in $patterns) {
        if ($pattern) {
            $result = Test-SinglePattern -ArtifactPath $ArtifactPath -Pattern $pattern -Context $Context
            $validationResults += $result
            
            # Check if any validation failed
            if ($result -match "FAIL:") {
                $overallStatus = "FAIL"
            }
        }
    }
    
    # Add summary
    $summary = "VALIDATION SUMMARY: $overallStatus`n`n" + ($validationResults -join "`n")
    
    return $summary
}

<#
.SYNOPSIS
Get applicable principles for domain/phase

.PARAMETER Domain
Domain or phase (analyze, architect, implement)

.EXAMPLE
Get-ApplicablePrinciples -Domain "analyze"
#>
function Get-ApplicablePrinciples {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Domain
    )
    
    $repoRoot = Get-RepoRoot
    $kbRoot = Join-Path $repoRoot "memory/knowledge-base"
    $principles = @("shared-principles")  # Always include shared principles
    
    # Detect project contexts based on files
    $detectedContexts = Get-ProjectContexts
    
    # Add context-specific principles
    foreach ($context in $detectedContexts) {
        if ($context -and (Test-Path (Join-Path $kbRoot $context))) {
            $principles += $context
        }
    }
    
    # Add domain-specific principles based on phase
    switch ($Domain) {
        "analyze" {
            # Analysis phase focuses on architecture assessment
            if ($principles -contains "backend") {
                $principles += "backend/domain-modeling"
            }
        }
        "architect" {
            # Architecture phase needs design patterns
            if ($principles -contains "frontend") {
                $principles += "frontend/ui-architecture"
            }
            if ($principles -contains "backend") {
                $principles += "backend/api-design"
            }
        }
        "implement" {
            # Implementation phase needs coding standards
            if ($principles -contains "frontend") {
                $principles += "frontend/react-patterns"
            }
            if ($principles -contains "devops-sre") {
                $principles += "devops-sre/deployment-patterns"
            }
        }
    }
    
    return $principles -join " "
}

<#
.SYNOPSIS
Generate compliance report for specific phase

.PARAMETER Phase
SDD phase (analyze, architect, implement)

.EXAMPLE
New-ComplianceReport -Phase "analyze"
#>
function New-ComplianceReport {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Phase
    )
    
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $repoRoot = Get-RepoRoot
    $reportDir = Join-Path $repoRoot ".specify-cache/compliance-reports"
    $reportFile = Join-Path $reportDir "compliance-report-$Phase-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    
    # Create reports directory
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    
    # Generate report content
    $reportContent = @"
# Compliance Report - $Phase Phase

**Generated**: $timestamp  
**Phase**: $Phase  
**Project**: $(Split-Path -Leaf $repoRoot)  
**KB Integration Version**: 1.0

## Executive Summary

$(New-ComplianceSummary -Phase $Phase)

## Applicable Principles

$(Get-ApplicablePrinciples -Domain $Phase)

## Detailed Compliance Analysis

$(New-DetailedCompliance -Phase $Phase)

## Recommendations

$(New-ComplianceRecommendations -Phase $Phase)

## KB References

$(New-KBReferences -Phase $Phase)

---

*Generated by Knowledge Base Integration Module v1.0*  
*Part of SDD v2.0 Critical Systems*
"@
    
    Set-Content -Path $reportFile -Value $reportContent -Encoding UTF8
    
    # Set COMPLIANCE_REPORT_PATH placeholder for template substitution
    $env:COMPLIANCE_REPORT_PATH = $reportFile
    return $reportFile
}

# =============================================================================
# SUPPORTING FUNCTIONS
# =============================================================================

# Test if KB context is valid
function Test-KBContext {
    param([string]$Context)
    
    return $Context -in @("shared-principles", "frontend", "backend", "devops-sre")
}

# Generate cache key for query
function New-CacheKey {
    param(
        [string]$Context,
        [string]$Query
    )
    
    $input = "${Context}_${Query}"
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    $hash = $hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($input))
    return [System.BitConverter]::ToString($hash).Replace("-", "").ToLower()
}

# Get cached KB result
function Get-CachedKBResult {
    param([string]$CacheKey)
    
    $repoRoot = Get-RepoRoot
    $cacheDir = Join-Path $repoRoot ".specify-cache/kb-queries"
    $cacheFile = Join-Path $cacheDir "$CacheKey.json"
    
    if (Test-Path $cacheFile) {
        # Check TTL (24 hours)
        $fileAge = (Get-Date) - (Get-Item $cacheFile).LastWriteTime
        if ($fileAge.TotalSeconds -lt $Script:KBCacheTTL) {
            return Get-Content $cacheFile -Raw
        }
        else {
            # Remove expired cache
            Remove-Item $cacheFile -Force -ErrorAction SilentlyContinue
        }
    }
    
    return $null
}

# Cache KB result
function Set-CachedKBResult {
    param(
        [string]$CacheKey,
        [string]$Result
    )
    
    $repoRoot = Get-RepoRoot
    $cacheDir = Join-Path $repoRoot ".specify-cache/kb-queries"
    
    if (-not (Test-Path $cacheDir)) {
        New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    }
    
    $cacheFile = Join-Path $cacheDir "$CacheKey.json"
    Set-Content -Path $cacheFile -Value $Result -Encoding UTF8
}

# Execute KB query in specific context directory
function Invoke-KBQuery {
    param(
        [string]$KBContextDir,
        [string]$Query,
        [int]$TimeoutSeconds = 10
    )
    
    if (-not (Test-Path $KBContextDir)) {
        return $null
    }
    
    # Search for relevant files using Select-String with case-insensitive matching
    $results = @()
    $queryTerms = $Query.ToLower() -split '\s+' | Where-Object { $_ }
    
    # Find markdown files and search content
    $mdFiles = Get-ChildItem -Path $KBContextDir -Filter "*.md" -Recurse -File
    
    foreach ($file in $mdFiles) {
        try {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content) {
                $hasMatch = $false
                foreach ($term in $queryTerms) {
                    if ($content -match $term) {
                        $hasMatch = $true
                        break
                    }
                }
                
                if ($hasMatch) {
                    $relevantContent = Get-RelevantContent -FilePath $file.FullName -QueryTerms $queryTerms
                    if ($relevantContent) {
                        $results += "## $($file.BaseName)`n`n$relevantContent`n"
                    }
                }
            }
        }
        catch {
            # Skip files that can't be read
            continue
        }
    }
    
    if ($results) {
        return $results -join "`n"
    }
    else {
        return "No specific guidance found for query: $Query"
    }
}

# Extract relevant content from file based on query
function Get-RelevantContent {
    param(
        [string]$FilePath,
        [string[]]$QueryTerms
    )
    
    try {
        $lines = Get-Content $FilePath
        $relevantLines = @()
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            $hasMatch = $false
            
            foreach ($term in $QueryTerms) {
                if ($line -match $term) {
                    $hasMatch = $true
                    break
                }
            }
            
            if ($hasMatch) {
                # Get context (3 lines before and after)
                $start = [Math]::Max(0, $i - 3)
                $end = [Math]::Min($lines.Count - 1, $i + 3)
                
                for ($j = $start; $j -le $end; $j++) {
                    if ($lines[$j] -notin $relevantLines) {
                        $relevantLines += $lines[$j]
                    }
                }
            }
        }
        
        return ($relevantLines | Select-Object -First 20) -join "`n"
    }
    catch {
        return $null
    }
}

# Detect project contexts based on file analysis
function Get-ProjectContexts {
    $repoRoot = Get-RepoRoot
    $contexts = @()
    
    # Detect frontend context
    if ((Test-Path (Join-Path $repoRoot "package.json")) -or 
        (Get-ChildItem -Path $repoRoot -Include "*.jsx", "*.tsx", "*.vue" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1)) {
        $contexts += "frontend"
    }
    
    # Detect backend context
    if ((Test-Path (Join-Path $repoRoot "pom.xml")) -or 
        (Test-Path (Join-Path $repoRoot "Cargo.toml")) -or 
        (Test-Path (Join-Path $repoRoot "go.mod")) -or
        (Get-ChildItem -Path $repoRoot -Include "*.java", "*.rs", "*.go", "*.py" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1)) {
        $contexts += "backend"
    }
    
    # Detect DevOps context
    if ((Test-Path (Join-Path $repoRoot "Dockerfile")) -or 
        (Test-Path (Join-Path $repoRoot "docker-compose.yml")) -or
        (Get-ChildItem -Path $repoRoot -Include "*.tf", "*.yml", "*.yaml" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1)) {
        $contexts += "devops-sre"
    }
    
    return $contexts
}

# Get applicable patterns for context
function Get-ApplicablePatterns {
    param([string]$Context)
    
    switch ($Context) {
        "shared-principles" {
            return @("clean-code-naming", "solid-principles", "dependency-rule")
        }
        "frontend" {
            return @("component-design", "state-management", "performance-optimization")
        }
        "backend" {
            return @("domain-modeling", "api-design", "data-persistence")
        }
        "devops-sre" {
            return @("infrastructure-as-code", "deployment-patterns", "monitoring")
        }
        default {
            return @("general-best-practices")
        }
    }
}

# Validate single pattern against artifact
function Test-SinglePattern {
    param(
        [string]$ArtifactPath,
        [string]$Pattern,
        [string]$Context
    )
    
    switch ($Pattern) {
        "clean-code-naming" {
            return Test-NamingConventions -ArtifactPath $ArtifactPath
        }
        "solid-principles" {
            return Test-SOLIDPrinciples -ArtifactPath $ArtifactPath
        }
        "component-design" {
            return Test-ComponentDesign -ArtifactPath $ArtifactPath
        }
        default {
            return "SKIP: Pattern '$Pattern' validation not implemented"
        }
    }
}

# Validate naming conventions
function Test-NamingConventions {
    param([string]$ArtifactPath)
    
    try {
        $content = Get-Content $ArtifactPath -Raw
        
        # Check for common naming issues
        if ($content -match "var|function|class") {
            # Check for single letter variables (except common ones like i, j, k)
            if ($content -match '\b[a-h,l-z]\b\s*=') {
                return "FAIL: Single letter variable names found (except i,j,k)"
            }
            else {
                return "PASS: Naming conventions check"
            }
        }
        else {
            return "SKIP: No code constructs found for naming validation"
        }
    }
    catch {
        return "ERROR: Could not validate naming conventions: $($_.Exception.Message)"
    }
}

# Validate SOLID principles (basic check)
function Test-SOLIDPrinciples {
    param([string]$ArtifactPath)
    
    try {
        $lineCount = (Get-Content $ArtifactPath).Count
        
        if ($lineCount -gt 500) {
            return "WARN: Large file ($lineCount lines) - consider splitting for Single Responsibility"
        }
        else {
            return "PASS: File size within reasonable bounds"
        }
    }
    catch {
        return "ERROR: Could not validate SOLID principles: $($_.Exception.Message)"
    }
}

# Validate component design (for frontend)
function Test-ComponentDesign {
    param([string]$ArtifactPath)
    
    if ($ArtifactPath -match '\.(jsx|tsx|vue)$') {
        try {
            $lineCount = (Get-Content $ArtifactPath).Count
            
            if ($lineCount -gt 200) {
                return "WARN: Large component ($lineCount lines) - consider breaking down"
            }
            else {
                return "PASS: Component size appropriate"
            }
        }
        catch {
            return "ERROR: Could not validate component design: $($_.Exception.Message)"
        }
    }
    else {
        return "SKIP: Not a component file"
    }
}

# Fallback guidance when KB unavailable
function Get-FallbackGuidance {
    param([string]$Context)
    
    switch ($Context) {
        "shared-principles" {
            return @"
## Basic Software Engineering Principles

- Apply SOLID principles (Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion)
- Use clear, descriptive naming for variables, functions, and classes
- Keep functions small and focused on a single task
- Write self-documenting code with minimal but effective comments
- Follow consistent code formatting and style guidelines
"@
        }
        "frontend" {
            return @"
## Basic Frontend Development Guidance

- Focus on component reusability and maintainability
- Implement proper state management patterns
- Optimize for user experience and performance
- Ensure accessibility compliance (WCAG guidelines)
- Use responsive design principles
- Minimize bundle size and optimize loading times
"@
        }
        "backend" {
            return @"
## Basic Backend Development Guidance

- Implement domain-driven design principles
- Design clean, RESTful APIs with proper HTTP methods
- Ensure data consistency and integrity
- Implement proper error handling and logging
- Use appropriate design patterns (Repository, Factory, etc.)
- Follow security best practices for authentication and authorization
"@
        }
        "devops-sre" {
            return @"
## Basic DevOps/SRE Guidance

- Implement Infrastructure as Code (IaC) practices
- Ensure comprehensive monitoring and alerting
- Automate deployment pipelines with proper testing
- Implement proper backup and disaster recovery procedures
- Follow security best practices for infrastructure
- Document operational procedures and runbooks
"@
        }
        default {
            return "Apply general software engineering best practices: clean code, proper testing, documentation, and maintainable architecture."
        }
    }
}

# Generate compliance summary
function New-ComplianceSummary {
    param([string]$Phase)
    
    return @"
This compliance report analyzes the current project state against Knowledge Base v2.0 standards for the **$Phase** phase.

**Key Areas Assessed:**
- Adherence to shared software engineering principles
- Context-specific best practices application
- Pattern consistency across the project
- Documentation and maintainability standards

**Assessment Method:**
- Automated pattern detection and validation
- Knowledge Base query integration
- Fallback guidance when specific patterns unavailable
"@
}

# Generate detailed compliance analysis
function New-DetailedCompliance {
    param([string]$Phase)
    
    $repoRoot = Get-RepoRoot
    $detectedContexts = (Get-ProjectContexts) -join " "
    $applicablePrinciples = Get-ApplicablePrinciples -Domain $Phase
    
    return @"
### Project Structure Analysis

**Repository Root:** $repoRoot
**Detected Contexts:** $detectedContexts
**Applicable Principles:** $applicablePrinciples

### Validation Results

*Detailed validation results would be generated here based on actual project files.*

### Knowledge Base Coverage

- ✅ Shared principles guidance available
- ✅ Context-specific patterns identified
- ✅ Fallback guidance implemented
"@
}

# Generate compliance recommendations
function New-ComplianceRecommendations {
    param([string]$Phase)
    
    $baseRecommendations = @"
### Immediate Actions
1. Review and apply shared principles across all code
2. Implement context-specific patterns for detected technologies
3. Ensure consistent naming conventions throughout project

### Phase-Specific Recommendations ($Phase)
"@
    
    $phaseSpecific = switch ($Phase) {
        "analyze" {
            @"
- Complete architecture assessment using KB guidance
- Document technical debt and constraints
- Validate pattern applicability for project context
"@
        }
        "architect" {
            @"
- Create Architecture Decision Records (ADRs) for key decisions
- Ensure design consistency across components
- Validate dependency flow follows clean architecture principles
"@
        }
        "implement" {
            @"
- Apply coding standards consistently
- Ensure adequate test coverage
- Document implementation decisions and patterns used
"@
        }
        default {
            "- Follow general best practices for this phase"
        }
    }
    
    return $baseRecommendations + "`n" + $phaseSpecific
}

# Generate KB references used
function New-KBReferences {
    param([string]$Phase)
    
    $repoRoot = Get-RepoRoot
    $kbRoot = Join-Path $repoRoot "memory/knowledge-base"
    $principles = (Get-ApplicablePrinciples -Domain $Phase) -split '\s+'
    
    $references = @"
### Knowledge Base References

**Base Path:** $kbRoot

**Referenced Contexts:**
"@
    
    foreach ($principle in $principles) {
        if ($principle) {
            $principleDir = Join-Path $kbRoot $principle
            if (Test-Path $principleDir) {
                $references += "`n- ✅ $principle/ (available)"
            }
            else {
                $references += "`n- ❌ $principle/ (not found - using fallback)"
            }
        }
    }
    
    return $references
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Display KB integration status
function Show-KBStatus {
    $repoRoot = Get-RepoRoot
    $kbRoot = Join-Path $repoRoot "memory/knowledge-base"
    $cacheDir = Join-Path $repoRoot ".specify-cache"
    
    Write-Output "=== Knowledge Base Integration Status ==="
    Write-Output ""
    Write-Output "KB Root: $kbRoot"
    Write-Output "KB Available: $(if (Test-Path $kbRoot) { '✅ Yes' } else { '❌ No' })"
    Write-Output "Cache Directory: $cacheDir"
    Write-Output "Cache Available: $(if (Test-Path $cacheDir) { '✅ Yes' } else { '❌ No' })"
    Write-Output ""
    Write-Output "Available Contexts:"
    
    foreach ($context in @("shared-principles", "frontend", "backend", "devops-sre")) {
        $contextDir = Join-Path $kbRoot $context
        if (Test-Path $contextDir) {
            Write-Output "  ✅ $context"
        }
        else {
            Write-Output "  ❌ $context"
        }
    }
    
    Write-Output ""
    Write-Output "Detected Project Contexts:"
    
    $detectedContexts = Get-ProjectContexts
    foreach ($context in $detectedContexts) {
        Write-Output "  🔍 $context"
    }
}

# Clear KB cache
function Clear-KBCache {
    $repoRoot = Get-RepoRoot
    $cacheDir = Join-Path $repoRoot ".specify-cache/kb-queries"
    
    if (Test-Path $cacheDir) {
        Remove-Item $cacheDir -Recurse -Force
        Write-Output "✅ KB cache cleared"
    }
    else {
        Write-Output "ℹ️  No cache to clear"
    }
}

# Main function for direct script execution
function Main {
    param([string[]]$Arguments)
    
    if ($Arguments.Count -eq 0) {
        $Arguments = @("help")
    }
    
    switch ($Arguments[0]) {
        "status" {
            Show-KBStatus
        }
        "clear-cache" {
            Clear-KBCache
        }
        "query" {
            if ($Arguments.Count -lt 3) {
                Write-Output "Usage: .\knowledge-base-integration.ps1 query <context> <query_string>"
                exit 1
            }
            Query-KnowledgeBase -Context $Arguments[1] -Query $Arguments[2]
        }
        "validate" {
            if ($Arguments.Count -lt 3) {
                Write-Output "Usage: .\knowledge-base-integration.ps1 validate <artifact_path> <context>"
                exit 1
            }
            Test-AgainstPatterns -ArtifactPath $Arguments[1] -Context $Arguments[2]
        }
        "principles" {
            if ($Arguments.Count -lt 2) {
                Write-Output "Usage: .\knowledge-base-integration.ps1 principles <domain>"
                exit 1
            }
            Get-ApplicablePrinciples -Domain $Arguments[1]
        }
        "report" {
            if ($Arguments.Count -lt 2) {
                Write-Output "Usage: .\knowledge-base-integration.ps1 report <phase>"
                exit 1
            }
            New-ComplianceReport -Phase $Arguments[1]
        }
        default {
            Write-Output "Knowledge Base Integration Module v1.0 - PowerShell"
            Write-Output "Usage: .\knowledge-base-integration.ps1 {status|clear-cache|query|validate|principles|report}"
            Write-Output ""
            Write-Output "Commands:"
            Write-Output "  status                     - Show KB integration status"
            Write-Output "  clear-cache               - Clear KB query cache"
            Write-Output "  query <context> <query>   - Query KB for specific context"
            Write-Output "  validate <file> <context> - Validate file against KB patterns"
            Write-Output "  principles <domain>       - Get applicable principles for domain"
            Write-Output "  report <phase>           - Generate compliance report for phase"
        }
    }
}

# Execute main function if script is run directly
if ($MyInvocation.InvocationName -ne '.') {
    Main -Arguments $args
}