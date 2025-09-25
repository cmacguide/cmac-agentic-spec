# Artifact Integration Tests - PowerShell Version
# Comprehensive test suite for the Artifact Generation System
# Part of SDD v2.0 Critical Systems Implementation - Phase 2.3

param(
    [string]$TestFilter = "",
    [switch]$Verbose = $false
)

# Test configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$TestOutputDir = Join-Path $RepoRoot ".specify-cache\test-results"
$TestArtifactsDir = Join-Path $RepoRoot ".specify-cache\test-artifacts"

# Test counters
$Global:TestsTotal = 0
$Global:TestsPassed = 0
$Global:TestsFailed = 0

# Colors for output
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Blue"
    White = "White"
}

# =============================================================================
# TEST UTILITIES
# =============================================================================

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Colors[$Color]
}

function Initialize-TestEnvironment {
    Write-ColorOutput "🔧 Initializing test environment..." "Blue"
    
    # Create test directories
    if (-not (Test-Path $TestOutputDir)) {
        New-Item -ItemType Directory -Path $TestOutputDir -Force | Out-Null
    }
    if (-not (Test-Path $TestArtifactsDir)) {
        New-Item -ItemType Directory -Path $TestArtifactsDir -Force | Out-Null
    }
    
    # Clean previous test results
    Get-ChildItem $TestOutputDir -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Get-ChildItem $TestArtifactsDir -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    
    # Initialize test counters
    $Global:TestsTotal = 0
    $Global:TestsPassed = 0
    $Global:TestsFailed = 0
    
    Write-ColorOutput "✅ Test environment initialized" "Green"
}

function Invoke-Test {
    param(
        [string]$TestName,
        [scriptblock]$TestFunction
    )
    
    $Global:TestsTotal++
    Write-ColorOutput "🧪 Running test: $TestName" "Blue"
    
    try {
        $result = & $TestFunction
        if ($result) {
            $Global:TestsPassed++
            Write-ColorOutput "✅ PASS: $TestName" "Green"
            return $true
        } else {
            $Global:TestsFailed++
            Write-ColorOutput "❌ FAIL: $TestName" "Red"
            return $false
        }
    } catch {
        $Global:TestsFailed++
        Write-ColorOutput "❌ FAIL: $TestName - Exception: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Assert-FileExists {
    param(
        [string]$FilePath,
        [string]$Description = "File"
    )
    
    if (Test-Path $FilePath -PathType Leaf) {
        Write-Host "  ✅ $Description exists: $FilePath"
        return $true
    } else {
        Write-Host "  ❌ $Description missing: $FilePath"
        return $false
    }
}

function Assert-DirectoryExists {
    param(
        [string]$DirectoryPath,
        [string]$Description = "Directory"
    )
    
    if (Test-Path $DirectoryPath -PathType Container) {
        Write-Host "  ✅ $Description exists: $DirectoryPath"
        return $true
    } else {
        Write-Host "  ❌ $Description missing: $DirectoryPath"
        return $false
    }
}

function Assert-ContentContains {
    param(
        [string]$FilePath,
        [string]$ExpectedContent,
        [string]$Description = "Content check"
    )
    
    if ((Test-Path $FilePath) -and (Select-String -Path $FilePath -Pattern $ExpectedContent -Quiet)) {
        Write-Host "  ✅ $Description`: Found '$ExpectedContent'"
        return $true
    } else {
        Write-Host "  ❌ $Description`: Missing '$ExpectedContent' in $FilePath"
        return $false
    }
}

function Assert-ValidJson {
    param(
        [string]$FilePath,
        [string]$Description = "JSON validation"
    )
    
    if (Test-Path $FilePath) {
        try {
            Get-Content $FilePath -Raw | ConvertFrom-Json | Out-Null
            Write-Host "  ✅ $Description`: Valid JSON"
            return $true
        } catch {
            Write-Host "  ❌ $Description`: Invalid JSON in $FilePath"
            return $false
        }
    } else {
        Write-Host "  ❌ $Description`: File not found $FilePath"
        return $false
    }
}

# =============================================================================
# ARTIFACT GENERATION WRAPPER FUNCTIONS
# =============================================================================

function Invoke-ArtifactGeneration {
    param(
        [string]$TemplateId,
        [string]$Phase,
        [string]$Context,
        [string]$OutputPath = ""
    )
    
    $bashScript = Join-Path $RepoRoot "scripts\bash\artifact-generation.sh"
    
    if ($OutputPath) {
        $result = & bash $bashScript generate $TemplateId $Phase $Context $OutputPath 2>&1
    } else {
        $result = & bash $bashScript generate $TemplateId $Phase $Context 2>&1
    }
    
    return $LASTEXITCODE -eq 0
}

function Invoke-PhaseArtifactGeneration {
    param(
        [string]$Phase,
        [string]$Context
    )
    
    $bashScript = Join-Path $RepoRoot "scripts\bash\artifact-generation.sh"
    $result = & bash $bashScript generate-phase $Phase $Context 2>&1
    
    return $LASTEXITCODE -eq 0
}

function Get-PhaseTemplates {
    param(
        [string]$Phase
    )
    
    $bashScript = Join-Path $RepoRoot "scripts\bash\artifact-generation.sh"
    $result = & bash $bashScript list-templates $Phase 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        return $result
    } else {
        return @()
    }
}

# =============================================================================
# INDIVIDUAL ARTIFACT GENERATION TESTS
# =============================================================================

function Test-AnalyzeIndividualArtifacts {
    $testContext = "shared-principles"
    $phase = "analyze"
    $success = $true
    
    Write-Host "  Testing individual artifact generation for $phase phase..."
    
    $templates = @("architecture_assessment", "technical_debt_report", "compliance_check", "knowledge_base_references")
    
    foreach ($templateId in $templates) {
        Write-Host "    Generating $templateId..."
        
        $outputFile = Join-Path $TestArtifactsDir "$phase\$templateId.test"
        $outputDir = Split-Path $outputFile -Parent
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        if (Invoke-ArtifactGeneration $templateId $phase $testContext $outputFile) {
            if (-not (Assert-FileExists $outputFile "$templateId artifact")) {
                $success = $false
            }
            
            if ((Test-Path $outputFile) -and ((Get-Item $outputFile).Length -lt 100)) {
                Write-Host "    ❌ $templateId`: Content too short"
                $success = $false
            } else {
                Write-Host "    ✅ $templateId`: Generated successfully"
            }
            
            if ($templateId -like "*compliance_check*") {
                if (-not (Assert-ValidJson $outputFile "$templateId JSON")) {
                    $success = $false
                }
            }
        } else {
            Write-Host "    ❌ $templateId`: Generation failed"
            $success = $false
        }
    }
    
    return $success
}

function Test-ArchitectIndividualArtifacts {
    $testContext = "shared-principles"
    $phase = "architect"
    $success = $true
    
    Write-Host "  Testing individual artifact generation for $phase phase..."
    
    $templates = @("architecture_decision_record", "system_design_document", "component_interaction_diagram", "validation_report")
    
    foreach ($templateId in $templates) {
        Write-Host "    Generating $templateId..."
        
        $outputFile = Join-Path $TestArtifactsDir "$phase\$templateId.test"
        $outputDir = Split-Path $outputFile -Parent
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        if (Invoke-ArtifactGeneration $templateId $phase $testContext $outputFile) {
            if (-not (Assert-FileExists $outputFile "$templateId artifact")) {
                $success = $false
            }
            
            if ((Test-Path $outputFile) -and ((Get-Item $outputFile).Length -lt 100)) {
                Write-Host "    ❌ $templateId`: Content too short"
                $success = $false
            } else {
                Write-Host "    ✅ $templateId`: Generated successfully"
            }
            
            if ($templateId -like "*component_interaction_diagram*") {
                if (-not (Assert-ContentContains $outputFile "(graph|flowchart|sequenceDiagram)" "Mermaid diagram")) {
                    $success = $false
                }
            }
        } else {
            Write-Host "    ❌ $templateId`: Generation failed"
            $success = $false
        }
    }
    
    return $success
}

function Test-ImplementIndividualArtifacts {
    $testContext = "shared-principles"
    $phase = "implement"
    $success = $true
    
    Write-Host "  Testing individual artifact generation for $phase phase..."
    
    $templates = @("code_quality_report", "test_coverage_report", "performance_benchmarks", "api_documentation")
    
    foreach ($templateId in $templates) {
        Write-Host "    Generating $templateId..."
        
        $outputFile = Join-Path $TestArtifactsDir "$phase\$templateId.test"
        $outputDir = Split-Path $outputFile -Parent
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        if (Invoke-ArtifactGeneration $templateId $phase $testContext $outputFile) {
            if (-not (Assert-FileExists $outputFile "$templateId artifact")) {
                $success = $false
            }
            
            if ((Test-Path $outputFile) -and ((Get-Item $outputFile).Length -lt 100)) {
                Write-Host "    ❌ $templateId`: Content too short"
                $success = $false
            } else {
                Write-Host "    ✅ $templateId`: Generated successfully"
            }
            
            if ($templateId -like "*code_quality_report*") {
                if (-not (Assert-ValidJson $outputFile "$templateId JSON")) {
                    $success = $false
                }
            }
            
            if ($templateId -like "*test_coverage_report*") {
                if (-not (Assert-ContentContains $outputFile "(<html>|<HTML>)" "HTML structure")) {
                    $success = $false
                }
            }
        } else {
            Write-Host "    ❌ $templateId`: Generation failed"
            $success = $false
        }
    }
    
    return $success
}

function Test-CheckpointsIndividualArtifacts {
    $testContext = "shared-principles"
    $phase = "checkpoints"
    $success = $true
    
    Write-Host "  Testing individual artifact generation for $phase phase..."
    
    $templates = @("quality_gate_results", "compliance_audit", "rollback_snapshot", "checkpoint_summary")
    
    foreach ($templateId in $templates) {
        Write-Host "    Generating $templateId..."
        
        $outputFile = Join-Path $TestArtifactsDir "$phase\$templateId.test"
        $outputDir = Split-Path $outputFile -Parent
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        if (Invoke-ArtifactGeneration $templateId $phase $testContext $outputFile) {
            if (-not (Assert-FileExists $outputFile "$templateId artifact")) {
                $success = $false
            }
            
            if ((Test-Path $outputFile) -and ((Get-Item $outputFile).Length -lt 100)) {
                Write-Host "    ❌ $templateId`: Content too short"
                $success = $false
            } else {
                Write-Host "    ✅ $templateId`: Generated successfully"
            }
            
            if (($templateId -like "*quality_gate_results*") -or ($templateId -like "*rollback_snapshot*")) {
                if (-not (Assert-ValidJson $outputFile "$templateId JSON")) {
                    $success = $false
                }
            }
        } else {
            Write-Host "    ❌ $templateId`: Generation failed"
            $success = $false
        }
    }
    
    return $success
}

# =============================================================================
# PHASE GENERATION TESTS
# =============================================================================

function Test-PhaseGeneration {
    $testContext = "shared-principles"
    $success = $true
    
    Write-Host "  Testing complete phase artifact generation..."
    
    $phases = @("analyze", "architect", "implement", "checkpoints")
    
    foreach ($phase in $phases) {
        Write-Host "    Generating all artifacts for $phase phase..."
        
        if (Invoke-PhaseArtifactGeneration $phase $testContext) {
            Write-Host "    ✅ $phase`: Phase generation completed"
            
            $artifactsDir = Join-Path $RepoRoot "artifacts\$phase"
            if (-not (Assert-DirectoryExists $artifactsDir "$phase artifacts directory")) {
                $success = $false
            }
            
            if (Test-Path $artifactsDir) {
                $artifactCount = (Get-ChildItem $artifactsDir -File -Recurse).Count
                if ($artifactCount -ge 4) {
                    Write-Host "    ✅ $phase`: Generated $artifactCount artifacts"
                } else {
                    Write-Host "    ❌ $phase`: Only $artifactCount artifacts generated (expected 4+)"
                    $success = $false
                }
            }
        } else {
            Write-Host "    ❌ $phase`: Phase generation failed"
            $success = $false
        }
    }
    
    return $success
}

# =============================================================================
# PERFORMANCE TESTS
# =============================================================================

function Test-GenerationPerformance {
    $testContext = "shared-principles"
    $phase = "analyze"
    $templateId = "architecture_assessment"
    $success = $true
    
    Write-Host "  Testing generation performance..."
    
    # Measure single artifact generation time
    $startTime = Get-Date
    $outputFile = Join-Path $TestArtifactsDir "performance_test_$templateId.md"
    $outputDir = Split-Path $outputFile -Parent
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    if (Invoke-ArtifactGeneration $templateId $phase $testContext $outputFile) {
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        Write-Host "    ✅ Single artifact generation completed in $([math]::Round($duration, 2))s"
        
        if ($duration -lt 10) {
            Write-Host "    ✅ Performance target met (< 10s)"
        } else {
            Write-Host "    ⚠️  Performance target missed ($([math]::Round($duration, 2))s >= 10s)"
        }
        
        # Measure phase generation time
        $startTime = Get-Date
        
        if (Invoke-PhaseArtifactGeneration $phase $testContext) {
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            
            Write-Host "    ✅ Phase generation completed in $([math]::Round($duration, 2))s"
            
            if ($duration -lt 30) {
                Write-Host "    ✅ Phase performance target met (< 30s)"
            } else {
                Write-Host "    ⚠️  Phase performance target missed ($([math]::Round($duration, 2))s >= 30s)"
            }
        } else {
            Write-Host "    ❌ Phase generation performance test failed"
            $success = $false
        }
    } else {
        Write-Host "    ❌ Single artifact generation performance test failed"
        $success = $false
    }
    
    return $success
}

# =============================================================================
# TEMPLATE VALIDATION TESTS
# =============================================================================

function Test-TemplateListing {
    $success = $true
    
    Write-Host "  Testing template listing functionality..."
    
    $phases = @("analyze", "architect", "implement", "checkpoints")
    
    foreach ($phase in $phases) {
        Write-Host "    Testing template listing for $phase..."
        
        $templates = Get-PhaseTemplates $phase
        $templateCount = $templates.Count
        
        if ($templateCount -ge 4) {
            Write-Host "    ✅ $phase`: Found $templateCount templates"
        } else {
            Write-Host "    ❌ $phase`: Only found $templateCount templates (expected 4+)"
            $success = $false
        }
    }
    
    return $success
}

# =============================================================================
# MAIN TEST EXECUTION
# =============================================================================

function New-TestReport {
    $reportFile = Join-Path $TestOutputDir "integration_test_report.md"
    
    $successRate = if ($Global:TestsTotal -gt 0) { [math]::Round(($Global:TestsPassed * 100) / $Global:TestsTotal, 2) } else { 0 }
    
    $reportContent = @"
# Artifact Integration Test Report

**Date**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
**Test Suite**: Artifact Generation System Integration Tests (PowerShell)
**Version**: SDD v2.0 Phase 2.3

## Test Summary

- **Total Tests**: $($Global:TestsTotal)
- **Passed**: $($Global:TestsPassed)
- **Failed**: $($Global:TestsFailed)
- **Success Rate**: $successRate%

## Test Results

$(if ($Global:TestsFailed -eq 0) {
    "✅ **ALL TESTS PASSED** - System is ready for production"
} else {
    "❌ **$($Global:TestsFailed) TESTS FAILED** - Issues need to be resolved"
})

## Test Environment

- **Repository Root**: $RepoRoot
- **Test Output**: $TestOutputDir
- **Test Artifacts**: $TestArtifactsDir

## Artifacts Generated During Testing

$(if (Test-Path $TestArtifactsDir) { (Get-ChildItem $TestArtifactsDir -File -Recurse).Count } else { 0 }) test artifacts generated

## Recommendations

$(if ($Global:TestsFailed -eq 0) {
    "- System is fully functional and ready for Phase 2.3 completion`n- All artifact generation workflows are operational`n- Performance targets are being met"
} else {
    "- Review failed tests and resolve issues before proceeding`n- Check system dependencies and configuration`n- Verify template files and integration"
})

---

*Generated by Artifact Integration Test Suite v1.0 (PowerShell)*
"@

    $reportContent | Out-File -FilePath $reportFile -Encoding UTF8
    Write-ColorOutput "📊 Test report generated: $reportFile" "Blue"
}

function Start-Tests {
    Write-ColorOutput "🚀 Starting Artifact Integration Tests (PowerShell)" "Blue"
    Write-ColorOutput "======================================" "Blue"
    
    # Initialize test environment
    Initialize-TestEnvironment
    
    # Run individual artifact generation tests
    Write-ColorOutput "`n📋 Individual Artifact Generation Tests" "Yellow"
    Invoke-Test "Analyze Individual Artifacts" { Test-AnalyzeIndividualArtifacts }
    Invoke-Test "Architect Individual Artifacts" { Test-ArchitectIndividualArtifacts }
    Invoke-Test "Implement Individual Artifacts" { Test-ImplementIndividualArtifacts }
    Invoke-Test "Checkpoints Individual Artifacts" { Test-CheckpointsIndividualArtifacts }
    
    # Run phase generation tests
    Write-ColorOutput "`n🔄 Phase Generation Tests" "Yellow"
    Invoke-Test "Complete Phase Generation" { Test-PhaseGeneration }
    
    # Run template validation tests
    Write-ColorOutput "`n📝 Template Validation Tests" "Yellow"
    Invoke-Test "Template Listing" { Test-TemplateListing }
    
    # Run performance tests
    Write-ColorOutput "`n⚡ Performance Tests" "Yellow"
    Invoke-Test "Generation Performance" { Test-GenerationPerformance }
    
    # Generate test report
    New-TestReport
    
    # Final summary
    Write-ColorOutput "`n======================================" "Blue"
    Write-ColorOutput "🏁 Test Execution Complete" "Blue"
    Write-ColorOutput "======================================" "Blue"
    
    if ($Global:TestsFailed -eq 0) {
        Write-ColorOutput "✅ ALL TESTS PASSED ($($Global:TestsPassed)/$($Global:TestsTotal))" "Green"
        Write-ColorOutput "🎉 Artifact Generation System is fully functional!" "Green"
        exit 0
    } else {
        Write-ColorOutput "❌ $($Global:TestsFailed) TESTS FAILED ($($Global:TestsPassed)/$($Global:TestsTotal) passed)" "Red"
        Write-ColorOutput "🔧 System requires fixes before production use" "Red"
        exit 1
    }
}

# Execute main function
Start-Tests